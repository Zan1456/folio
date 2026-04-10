// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:folio_kreta_api/client/api.dart';

// Keep this enum — used by DatabaseStore/Query for last_seen tracking
enum LastSeenCategory { grade, surprisegrade, absence, message, lesson }

// Notification type bitmask values (mirrors KRÉTA NotificationMessageType)
class NotificationType {
  static const int all = 1;
  static const int evaluation = 2;
  static const int omission = 4;
  static const int note = 8;
  static const int message = 16;
  static const int task = 32;
  static const int exam = 64;
  static const int lessons = 128;
}

// Notification API key for DELETE/PUT (unauthenticated) requests
const _notifApiKey = '7856d350-1fda-45f5-822d-e1a2f3f1acf0';

enum NotificationRegistrationStatus {
  /// The device has a stored registration ID and the FCM token matches.
  registered,

  /// The device has a stored registration ID but the FCM token has changed.
  tokenMismatch,

  /// No stored registration ID – the device has never been registered.
  notRegistered,

  /// Could not retrieve a FCM token from Firebase.
  noToken,
}

class NotificationHelper {
  /// Call once at app startup (after Firebase.initializeApp).
  /// Requests permission, then registers/updates the subscription for [user].
  static Future<void> initialize(User user, DatabaseProvider database) async {
    if (Platform.isLinux || Platform.isWindows) return;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await subscribeIfNeeded(user, database);
  }

  /// Registers (or re-registers if the FCM token changed) the device for
  /// push notifications with the KRÉTA Global Notification API.
  static Future<void> subscribeIfNeeded(
      User user, DatabaseProvider database) async {
    if (user.isDemo) return;

    final messaging = FirebaseMessaging.instance;
    final fcmToken = await messaging.getToken();
    if (fcmToken == null) return;

    final stored =
        await database.userQuery.getNotificationSubscription(userId: user.id);

    if (stored.registrationId.isEmpty) {
      // No existing registration → POST
      await _register(user: user, fcmToken: fcmToken, database: database);
    } else if (stored.fcmToken != fcmToken) {
      // Token rotated → PUT
      await _updateRegistration(
        registrationId: stored.registrationId,
        newFcmToken: fcmToken,
        user: user,
        database: database,
      );
    }
    // else: already registered with current token, nothing to do
  }

  /// Returns the current Firebase / KRÉTA registration status for [user].
  /// Does not show any permission prompt.
  static Future<NotificationRegistrationStatus> checkStatus(
      User user, DatabaseProvider database) async {
    if (Platform.isLinux || Platform.isWindows) {
      return NotificationRegistrationStatus.notRegistered;
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return NotificationRegistrationStatus.noToken;

    final stored =
        await database.userQuery.getNotificationSubscription(userId: user.id);

    if (stored.registrationId.isEmpty) {
      return NotificationRegistrationStatus.notRegistered;
    }
    if (stored.fcmToken != fcmToken) {
      return NotificationRegistrationStatus.tokenMismatch;
    }
    return NotificationRegistrationStatus.registered;
  }

  /// Removes the push notification registration for [user] from the KRÉTA
  /// server and clears the local DB entry. Call on logout / account removal.
  static Future<void> unsubscribe(User user, DatabaseProvider database) async {
    final stored =
        await database.userQuery.getNotificationSubscription(userId: user.id);
    if (stored.registrationId.isEmpty) return;

    final role = user.role == Role.student ? 1 : 2;
    final env =
        user.role == Role.student ? 'Tanulo_Native' : 'Gondviselo_Native';

    try {
      await http.delete(
        Uri.parse(KretaAPI.notificationRegistration).replace(queryParameters: {
          'RegistrationId': stored.registrationId,
          'NotificationRole': role.toString(),
          'NotificationEnvironment': env,
          'NotificationType': NotificationType.all.toString(),
          'NotificationSource': 'Kreta',
        }),
        headers: {'apiKey': _notifApiKey},
      );
    } catch (e) {
      print('NotificationHelper: unsubscribe error: $e');
    }

    await database.userStore.clearNotificationSubscription(userId: user.id);
  }

  static Future<void> _register({
    required User user,
    required String fcmToken,
    required DatabaseProvider database,
  }) async {
    final role = user.role == Role.student ? 1 : 2;
    final env =
        user.role == Role.student ? 'Tanulo_Native' : 'Gondviselo_Native';

    try {
      final response = await http.post(
        Uri.parse(KretaAPI.notificationRegistration).replace(queryParameters: {
          'Handle': fcmToken,
          'NotificationRole': role.toString(),
          'NotificationEnvironment': env,
          'Platform': 'fcmv1',
          'NotificationType': NotificationType.all.toString(),
          'NotificationSource': 'Kreta',
        }),
        headers: {
          'Authorization': 'Bearer ${user.accessToken}',
          'apiKey': _notifApiKey,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final registrationId = json['registrationId'] as String? ?? '';
        if (registrationId.isNotEmpty) {
          await database.userStore.storeNotificationSubscription(
            userId: user.id,
            registrationId: registrationId,
            fcmToken: fcmToken,
          );
          print('NotificationHelper: registered ($registrationId)');
        }
      } else {
        print('NotificationHelper: register failed ${response.statusCode}');
      }
    } catch (e) {
      print('NotificationHelper: register error: $e');
    }
  }

  static Future<void> _updateRegistration({
    required String registrationId,
    required String newFcmToken,
    required User user,
    required DatabaseProvider database,
  }) async {
    final role = user.role == Role.student ? 1 : 2;
    final env =
        user.role == Role.student ? 'Tanulo_Native' : 'Gondviselo_Native';

    try {
      final response = await http.put(
        Uri.parse(KretaAPI.notificationRegistration).replace(queryParameters: {
          'RegistrationId': registrationId,
          'Handle': newFcmToken,
          'NotificationRole': role.toString(),
          'NotificationEnvironment': env,
          'NotificationType': NotificationType.all.toString(),
          'NotificationSource': 'Kreta',
        }),
        headers: {'apiKey': _notifApiKey},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await database.userStore.storeNotificationSubscription(
          userId: user.id,
          registrationId: registrationId,
          fcmToken: newFcmToken,
        );
        print('NotificationHelper: token updated');
      } else {
        print('NotificationHelper: token update failed ${response.statusCode}');
      }
    } catch (e) {
      print('NotificationHelper: token update error: $e');
    }
  }
}
