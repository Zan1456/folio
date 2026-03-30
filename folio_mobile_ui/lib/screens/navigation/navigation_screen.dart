// ignore_for_file: deprecated_member_use

import 'package:flutter_svg/svg.dart';
import 'package:folio/api/providers/update_provider.dart';
import 'package:folio/helpers/quick_actions.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/observer.dart';
import 'package:folio/utils/navigation_service.dart';
import 'package:folio/utils/service_locator.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_mobile_ui/common/profile_image/profile_image.dart';
import 'package:folio_mobile_ui/common/system_chrome.dart';
import 'package:folio_mobile_ui/screens/navigation/more_menu.dart';
import 'package:folio_mobile_ui/screens/navigation/nabar.dart';
import 'package:folio_mobile_ui/screens/navigation/navbar_item.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_route.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_route_handler.dart';
import 'package:folio_mobile_ui/screens/navigation/status_bar.dart';
import 'package:folio_mobile_ui/screens/news/news_view.dart';
import 'package:folio_mobile_ui/screens/settings/live_activity_consent_dialog.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_dialog.dart';
import 'package:folio_mobile_ui/pages/grades/goal_planner/goal_complete_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:folio_mobile_ui/common/screens.i18n.dart';
import 'package:folio/api/providers/news_provider.dart';
import 'package:folio/api/providers/sync.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:folio/providers/goal_provider.dart';
import 'package:folio/api/providers/ad_provider.dart';
import 'dart:io' show Platform;

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  static NavigationScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<NavigationScreenState>();

  @override
  NavigationScreenState createState() => NavigationScreenState();
}

class NavigationScreenState extends State<NavigationScreen>
    with WidgetsBindingObserver {
  late NavigationRoute selected;
  List<String> initializers = [];
  final _navigatorState = locator<NavigationService>().navigatorKey;

  late SettingsProvider settings;
  late NewsProvider newsProvider;
  late GoalProvider goalProvider;
  late UpdateProvider updateProvider;
  late GradeProvider gradeProvicer;
  late AdProvider adProvider;

  NavigatorState? get navigator => _navigatorState.currentState;

  void customRoute(Route route) => navigator?.pushReplacement(route);

  bool init(String id) {
    if (initializers.contains(id)) return false;

    initializers.add(id);

    return true;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY), (String taskId) async {
      // <-- Event handler
      // This is the fetch-event callback.
      if (kDebugMode) {
        print("[BackgroundFetch] Event received $taskId");
      }

      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      if (kDebugMode) {
        print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      }
      BackgroundFetch.finish(taskId);
    });
    if (kDebugMode) {
      print('[BackgroundFetch] configure success: $status');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  void initState() {
    super.initState();

    settings = Provider.of<SettingsProvider>(context, listen: false);
    selected = NavigationRoute();
    // Clamp to valid page indices (0-2, index 3 is the "Több" popup)
    final startIndex = settings.startPage.index.clamp(0, 2);
    selected.index = startIndex;

    // add brightness observer
    WidgetsBinding.instance.addObserver(this);

    // set client User-Agent
    Provider.of<KretaClient>(context, listen: false).userAgent =
        settings.config.userAgent;

    // get news
    newsProvider = Provider.of<NewsProvider>(context, listen: false);
    newsProvider.restore().then((value) => newsProvider.fetch());

    // init grade provider (for goals)
    gradeProvicer = Provider.of<GradeProvider>(context, listen: false);

    // get goals
    goalProvider = Provider.of<GoalProvider>(context, listen: false);
    goalProvider.fetchDone(gradeProvider: gradeProvicer);

    // get releases
    updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    updateProvider.fetch().then((_) {
      if (updateProvider.available && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          UpdateDialog.show(context, updateProvider.releases.first);
        });
      }
    });

    // get advertisements
    adProvider = Provider.of<AdProvider>(context, listen: false);
    adProvider.fetch();

    // initial sync
    syncAll(context);
    setupQuickActions();

    // Show live activity consent dialog on iOS
    if (Platform.isIOS &&
        settings.unseenNewFeatures.contains('live_activity_consent')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LiveActivityConsentDialog.show(context);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (settings.theme == ThemeMode.system) {
      Brightness? brightness =
          WidgetsBinding.instance.window.platformBrightness;
      Provider.of<ThemeModeObserver>(context, listen: false).changeTheme(
          brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark);
    }
    super.didChangePlatformBrightness();
  }

  void setPage(String page) => setState(() => selected.name = page);

  @override
  Widget build(BuildContext context) {
    setSystemChrome(context);
    settings = Provider.of<SettingsProvider>(context);
    newsProvider = Provider.of<NewsProvider>(context);
    goalProvider = Provider.of<GoalProvider>(context);
    final user = Provider.of<UserProvider>(context);
    final navUpdateProvider = Provider.of<UpdateProvider>(context);
    final navNameParts = user.displayName?.split(" ") ?? ["?"];
    final navFirstName = settings.presentationMode
        ? "János"
        : (navNameParts.length > 1 ? navNameParts[1] : navNameParts[0]);

    // show news and complete goals
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newsProvider.show) {
        NewsView.show(newsProvider.news[0], context: context)
            .then((value) => newsProvider.release());
        newsProvider.lock();
      }

      if (goalProvider.hasDoneGoals) {
        GoalCompleteModal.show(goalProvider.doneSubject!, context: context);
        goalProvider.lock();
      }
    });

    handleQuickActions(context, (page) {
      setPage(page);
      _navigatorState.currentState?.pushReplacementNamed(page);
    });

    // SvgTheme navIcTheme =
    //     SvgTheme(currentColor: Theme.of(context).colorScheme.primary);

    return WillPopScope(
      onWillPop: () async {
        if (_navigatorState.currentState?.canPop() ?? false) {
          _navigatorState.currentState?.pop();
          if (!kDebugMode) {
            return true;
          }
          return false;
        }

        if (selected.index != 0) {
          setState(() => selected.index = 0);
          _navigatorState.currentState?.pushReplacementNamed(selected.name);
        }

        return false;
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Navigator(
              key: _navigatorState,
              initialRoute: selected.name,
              onGenerateRoute: (settings) =>
                  navigationRouteHandler(settings),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                // Status bar
                const StatusBar(),

                // Floating Bottom Navigation Bar
                Navbar(
                        selectedIndex: selected.index,
                        onSelected: onPageSelected,
                        items: [
                          NavItem(
                            title: "home".i18n,
                            icon: Stack(
                              alignment: AlignmentDirectional.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/svg/menu_icons/today.svg',
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  height: 24,
                                ),
                                Transform.translate(
                                  offset: const Offset(0, 1.6),
                                  child: Text(
                                    DateTime.now().day.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize:
                                          DateTime.now().day > 9 ? 12.1 : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            activeIcon: Stack(
                              alignment: AlignmentDirectional.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/svg/menu_icons/today_selected.svg',
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  height: 24,
                                ),
                                Transform.translate(
                                  offset: const Offset(0, 1.8),
                                  child: Text(
                                    DateTime.now().day.toString(),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .background,
                                      fontWeight: FontWeight.w500,
                                      fontSize:
                                          DateTime.now().day > 9 ? 12.1 : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          NavItem(
                            title: "grades".i18n,
                            icon: SvgPicture.asset(
                              'assets/svg/menu_icons/grades.svg',
                              color: Theme.of(context).colorScheme.secondary,
                              height: 22,
                            ),
                            activeIcon: SvgPicture.asset(
                              'assets/svg/menu_icons/grades_selected.svg',
                              color: Theme.of(context).colorScheme.secondary,
                              height: 22,
                            ),
                          ),
                          NavItem(
                            title: "timetable".i18n,
                            icon: SvgPicture.asset(
                              'assets/svg/menu_icons/timetable.svg',
                              color: Theme.of(context).colorScheme.secondary,
                              height: 22,
                            ),
                            activeIcon: SvgPicture.asset(
                              'assets/svg/menu_icons/timetable_selected.svg',
                              color: Theme.of(context).colorScheme.secondary,
                              height: 22,
                            ),
                          ),
                          NavItem(
                            title: "more".i18n,
                            icon: ProfileImage(
                              name: navFirstName,
                              backgroundColor:
                                  Theme.of(context).colorScheme.tertiary,
                              badge: navUpdateProvider.available,
                              role: user.role,
                              profilePictureString: user.picture,
                              gradeStreak: (user.gradeStreak ?? 0) > 1,
                              radius: 14.0,
                            ),
                            activeIcon: ProfileImage(
                              name: navFirstName,
                              backgroundColor:
                                  Theme.of(context).colorScheme.tertiary,
                              badge: navUpdateProvider.available,
                              role: user.role,
                              profilePictureString: user.picture,
                              gradeStreak: (user.gradeStreak ?? 0) > 1,
                              radius: 14.0,
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  void onPageSelected(int index) {
    // "Több" button (index 3) opens popup, does not navigate
    if (index == 3) {
      switch (settings.vibrate) {
        case VibrationStrength.light:
          HapticFeedback.lightImpact();
          break;
        case VibrationStrength.medium:
          HapticFeedback.mediumImpact();
          break;
        case VibrationStrength.strong:
          HapticFeedback.heavyImpact();
          break;
        default:
      }
      MoreMenu.show(context);
      return;
    }

    // Vibrate, then set the active screen
    if (selected.index != index) {
      switch (settings.vibrate) {
        case VibrationStrength.light:
          HapticFeedback.lightImpact();
          break;
        case VibrationStrength.medium:
          HapticFeedback.mediumImpact();
          break;
        case VibrationStrength.strong:
          HapticFeedback.heavyImpact();
          break;
        default:
      }
      setState(() => selected.index = index);
      _navigatorState.currentState?.pushReplacementNamed(selected.name);
    }
  }
}
