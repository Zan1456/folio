import 'dart:math';
import 'package:animations/animations.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/dot.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/system_chrome.dart';
import 'package:folio_kreta_api/controllers/timetable_controller.dart';
import 'package:folio_mobile_ui/common/widgets/lesson/lesson_viewable.dart';
import 'package:folio_mobile_ui/pages/timetable/fs_timetable.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_route_handler.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:folio_mobile_ui/common/haptic.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'timetable_page.i18n.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key, this.initialDay, this.initialWeek});

  final DateTime? initialDay;
  final Week? initialWeek;

  static void jump(BuildContext context,
      {Week? week, DateTime? day, Lesson? lesson}) {
    // Go to timetable page with arguments
    NavigationScreen.of(context)
        ?.customRoute(navigationPageRoute((context) => TimetablePage(
              initialDay: lesson?.date ?? day,
              initialWeek: lesson?.date != null
                  ? Week.fromDate(lesson!.date)
                  : day != null
                      ? Week.fromDate(day)
                      : week,
            )));

    NavigationScreen.of(context)?.setPage("timetable");

    // Show initial Lesson
    // if (lesson != null) LessonView.show(lesson, context: context);
    // changed to new popup
    if (lesson != null) {
      TimetableLessonPopup.show(context: context, lesson: lesson);
    }
  }

  @override
  TimetablePageState createState() => TimetablePageState();
}

class TimetablePageState extends State<TimetablePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late UserProvider user;
  late TimetableProvider timetableProvider;
  late SettingsProvider settingsProvider;
  late DatabaseProvider db;

  late String firstName;

  late TimetableController _controller;
  late TabController _tabController;

  late Widget empty;

  Map<String, String> customLessonDesc = {};

  int _getDayIndex(DateTime date) {
    int index = 0;
    if (_controller.days == null || (_controller.days?.isEmpty ?? true)) {
      return index;
    }

    // find the first day with upcoming lessons
    index = _controller.days!.indexWhere((day) => day.last.end.isAfter(date));
    if (index == -1) index = 0; // fallback

    return index;
  }

  // Update timetable on user change
  Future<void> _userListener() async {
    await Provider.of<TimetableProvider>(context, listen: false).restoreUser();
    await Provider.of<KretaClient>(context, listen: false).refreshLogin();
    if (mounted) _controller.jump(_controller.currentWeek, context: context);
  }

  // When the app comes to foreground, refresh the timetable
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) _controller.jump(_controller.currentWeek, context: context);
    }
  }

  @override
  void initState() {
    super.initState();

    // Initalize controllers
    _controller = TimetableController();
    _tabController = TabController(length: 0, vsync: this, initialIndex: 0);

    empty = Empty(subtitle: "empty".i18n);

    bool initial = true;

    // Only update the TabController on week changes
    _controller.addListener(() {
      if (_controller.days == null) return;
      // Refresh custom descriptions when timetable data changes
      getCustom();
      setState(() {
        _tabController = TabController(
          length: _controller.days!.length,
          vsync: this,
          initialIndex:
              min(_tabController.index, max(_controller.days!.length - 1, 0)),
        );

        if (initial ||
            _controller.previousWeekId != _controller.currentWeekId) {
          _tabController
              .animateTo(_getDayIndex(widget.initialDay ?? DateTime.now()));
        }
        initial = false;

        // Empty is updated once every week change
        empty = Empty(subtitle: "empty".i18n);
      });
    });

    if (mounted) {
      if (widget.initialWeek != null) {
        _controller.jump(widget.initialWeek!, context: context, initial: true);
      } else {
        _controller.jump(_controller.currentWeek,
            context: context, initial: true, skip: true);
      }
    }

    // push timetable to calendar (calendar sync removed)

    // Listen for user changes
    user = Provider.of<UserProvider>(context, listen: false);
    user.addListener(_userListener);

    // listen for lesson customization
    db = Provider.of<DatabaseProvider>(context, listen: false);
    getCustom();

    // Register listening for app state changes to refresh the timetable
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    user.removeListener(_userListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String dayTitle(int index) {
    // Sometimes when changing weeks really fast,
    // controller.days might be null or won't include index
    try {
      return DateFormat("EEEE", I18n.of(context).locale.languageCode)
          .format(_controller.days![index].first.date);
    } catch (e) {
      return "timetable".i18n;
    }
  }

  void getCustom() async {
    customLessonDesc =
        await db.userQuery.getCustomLessonDescriptions(userId: user.id!);
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context, listen: false);
    timetableProvider = Provider.of<TimetableProvider>(context, listen: false);
    settingsProvider = Provider.of<SettingsProvider>(context);

    // Pre-compute per-day values once per build, not inside itemBuilder
    final now = DateTime.now();
    final locale = I18n.of(context).locale.languageCode;
    final df = DateFormat("H:mm", locale);
    final dayLabels = _controller.days != null
        ? List<String>.generate(
            _controller.days!.length,
            (i) => DateFormat("EEEE", locale)
                .format(_controller.days![i].first.date)
                .capital(),
          )
        : <String>[];
    final swapDescPerDay = _controller.days != null
        ? List<bool>.generate(_controller.days!.length, (i) {
            final day = _controller.days![i];
            if (day.isEmpty) return false;
            final swapCount = day.fold<int>(0, (s, l) => s + (l.swapDesc ? 1 : 0));
            return swapCount >= day.length * .5;
          })
        : <bool>[];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ─── Accent Header ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28.0)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row: spinner + "Órarend" + inline week selector + more
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 8.0, 0.0),
                    child: Row(
                      children: [
                        // Loading spinner
                        () {
                          final show = _controller.days == null ||
                              (_controller.loadType != LoadType.offline &&
                                  _controller.loadType != LoadType.online);
                          const duration = Duration(milliseconds: 150);
                          return AnimatedOpacity(
                            opacity: show ? 1.0 : 0.0,
                            duration: duration,
                            child: AnimatedContainer(
                              duration: duration,
                              width: show ? 26.0 : 0.0,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: CupertinoActivityIndicator(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer),
                              ),
                            ),
                          );
                        }(),
                        // "Órarend" title
                        Expanded(
                          child: Text(
                            "timetable".i18n,
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        // Compact inline week selector
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _controller.currentWeekId == 0
                                    ? null
                                    : () {
                                        performHapticFeedback(settingsProvider.vibrate);
                                        setState(() => _controller.previous(context));
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 11.0),
                                  child: Icon(
                                    Icons.keyboard_arrow_left_rounded,
                                    size: 20.0,
                                    color: _controller.currentWeekId == 0
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withValues(alpha: 0.3)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  performHapticFeedback(settingsProvider.vibrate);
                                  setState(() {
                                    _controller.current();
                                    if (mounted) {
                                      _controller.jump(
                                        _controller.currentWeek,
                                        context: context,
                                        loader: _controller.currentWeekId !=
                                            _controller.previousWeekId,
                                      );
                                    }
                                    _tabController
                                        .animateTo(_getDayIndex(DateTime.now()));
                                  });
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  child: Text(
                                    "${_controller.currentWeekId + 1}. ${"week".i18n}",
                                    key: ValueKey<int>(_controller.currentWeekId),
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _controller.currentWeekId == 51
                                    ? null
                                    : () {
                                        performHapticFeedback(settingsProvider.vibrate);
                                        setState(() => _controller.next(context));
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 11.0),
                                  child: Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                    size: 20.0,
                                    color: _controller.currentWeekId == 51
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withValues(alpha: 0.3)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // More / settings button
                        IconButton(
                          splashRadius: 24.0,
                          onPressed: () {
                            performHapticFeedback(settingsProvider.vibrate);
                            showQuickSettings(context);
                          },
                          icon: Icon(Icons.more_horiz_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                      ],
                    ),
                  ),
                  // Day tab bar
                  if (_tabController.length > 0)
                    ListenableBuilder(
                      listenable: _tabController,
                      builder: (context, _) => TabBar(
                        controller: _tabController,
                        dividerColor: Colors.transparent,
                        labelPadding: EdgeInsets.zero,
                        labelColor: Theme.of(context).colorScheme.secondary,
                        unselectedLabelColor: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.65),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6.0),
                        indicator: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        overlayColor: WidgetStateProperty.all(Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.08)),
                        onTap: (_) =>
                            performHapticFeedback(settingsProvider.vibrate),
                        padding:
                            const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 14.0),
                        tabs: List.generate(_tabController.length, (index) {
                          final isToday = _sameDate(
                              _controller.days![index].first.date, now);
                          final isSelected = _tabController.index == index;
                          final dotColor = isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.6)
                              : Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.45);
                          final label = dayLabels[index];
                          return Tab(
                            height: 50.0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isToday) Dot(size: 4.0, color: dotColor),
                                Text(
                                  label.substring(0, 1),
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: isToday ? 0.0 : 2.0),
                                Text(
                                  _controller.days![index].first.date.day
                                      .toString(),
                                  style: const TextStyle(
                                    height: 1.0,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ─── Timetable content ─────────────────────────────────────────
          Expanded(
            child: PageTransitionSwitcher(
              transitionBuilder: (
                Widget child,
                Animation<double> primaryAnimation,
                Animation<double> secondaryAnimation,
              ) {
                return FadeThroughTransition(
                  animation: primaryAnimation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  child: child,
                );
              },
              child: _controller.days != null
                  ? Column(
                      key: Key(_controller.currentWeek.toString()),
                      children: [
                        _tabController.length > 0
                            ? Expanded(
                                child: TabBarView(
                                  physics: const BouncingScrollPhysics(),
                                  controller: _tabController,
                                  children: List.generate(
                                    _controller.days!.length,
                                    (tab) => RefreshIndicator(
                                      onRefresh: () => mounted
                                          ? _controller.jump(
                                              _controller.currentWeek,
                                              context: context,
                                              loader: false)
                                          : Future.value(null),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      child: ListView.builder(
                                        padding: EdgeInsets.fromLTRB(
                                            10.0, 8.0, 10.0,
                                            MediaQuery.of(context).padding.bottom + 8.0),
                                        physics: const BouncingScrollPhysics(),
                                        itemCount:
                                            _controller.days![tab].length,
                                        itemBuilder: (context, index) {
                                          if (_controller.days == null) {
                                            return Container();
                                          }

                                          int len =
                                              _controller.days![tab].length;
                                          final Lesson lesson =
                                              _controller.days![tab][index];
                                          final Lesson? before =
                                              len + index > len
                                                  ? _controller.days![tab]
                                                      [index - 1]
                                                  : null;
                                          final bool swapDescDay = swapDescPerDay[tab];

                                          return RepaintBoundary(
                                            child: Column(
                                              children: [
                                              if (before != null &&
                                                  (before.end.hour != 0 &&
                                                      lesson.start.hour != 0) &&
                                                  settingsProvider.showBreaks)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                      top: index == 0
                                                          ? 0.0
                                                          : 8.0,
                                                      bottom: 6.0,
                                                      left: 50.0),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10.0),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withValues(
                                                                alpha: 0.25),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16.0),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8.0,
                                                                      vertical:
                                                                          2.5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50.0),
                                                                color: AppColors.of(
                                                                        context)
                                                                    .text
                                                                    .withValues(
                                                                        alpha:
                                                                            0.90),
                                                              ),
                                                              child: Text(
                                                                'break'.i18n,
                                                                style:
                                                                    TextStyle(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .scaffoldBackgroundColor,
                                                                  fontSize:
                                                                      12.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  height: 1.1,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 10.0),
                                                            Text(
                                                              '${df.format(before.end)} - ${df.format(lesson.start)}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        if (now.isBefore(lesson.start) &&
                                                            now.isAfter(before.end))
                                                          Dot(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .secondary
                                                                .withValues(
                                                                    alpha: .5),
                                                            size: 10.0,
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              LessonViewable(
                                                lesson,
                                                swapDesc: swapDescDay,
                                                customDesc:
                                                    customLessonDesc[
                                                            lesson.id] ??
                                                        lesson.description,
                                                showSubTiles:
                                                    settingsProvider
                                                        .qTimetableSubTiles,
                                              ),
                                            ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Expanded(
                                child: Center(child: empty),
                              ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  void showQuickSettings(BuildContext context) {
    showRoundedModalBottomSheet(
      context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: BottomSheetMenu(items: [
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 16.0, right: 10.0),
            title: Row(
              children: [
                const Icon(Icons.dashboard_rounded),
                const SizedBox(
                  width: 10.0,
                ),
                Text('full_screen_timetable'.i18n),
              ],
            ),
            onTap: () {
              performHapticFeedback(settingsProvider.vibrate);
              if (_tabController.length == 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("empty_timetable".i18n),
                  duration: const Duration(seconds: 2),
                ));
                return;
              }

              Navigator.of(context, rootNavigator: true).pop();

              Navigator.of(context, rootNavigator: true)
                  .push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    FSTimetable(
                  controller: _controller,
                ),
              ))
                  .then((_) {
                SystemChrome.setPreferredOrientations(
                    [DeviceOrientation.portraitUp]);
                setSystemChrome(context);
              });
            },
          ),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 16.0, right: 10.0),
            title: Row(
              children: [
                const Icon(Icons.local_cafe_rounded),
                const SizedBox(
                  width: 10.0,
                ),
                Text('show_breaks'.i18n),
              ],
            ),
            value: Provider.of<SettingsProvider>(context, listen: false)
                .showBreaks,
            onChanged: (v) {
              performHapticFeedback(settingsProvider.vibrate);
              Provider.of<SettingsProvider>(context, listen: false)
                  .update(showBreaks: v);

              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        ),
        // SwitchListTile(
        //   title: Row(
        //     children: [
        //       const Icon(Icons.access_time_rounded),
        //       const SizedBox(
        //         width: 10.0,
        //       ),
        //       Text('show_lesson_num'.i18n),
        //     ],
        //   ),
        //   value: Provider.of<SettingsProvider>(context, listen: false)
        //       .qTimetableLessonNum,
        //   onChanged: (v) {
        //     Provider.of<SettingsProvider>(context, listen: false)
        //         .update(qTimetableLessonNum: v);

        //     Navigator.of(context, rootNavigator: true).pop();
        //   },
        // ),
        const SizedBox(
          height: 10.0,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface),
          child: SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 16.0, right: 10.0),
            title: Row(
              children: [
                const Icon(Icons.edit_document),
                const SizedBox(width: 10.0),
                Text('show_exams_homework'.i18n),
              ],
            ),
            value: Provider.of<SettingsProvider>(context, listen: false)
                .qTimetableSubTiles,
            onChanged: (v) {
              performHapticFeedback(settingsProvider.vibrate);
              Provider.of<SettingsProvider>(context, listen: false)
                  .update(qTimetableSubTiles: v);
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        ),
      ]),
    );
  }
}

// difference.inDays is not reliable
bool _sameDate(DateTime a, DateTime b) =>
    (a.year == b.year && a.month == b.month && a.day == b.day);
