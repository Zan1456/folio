import 'dart:math';

import 'package:animations/animations.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/exam.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio/helpers/average_helper.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/panel/panel.dart';
import 'package:folio_mobile_ui/common/trend_display.dart';
import 'package:folio_mobile_ui/common/widgets/cretification/certification_tile.dart';
import 'package:folio/ui/widgets/grade/grade_tile.dart';
import 'package:folio_mobile_ui/common/widgets/grade/grade_viewable.dart';
import 'package:folio_mobile_ui/common/hero_scrollview.dart';
import 'package:folio_mobile_ui/pages/grades/calculator/grade_calculator.dart';
import 'package:folio_mobile_ui/pages/grades/calculator/grade_calculator_provider.dart';
import 'package:folio_mobile_ui/pages/grades/grades_count.dart';
import 'package:folio_mobile_ui/pages/grades/graph.dart';
import 'package:folio_mobile_ui/pages/grades/subject_grades_container.dart';
// import 'package:folio_plus/models/premium_scopes.dart';
// import 'package:folio_plus/providers/plus_provider.dart';
import 'package:folio_plus/ui/mobile/goal_planner/goal_state_screen.dart';
// import 'package:folio_plus/ui/mobile/plus/upsell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:folio_plus/ui/mobile/goal_planner/goal_track_popup.dart';
import 'grades_page.i18n.dart';
// import 'package:folio_plus/ui/mobile/goal_planner/new_goal.dart';

class GradeSubjectView extends StatefulWidget {
  const GradeSubjectView(this.subject, {super.key, this.groupAverage = 0.0});

  final GradeSubject subject;
  final double groupAverage;

  void push(BuildContext context, {bool root = false}) {
    Navigator.of(context, rootNavigator: root)
        .push(CupertinoPageRoute(builder: (context) => this));
  }

  @override
  State<GradeSubjectView> createState() => _GradeSubjectViewState();
}

class _GradeSubjectViewState extends State<GradeSubjectView>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers
  PersistentBottomSheetController? _sheetController;
  final ScrollController _scrollController = ScrollController();

  List<Widget> gradeTiles = [];

  // Providers
  late GradeProvider gradeProvider;
  late GradeCalculatorProvider calculatorProvider;
  late SettingsProvider settingsProvider;
  late DatabaseProvider dbProvider;
  late UserProvider user;
  late ExamProvider examProvider;

  late double average;
  late Widget gradeGraph;

  bool gradeCalcMode = false;

  String plan = '';

  List<Grade> getSubjectGrades(GradeSubject subject) => !gradeCalcMode
      ? gradeProvider.grades.where((e) => e.subject == subject).toList()
      : calculatorProvider.grades.where((e) => e.subject == subject).toList();
  List<Exam> getSubjectExams(GradeSubject subject) =>
      examProvider.exams.where((e) => e.subject == subject).toList();

  bool showGraph(List<Grade> subjectGrades) {
    if (gradeCalcMode) return true;

    final gradeDates = subjectGrades.map((e) => e.date.millisecondsSinceEpoch);
    final maxGradeDate = gradeDates.fold(0, max);
    final minGradeDate = gradeDates.fold(0, min);
    if (maxGradeDate - minGradeDate < const Duration(days: 5).inMilliseconds) {
      return false; // naplo/#78
    }

    return subjectGrades.where((e) => e.type == GradeType.midYear).length > 1;
  }

  void buildTiles(List<Grade> subjectGrades) {
    List<Widget> tiles = [];

    tiles.add(Panel(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subject.renamedTo ?? widget.subject.name.capital(),
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(
            height: 8.0,
          ),
          Text(
            ((widget.subject.teacher?.isRenamed ?? false) &&
                        settingsProvider.renamedTeachersEnabled
                    ? widget.subject.teacher?.renamedTo
                    : widget.subject.teacher?.name.capital()) ??
                '',
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ],
      ),
    ));

    if (showGraph(subjectGrades)) {
      tiles.add(gradeGraph);
    } else {
      tiles.add(Container(height: 20.0));
    }

    tiles.add(Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Panel(
        child: GradesCount(grades: getSubjectGrades(widget.subject).toList()),
      ),
    ));

    // ignore: no_leading_underscores_for_local_identifiers
    List<Widget> _tiles = [];

    if (!gradeCalcMode) {
      subjectGrades.sort((a, b) => -a.date.compareTo(b.date));

      _tiles.add(const SizedBox(
        height: 4.0,
      ));

      for (var grade in subjectGrades) {
        if (grade.type == GradeType.midYear) {
          _tiles.add(GradeViewable(grade));
        } else {
          _tiles.add(CertificationTile(
            grade,
            padding: EdgeInsets.only(
                bottom: 8.0,
                top: (subjectGrades.first.id == grade.id) ? 0.0 : 8.0),
            newStyle: true,
          ));
        }
      }

      _tiles.add(const SizedBox(
        height: 4.0,
      ));
    } else if (subjectGrades.isNotEmpty) {
      _tiles.add(const SizedBox(
        height: 8.0,
      ));

      subjectGrades.sort((a, b) => -a.date.compareTo(b.date));
      for (var grade in subjectGrades) {
        _tiles.add(GradeTile(grade));
      }

      _tiles.add(const SizedBox(
        height: 8.0,
      ));
    }
    tiles.add(
      PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> primaryAnimation,
          Animation<double> secondaryAnimation,
        ) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
            fillColor: Colors.transparent,
            child: child,
          );
        },
        child: _tiles.isNotEmpty
            ? Panel(
                key: ValueKey(gradeCalcMode),
                title: Text(
                  gradeCalcMode ? "Ghost Grades".i18n : "Grades".i18n,
                ),
                child: Column(
                  children: _tiles,
                ))
            : const Empty(),
      ),
    );

    tiles.add(Padding(
        padding: EdgeInsets.only(bottom: !gradeCalcMode ? 24.0 : 269.0)));
    gradeTiles = List.castFrom(tiles);
  }

  @override
  void initState() {
    super.initState();
    user = Provider.of<UserProvider>(context, listen: false);
    dbProvider = Provider.of<DatabaseProvider>(context, listen: false);

    fetchGoalPlans();
  }

  void fetchGoalPlans() async {
    plan = (await dbProvider.userQuery
            .subjectGoalPlans(userId: user.id!))[widget.subject.id] ??
        '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    gradeProvider = Provider.of<GradeProvider>(context);
    calculatorProvider = Provider.of<GradeCalculatorProvider>(context);
    settingsProvider = Provider.of<SettingsProvider>(context);
    examProvider = Provider.of<ExamProvider>(context);

    List<Grade> subjectGrades = getSubjectGrades(widget.subject).toList();
    average = AverageHelper.averageEvals(subjectGrades);
    final prevAvg = subjectGrades.isNotEmpty
        ? AverageHelper.averageEvals(subjectGrades
            .where((e) => e.date.isBefore(subjectGrades
                .reduce((v, e) => e.date.isAfter(v.date) ? e : v)
                .date
                .subtract(const Duration(days: 30))))
            .toList())
        : 0.0;

    gradeGraph = Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Panel(
        title: average != prevAvg
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TrendDisplay(current: average, previous: prevAvg),
                ],
              )
            : null,
        child: Container(
          padding: const EdgeInsets.only(top: 16.0, right: 12.0),
          child: GradeGraph(subjectGrades,
              dayThreshold: 5, classAvg: widget.groupAverage),
        ),
      ),
    );

    if (!gradeCalcMode) {
      buildTiles(subjectGrades);
    } else {
      List<Grade> ghostGrades = calculatorProvider.ghosts
          .where((e) => e.subject == widget.subject)
          .toList();
      buildTiles(ghostGrades);
    }

    return Scaffold(
        key: _scaffoldKey,
        body: RefreshIndicator(
          onRefresh: () async {},
          color: Theme.of(context).colorScheme.secondary,
          child: HeroScrollView(
            showTitleUnscroll: false,
            onClose: () {
              if (_sheetController != null && gradeCalcMode) {
                _sheetController!.close();
              } else {
                Navigator.of(context).pop();
              }
            },
            navBarItems: [
              // Averages (compact)
              if (widget.groupAverage != 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.groupAverage.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
              ],
              if (average != 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Text(
                    average.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
              ],
              // Action icon buttons
              if (!gradeCalcMode &&
                  subjectGrades
                      .where((e) => e.type == GradeType.midYear)
                      .isNotEmpty) ...[
                GestureDetector(
                  onTap: () => gradeCalc(context),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(Icons.add_rounded,
                        size: 16.0,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 6.0),
                GestureDetector(
                  onTap: () =>
                      GoalTrackPopup.show(context, subject: widget.subject),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: plan != ''
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(Icons.flag_rounded,
                        size: 16.0,
                        color: plan != ''
                            ? Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer
                            : Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 6.0),
              ],
              // Goal state icon
              if (plan != '') ...[
                GestureDetector(
                  onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                      builder: (context) =>
                          GoalStateScreen(subject: widget.subject))),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(Icons.track_changes_rounded,
                        size: 16.0,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer),
                  ),
                ),
                const SizedBox(width: 6.0),
              ],
              const SizedBox(width: 6.0),
            ],
            icon: SubjectIcon.resolveVariant(
                subject: widget.subject, context: context),
            scrollController: _scrollController,
            title: widget.subject.renamedTo ?? widget.subject.name.capital(),
            italic: settingsProvider.renamedSubjectsItalics &&
                widget.subject.isRenamed,
            //   child: TabBarView(
            //       physics: const BouncingScrollPhysics(),
            //       controller: _tabController,
            //       children: List.generate(
            //           3, (index) => filterViewBuilder(context, index))),
            // ),
            child: SubjectGradesContainer(
              child: CupertinoScrollbar(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  shrinkWrap: true,
                  itemBuilder: (context, index) => gradeTiles[index],
                  itemCount: gradeTiles.length,
                ),
              ),
            ),
          ),
        ));
  }

  Widget filterViewBuilder(context, int activeData) {
    return Container();
  }

  void gradeCalc(BuildContext context) {
    // Scroll to the top of the page
    _scrollController.animateTo(100,
        duration: const Duration(milliseconds: 500), curve: Curves.ease);

    calculatorProvider.clear();
    calculatorProvider.addAllGrades(gradeProvider.grades);

    _sheetController = _scaffoldKey.currentState?.showBottomSheet(
      (context) => RoundedBottomSheet(
          borderRadius: 14.0,
          showHandle: false,
          child: GradeCalculator(widget.subject)),
      backgroundColor: const Color(0x00000000),
      elevation: 12.0,
    );

    // Hide the fab and grades
    setState(() {
      gradeCalcMode = true;
    });

    _sheetController!.closed.then((value) {
      // Show fab and grades
      if (mounted) {
        setState(() {
          gradeCalcMode = false;
        });
      }
    });
  }
}
