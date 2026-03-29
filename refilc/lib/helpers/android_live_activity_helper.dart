import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:refilc/api/providers/live_card_provider.dart';

class AndroidLiveActivityHelper {
  static const _channel = MethodChannel('app.zan1456.folio/android_live_activity');

  static bool _active = false;

  /// Remaining seconds until [endDate], clamped to 0.
  static int _remainingSeconds(Map<String, String> data) {
    final endMs = int.tryParse(data['endDate'] ?? '');
    if (endMs == null || endMs == 0) return 0;
    final remaining = (endMs - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    return remaining.clamp(0, 999999);
  }

  static Future<void> showOrUpdate({
    required LiveCardState state,
    required Map<String, String> data,
    required String type,
  }) async {
    if (!Platform.isAndroid) return;

    String title = '';
    String body = '';
    String? subText;

    final remainingSeconds = _remainingSeconds(data);

    switch (state) {
      case LiveCardState.duringLesson:
        final index = data['index'] ?? '';
        title = '${index.isNotEmpty ? "$index" : ""}${data['title'] ?? ''}';
        final room = data['subtitle'] ?? '';
        body = room.isNotEmpty ? room : (data['description'] ?? '');
        // No remaining text, no next subject during lesson
        break;

      case LiveCardState.duringBreak:
        final nextSubject = data['nextSubject'] ?? '';
        final nextRoom = data['nextRoom'] ?? '';
        title = type == 'hyper_os' && nextSubject.isNotEmpty
            ? 'Szünet • $nextSubject'
            : 'Szünet';
        body = type == 'hyper_os'
            ? nextRoom
            : (nextSubject.isNotEmpty
                ? '$nextSubject${nextRoom.isNotEmpty ? " – $nextRoom" : ""}'
                : '');
        // No remaining text label
        break;

      case LiveCardState.morning:
      case LiveCardState.afternoon:
      case LiveCardState.night:
        final nextSubject = data['nextSubject'] ?? '';
        if (nextSubject.isEmpty) {
          await cancel();
          return;
        }
        final nextRoom = data['nextRoom'] ?? '';
        title = type == 'hyper_os' ? 'Következő: $nextSubject' : 'Következő óra';
        body = type == 'hyper_os' ? nextRoom : nextSubject;
        if (type != 'hyper_os' && nextRoom.isNotEmpty) subText = nextRoom;
        break;

      default:
        await cancel();
        return;
    }

    try {
      if (type == 'hyper_os') {
        await _channel.invokeMethod('showOrUpdateHyperOs', {
          'title': title,
          'body': body,
          'subText': subText ?? '',
          'remainingSeconds': remainingSeconds,
        });
      } else {
        await _channel.invokeMethod('showOrUpdateNative', {
          'title': title,
          'body': body,
          'subText': subText,
        });
      }
      _active = true;
    } on PlatformException catch (e) {
      debugPrint('AndroidLiveActivityHelper error: $e');
    }
  }

  static Future<void> cancel() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancel');
    } on PlatformException catch (e) {
      debugPrint('AndroidLiveActivityHelper cancel error: $e');
    } finally {
      _active = false;
    }
  }

  static bool get isActive => _active;
}
