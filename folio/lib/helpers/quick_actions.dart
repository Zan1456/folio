import 'package:flutter/cupertino.dart';
import 'package:quick_actions/quick_actions.dart';

const QuickActions quickActions = QuickActions();

void setupQuickActions() {
  quickActions.clearShortcutItems();
}

void handleQuickActions(BuildContext context, void Function(String) callback) {
  quickActions.initialize((shortcutType) {
    switch (shortcutType) {
      case 'action_home':
        callback("home");
        break;
      case 'action_grades':
        callback("grades");
        break;
      case 'action_timetable':
        callback("timetable");
        break;
      case 'action_messages':
        callback("messages");
        break;
      case 'action_absences':
        callback("absences");
        break;
    }
  });
}
