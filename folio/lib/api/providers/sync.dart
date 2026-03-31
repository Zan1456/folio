// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/api/providers/status_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/student.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/event_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';


// Mutex
bool lock = false;

Future<void> syncAll(BuildContext context) async {
  if (lock) return Future.value();
  // Lock
  lock = true;

  // ignore: avoid_print
  print("INFO Syncing all");

  UserProvider user = Provider.of<UserProvider>(context, listen: false);

  // Demo mode: load demo data into providers without API calls
  if (user.isDemo) {
    await Future.wait([
      Provider.of<GradeProvider>(context, listen: false).fetch(),
      Provider.of<TimetableProvider>(context, listen: false)
          .fetch(week: Week.current()),
      Provider.of<ExamProvider>(context, listen: false).fetch(),
      Provider.of<HomeworkProvider>(context, listen: false)
          .fetch(from: DateTime.now().subtract(const Duration(days: 30))),
      Provider.of<MessageProvider>(context, listen: false).fetchAll(),
      Provider.of<NoteProvider>(context, listen: false).fetch(),
      Provider.of<EventProvider>(context, listen: false).fetch(),
      Provider.of<AbsenceProvider>(context, listen: false).fetch(),
    ]);
    lock = false;
    return Future.value();
  }

  StatusProvider statusProvider =
      Provider.of<StatusProvider>(context, listen: false);

  // Validate user and token before launching parallel API calls.
  // This avoids every parallel task getting a 401 + 1.5 s retry penalty.
  if (user.user == null) {
    Navigator.of(context).pushNamedAndRemoveUntil("login", (_) => false);
    lock = false;
    return Future.value();
  }

  if (user.user!.accessToken.replaceAll(" ", "") == "") {
    String uid = user.user!.id;
    user.removeUser(uid);
    await Provider.of<DatabaseProvider>(context, listen: false)
        .store
        .removeUser(uid);
    Navigator.of(context).pushNamedAndRemoveUntil("login", (_) => false);
    lock = false;
    return;
  }

  if (user.user!.accessTokenExpire.isBefore(DateTime.now())) {
    String authRes = await Provider.of<KretaClient>(context, listen: false)
            .refreshLogin() ??
        '';
    if (authRes != 'success') {
      if (kDebugMode) print('ERROR: failed to refresh login');
      lock = false;
      return Future.value();
    } else {
      if (kDebugMode) print('INFO: access token refreshed');
    }
  } else {
    if (kDebugMode) print('INFO: access token is not expired');
  }

  List<Future<void>> tasks = [];
  int taski = 0;

  Future<void> syncStatus(Future<void> future) async {
    await future.onError((error, stackTrace) => null);
    taski++;
    statusProvider.triggerSync(current: taski, max: tasks.length);
  }

  tasks = [
    syncStatus(Provider.of<GradeProvider>(context, listen: false).fetch()),
    syncStatus(Provider.of<TimetableProvider>(context, listen: false)
        .fetch(week: Week.current())),
    syncStatus(Provider.of<ExamProvider>(context, listen: false).fetch()),
    syncStatus(Provider.of<HomeworkProvider>(context, listen: false)
        .fetch(from: DateTime.now().subtract(const Duration(days: 30)))),
    syncStatus(Provider.of<MessageProvider>(context, listen: false).fetchAll()),
    syncStatus(Provider.of<MessageProvider>(context, listen: false)
        .fetchAllRecipients()),
    syncStatus(Provider.of<NoteProvider>(context, listen: false).fetch()),
    syncStatus(Provider.of<EventProvider>(context, listen: false).fetch()),
    syncStatus(Provider.of<AbsenceProvider>(context, listen: false).fetch()),

    // Sync student
    syncStatus(() async {
      if (user.user == null) return;
      Map? studentJson = await Provider.of<KretaClient>(context, listen: false)
          .getAPI(KretaAPI.student(user.instituteCode!));
      if (studentJson == null) return;
      Student student = Student.fromJson(studentJson);

      user.user?.name = student.name;

      // Store user
      await Provider.of<DatabaseProvider>(context, listen: false)
          .store
          .storeUser(user.user!);
    }()),
  ];

  return Future.wait(tasks).then((value) {
    lock = false;
  });
}
