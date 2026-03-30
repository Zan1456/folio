/*
    Folio, the unofficial client for e-Kréta
    Copyright (C) 2025  Folio team

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:math';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:folio/api/client.dart';
import 'package:folio/api/providers/ad_provider.dart';
import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio/api/providers/news_provider.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/api/providers/self_note_provider.dart';
import 'package:folio/api/providers/status_provider.dart';
import 'package:folio/models/config.dart';
import 'package:folio/providers/third_party_provider.dart';
import 'package:folio/theme/observer.dart';
import 'package:folio/theme/theme.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_plus/providers/goal_provider.dart';
import 'package:folio_kreta_api/providers/share_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_color_utilities/palettes/core_palette.dart';
import 'package:provider/provider.dart';

// Mobile UI
import 'package:folio_mobile_ui/common/system_chrome.dart' as mobile;
import 'package:folio_mobile_ui/screens/login/login_route.dart' as mobile;
import 'package:folio_mobile_ui/screens/login/login_screen.dart' as mobile;
import 'package:folio_mobile_ui/screens/navigation/navigation_screen.dart'
    as mobile;
import 'package:folio_mobile_ui/screens/settings/settings_route.dart'
    as mobile;
import 'package:folio_mobile_ui/screens/settings/settings_screen.dart'
    as mobile;

// Providers
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/event_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/api/providers/update_provider.dart';
import 'package:folio_mobile_ui/pages/grades/calculator/grade_calculator_provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:folio_plus/providers/plus_provider.dart';

class App extends StatelessWidget {
  final SettingsProvider settings;
  final UserProvider user;
  final DatabaseProvider database;

  const App(
      {super.key,
      required this.database,
      required this.settings,
      required this.user});

  @override
  Widget build(BuildContext context) {
    mobile.setSystemChrome(context);

    // Set high refresh mode #28
    if (Platform.isAndroid) {
      try {
        FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        // Ignore error if display mode fails
      }
    }

    CorePalette? corePalette;

    final status = StatusProvider();
    final kreta = KretaClient(
        user: user, settings: settings, database: database, status: status);
    final timetable =
        TimetableProvider(user: user, database: database, kreta: kreta);
    final premium = PlusProvider(settings: settings);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FilcAPI.getConfig(settings).then((Config? config) {
        if (config != null) settings.update(config: config);
      });
      premium.activate();
    });

    return MultiProvider(
      providers: [
        // folio providers
        ChangeNotifierProvider<PlusProvider>(create: (_) => premium),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => settings),
        ChangeNotifierProvider<UserProvider>(create: (_) => user),
        ChangeNotifierProvider<StatusProvider>(create: (_) => status),
        Provider<KretaClient>(create: (_) => kreta),
        Provider<DatabaseProvider>(create: (context) => database),
        ChangeNotifierProvider<ThemeModeObserver>(
          create: (context) => ThemeModeObserver(
            initialTheme: settings.theme,
          ),
        ),
        ChangeNotifierProvider<NewsProvider>(
          create: (context) => NewsProvider(context: context),
        ),
        ChangeNotifierProvider<UpdateProvider>(
          create: (context) => UpdateProvider(context: context),
        ),
        ChangeNotifierProvider<AdProvider>(
          create: (context) => AdProvider(context: context),
        ),

        // user data (kreten) providers
        ChangeNotifierProvider<GradeProvider>(
          create: (_) => GradeProvider(
            settings: settings,
            user: user,
            database: database,
            kreta: kreta,
          ),
        ),
        ChangeNotifierProvider<TimetableProvider>(create: (_) => timetable),
        ChangeNotifierProvider<ExamProvider>(
          create: (context) => ExamProvider(context: context),
        ),
        ChangeNotifierProvider<HomeworkProvider>(
          create: (context) => HomeworkProvider(
            context: context,
            database: database,
            user: user,
          ),
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (context) => MessageProvider(context: context),
        ),
        ChangeNotifierProvider<NoteProvider>(
          create: (context) => NoteProvider(context: context),
        ),
        ChangeNotifierProvider<EventProvider>(
          create: (context) => EventProvider(context: context),
        ),
        ChangeNotifierProvider<AbsenceProvider>(
          create: (context) => AbsenceProvider(context: context),
        ),

        // other providers
        ChangeNotifierProvider<GradeCalculatorProvider>(
          create: (_) => GradeCalculatorProvider(
            settings: settings,
            user: user,
            database: database,
            kreta: kreta,
          ),
        ),
        ChangeNotifierProvider<LiveCardProvider>(
          create: (_) => LiveCardProvider(
            timetable: timetable,
            settings: settings,
          ),
        ),
        ChangeNotifierProvider<GoalProvider>(
          create: (_) => GoalProvider(
            database: database,
            user: user,
          ),
        ),
        ChangeNotifierProvider<ShareProvider>(
          create: (_) => ShareProvider(
            user: user,
          ),
        ),
        ChangeNotifierProvider<SelfNoteProvider>(
          create: (context) => SelfNoteProvider(context: context),
        ),

        // third party providers
        ChangeNotifierProvider<ThirdPartyProvider>(
          create: (context) => ThirdPartyProvider(),
        ),
      ],
      child: Consumer<ThemeModeObserver>(
        builder: (context, themeMode, child) {
          return FutureBuilder<CorePalette?>(
            future: DynamicColorPlugin.getCorePalette(),
            builder: (context, snapshot) {
              corePalette = snapshot.data;
              return MaterialApp(
                builder: (context, child) {
                  // Limit font size scaling to 1.0
                  double textScaleFactor =
                      min(MediaQuery.of(context).textScaleFactor, 1.0);

                  return I18n(
                    initialLocale: Locale(
                        settings.language, settings.language.toUpperCase()),
                    child: MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaleFactor: textScaleFactor),
                      child: child ??
                          const Scaffold(
                            backgroundColor: Colors.red,
                            body: Center(
                                child: Text("Route error - child is null",
                                    style: TextStyle(color: Colors.white))),
                          ),
                    ),
                  );
                },
                title: "Folio",
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme(context, palette: corePalette),
                darkTheme: AppTheme.darkTheme(context, palette: corePalette),
                themeMode: themeMode.themeMode,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', 'EN'),
                  Locale('hu', 'HU'),
                  Locale('de', 'DE'),
                ],
                localeListResolutionCallback: (locales, supported) {
                  Locale locale = const Locale('hu', 'HU');

                  for (var loc in locales ?? []) {
                    if (supported.contains(loc)) {
                      locale = loc;
                      break;
                    }
                  }

                  return locale;
                },
                onGenerateRoute: (settings) => rootNavigator(settings),
                initialRoute:
                    (user.getUsers().isNotEmpty) ? "navigation" : "login",
              );
            },
          );
        },
      ),
    );
  }

  Route? rootNavigator(RouteSettings route) {
    if (kIsWeb) {
      return null;
      // switch (route.name) {
      //   case "login_back":
      //     return CupertinoPageRoute(
      //         builder: (context) => const desktop.LoginScreen(back: true));
      //   case "login":
      //     return _rootRoute(const desktop.LoginScreen());
      //   case "navigation":
      //     return _rootRoute(const desktop.NavigationScreen());
      //   case "login_to_navigation":
      //     return desktop.loginRoute(const desktop.NavigationScreen());
      // }
    } else if (Platform.isAndroid || Platform.isIOS) {
      switch (route.name) {
        case "login_back":
          return CupertinoPageRoute(
              builder: (context) => const mobile.LoginScreen(back: true));
        case "login":
          return _rootRoute(const mobile.LoginScreen());
        case "navigation":
          return _rootRoute(const mobile.NavigationScreen());
        case "login_to_navigation":
          return mobile.loginRoute(const mobile.NavigationScreen());
        case "settings":
          return mobile.settingsRoute(const mobile.SettingsScreen());
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return null;
      // switch (route.name) {
      //   case "login_back":
      //     return CupertinoPageRoute(
      //         builder: (context) => const desktop.LoginScreen(back: true));
      //   case "login":
      //     return _rootRoute(const desktop.LoginScreen());
      //   case "navigation":
      //     return _rootRoute(const desktop.NavigationScreen());
      //   case "login_to_navigation":
      //     return desktop.loginRoute(const desktop.NavigationScreen());
      // }
    }
    return null;
  }

  Route _rootRoute(Widget widget) {
    return PageRouteBuilder(pageBuilder: (context, _, __) => widget);
  }
}
