// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:folio/utils/jwt.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/event_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/models/user.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/student.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:flutter/material.dart';
import 'package:folio/helpers/notification_helper.dart';
import 'package:provider/provider.dart';

enum LoginState {
  missingFields,
  invalidGrant,
  failed,
  normal,
  inProgress,
  success,
}

// login api
Future newLoginAPI({
  required String code,
  required BuildContext context,
  String? idpApplication,
  String? idpRememberBrowser,
  void Function(User)? onLogin,
  void Function()? onSuccess,
}) async {
  // actual login (token grant) logic
  Provider.of<KretaClient>(context, listen: false).userAgent =
      Provider.of<SettingsProvider>(context, listen: false).config.userAgent;

  Map<String, String> headers = {
    "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
    "accept": "*/*",
    "user-agent": "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0",
  };

  Map? res = await Provider.of<KretaClient>(context, listen: false)
      .postAPI(KretaAPI.login, headers: headers, body: {
    "code": code,
    "code_verifier": "DSpuqj_HhDX4wzQIbtn8lr8NLE5wEi1iVLMtMK0jY6c",
    "redirect_uri":
        "https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect",
    "client_id": KretaAPI.clientId,
    "grant_type": "authorization_code",
  });

  if (res != null) {
    if (kDebugMode) {
      print(res);

      // const splitSize = 1000;
      // RegExp exp = RegExp(r"\w{" "$splitSize" "}");
      // // String str = "0102031522";
      // Iterable<Match> matches = exp.allMatches(res.toString());
      // var list = matches.map((m) => m.group(0));
      // list.forEach((e) {
      //   print(e);
      // });
    }

    if (res.containsKey("error")) {
      if (res["error"] == "invalid_grant") {
        print("ERROR: invalid_grant");
        return;
      }
    } else {
      if (res.containsKey("access_token")) {
        try {
          Provider.of<KretaClient>(context, listen: false).accessToken =
              res["access_token"];
          Provider.of<KretaClient>(context, listen: false).refreshToken =
              res["refresh_token"];
          Provider.of<KretaClient>(context, listen: false)
              .idpApplicationCookie = idpApplication;

          String instituteCode =
              JwtUtils.getInstituteFromJWT(res["access_token"])!;
          String username = JwtUtils.getUsernameFromJWT(res["access_token"])!;
          Role role = JwtUtils.getRoleFromJWT(res["access_token"])!;

          Map? studentJson =
              await Provider.of<KretaClient>(context, listen: false)
                  .getAPI(KretaAPI.student(instituteCode));
          Student student = Student.fromJson(studentJson!);

          var user = User(
            username: username,
            password: '',
            instituteCode: instituteCode,
            name: student.name,
            student: student,
            role: role,
            accessToken: res["access_token"],
            accessTokenExpire:
                DateTime.now().add(Duration(seconds: (res["expires_in"] - 30))),
            refreshToken: res["refresh_token"],
          );
          user.idpApplication = idpApplication ?? '';
          user.idpRememberBrowser = idpRememberBrowser ?? '';

          if (onLogin != null) onLogin(user);

          // Store User in the database
          final dbProvider =
              Provider.of<DatabaseProvider>(context, listen: false);
          await dbProvider.store.storeUser(user);
          Provider.of<UserProvider>(context, listen: false).addUser(user);
          Provider.of<UserProvider>(context, listen: false).setUser(user.id);

          // Register device for push notifications
          final sp = Provider.of<SettingsProvider>(context, listen: false);
          if (sp.notificationsEnabled) {
            NotificationHelper.initialize(user, dbProvider);
          }

          // Get user data
          try {
            await Future.wait([
              Provider.of<GradeProvider>(context, listen: false).fetch(),
              Provider.of<TimetableProvider>(context, listen: false)
                  .fetch(week: Week.current()),
              Provider.of<ExamProvider>(context, listen: false).fetch(),
              Provider.of<HomeworkProvider>(context, listen: false).fetch(),
              Provider.of<MessageProvider>(context, listen: false).fetchAll(),
              Provider.of<MessageProvider>(context, listen: false)
                  .fetchAllRecipients(),
              Provider.of<NoteProvider>(context, listen: false).fetch(),
              Provider.of<EventProvider>(context, listen: false).fetch(),
              Provider.of<AbsenceProvider>(context, listen: false).fetch(),
            ]);
          } catch (error) {
            print("WARNING: failed to fetch user data: $error");
          }

          if (onSuccess != null) onSuccess();

          return LoginState.success;
        } catch (error) {
          print("ERROR: loginAPI: $error");
          // maybe check debug mode
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ERROR: $error")));
          return LoginState.failed;
        }
      }
    }
  }

  return LoginState.failed;
}
