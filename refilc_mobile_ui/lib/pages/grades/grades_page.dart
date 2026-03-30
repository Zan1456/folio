// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:refilc/api/providers/update_provider.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc/theme/colors/utils.dart';
import 'package:refilc/ui/widgets/grade/grade_tile.dart';
import 'package:refilc_kreta_api/models/exam.dart';
import 'package:refilc_kreta_api/providers/exam_provider.dart';
import 'package:refilc_kreta_api/providers/grade_provider.dart';
import 'package:refilc/api/providers/user_provider.dart';
import 'package:refilc_kreta_api/models/grade.dart';
import 'package:refilc_kreta_api/models/subject.dart';
import 'package:refilc_kreta_api/models/group_average.dart';
import 'package:refilc_kreta_api/providers/homework_provider.dart';
import 'package:refilc_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu.dart';
import 'package:refilc_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:refilc_mobile_ui/common/empty.dart';
import 'package:refilc_mobile_ui/common/panel/panel.dart';
import 'package:refilc_mobile_ui/common/widgets/exam/exam_viewable.dart';
import 'package:refilc_mobile_ui/common/widgets/grade/grade_subject_tile.dart';
import 'package:refilc_mobile_ui/common/trend_display.dart';
import 'package:refilc_mobile_ui/pages/grades/fail_warning.dart';
import 'package:refilc_mobile_ui/pages/grades/grades_count_item.dart';
import 'package:refilc_mobile_ui/pages/grades/graph.dart';
import 'package:refilc_mobile_ui/pages/grades/grade_subject_view.dart';
import 'package:refilc_mobile_ui/screens/navigation/navigation_route_handler.dart';
import 'package:refilc_mobile_ui/screens/navigation/navigation_screen.dart';
import 'package:refilc_plus/models/premium_scopes.dart';
import 'package:refilc_plus/providers/plus_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refilc/helpers/average_helper.dart';
import 'package:refilc_plus/ui/mobile/plus/premium_inline.dart';
import 'average_selector.dart';
import 'calculator/grade_calculator.dart';
import 'calculator/grade_calculator_provider.dart';
import 'grades_page.i18n.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  static void jump(BuildContext context, {GradeSubject? subject}) {
    // Go to timetable page with arguments
    NavigationScreen.of(context)
        ?.customRoute(navigationPageRoute((context) => const GradesPage()));

    NavigationScreen.of(context)?.setPage("grades");

    // Show initial Lesson
    if (subject != null) {
      GradeSubjectView(subject, groupAverage: 0.0).push(context, root: true);
    }
  }

  @override
  GradesPageState createState() => GradesPageState();
}

class GradesPageState extends State<GradesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  PersistentBottomSheetController? _sheetController;

  late UserProvider user;
  late GradeProvider gradeProvider;
  late UpdateProvider updateProvider;
  late GradeCalculatorProvider calculatorProvider;
  late HomeworkProvider homeworkProvider;
  late ExamProvider examProvider;
  late SettingsProvider settingsProvider;

  late String firstName;
  List<Widget> subjectTiles = [];

  int avgDropValue = 0;
  double subjectAvg = 0.0;

  bool gradeCalcMode = false;
  bool importedViewMode = false;

  List<Grade> jsonGrades = [];

  List<Grade> getSubjectGrades(GradeSubject subject,
          {int days = 0}) =>
      !gradeCalcMode
          ? (importedViewMode ? jsonGrades : gradeProvider.grades)
              .where((e) =>
                  e.subject == subject &&
                  e.type == GradeType.midYear &&
                  (days == 0 ||
                      e.date.isBefore(
                          DateTime.now().subtract(Duration(days: days)))))
              .toList()
          : calculatorProvider.grades
              .where((e) => e.subject == subject)
              .toList();

  void generateTiles() {
    List<GradeSubject> subjects =
        (importedViewMode ? jsonGrades : gradeProvider.grades)
            .map((e) => GradeSubject(
                  category: e.subject.category,
                  id: e.subject.id,
                  name: e.subject.name,
                  renamedTo: e.subject.renamedTo,
                  customRounding: e.subject.customRounding,
                  teacher: e.teacher,
                ))
            .toSet()
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    List<Widget> tiles = [];

    Map<GradeSubject, double> subjectAvgs = {};

    if (!gradeCalcMode) {
      var i = 0;

      tiles.addAll(subjects.map((subject) {
        List<Grade> subjectGrades = getSubjectGrades(subject);

        double avg = AverageHelper.averageEvals(subjectGrades);
        double averageBefore = 0.0;

        if (avgDropValue != 0) {
          List<Grade> gradesBefore =
              getSubjectGrades(subject, days: avgDropValue);
          averageBefore = avgDropValue == 0
              ? 0.0
              : AverageHelper.averageEvals(gradesBefore);
        }
        var nullavg = GroupAverage(average: 0.0, subject: subject, uid: "0");
        double groupAverage = gradeProvider.groupAverages
            .firstWhere((e) => e.subject == subject, orElse: () => nullavg)
            .average;

        if (avg != 0) subjectAvgs[subject] = avg;

        i++;

        int homeworkCount = homeworkProvider.homework
            .where((e) =>
                e.subject.id == subject.id &&
                e.deadline.isAfter(DateTime.now()))
            .length;
        bool hasHomework = homeworkCount > 0;

        List<Exam> allExams = examProvider.exams;
        try {
          allExams.sort((a, b) => a.date.compareTo(b.date));
        } catch (e) {
          if (kDebugMode) {
            print('failed to sort exams, reason: flutter');
          }
          allExams = [];
        }

        Exam? nearestExam = allExams.firstWhereOrNull((e) =>
            e.subject.id == subject.id && e.writeDate.isAfter(DateTime.now()));

        bool hasUnder = (hasHomework || nearestExam != null) &&
            Provider.of<SettingsProvider>(context, listen: false)
                .qSubjectsSubTiles;

        return Padding(
          padding: i > 1 ? const EdgeInsets.only(top: 9.0) : EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    if (Provider.of<SettingsProvider>(context, listen: false)
                        .shadowEffect)
                      BoxShadow(
                        offset: const Offset(0, 21),
                        blurRadius: 23.0,
                        color: Theme.of(context).shadowColor,
                      )
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16.0),
                    topRight: const Radius.circular(16.0),
                    bottomLeft: hasUnder
                        ? const Radius.circular(8.0)
                        : const Radius.circular(16.0),
                    bottomRight: hasUnder
                        ? const Radius.circular(8.0)
                        : const Radius.circular(16.0),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 6.0),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                    ),
                    child: GradeSubjectTile(
                      subject,
                      averageBefore: averageBefore,
                      average: avg,
                      groupAverage: avgDropValue == 0 ? groupAverage : 0.0,
                      onTap: () {
                        GradeSubjectView(subject, groupAverage: groupAverage)
                            .push(context, root: true);
                      },
                    ),
                  ),
                ),
              ),
              if (hasUnder)
                const SizedBox(
                  height: 6.0,
                ),
              if (hasHomework &&
                  Provider.of<SettingsProvider>(context, listen: false)
                      .qSubjectsSubTiles)
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      if (Provider.of<SettingsProvider>(context, listen: false)
                          .shadowEffect)
                        BoxShadow(
                          offset: const Offset(0, 21),
                          blurRadius: 23.0,
                          color: Theme.of(context).shadowColor,
                        )
                    ],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8.0),
                      topRight: const Radius.circular(8.0),
                      bottomLeft: nearestExam != null
                          ? const Radius.circular(8.0)
                          : const Radius.circular(16.0),
                      bottomRight: nearestExam != null
                          ? const Radius.circular(8.0)
                          : const Radius.circular(16.0),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 8.0,
                      left: 15.0,
                      right: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'you_have_hw'.i18n.fill([homeworkCount]),
                          style: const TextStyle(
                              fontSize: 15.0, fontWeight: FontWeight.w500),
                        ),
                        // const Icon(
                        //   Icons.keyboard_arrow_right_rounded,
                        //   grade: 0.5,
                        //   size: 20.0,
                        // )
                      ],
                    ),
                  ),
                ),
              if (hasHomework &&
                  nearestExam != null &&
                  Provider.of<SettingsProvider>(context).qSubjectsSubTiles)
                const SizedBox(
                  height: 6.0,
                ),
              if (nearestExam != null &&
                  Provider.of<SettingsProvider>(context).qSubjectsSubTiles)
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      if (Provider.of<SettingsProvider>(context, listen: false)
                          .shadowEffect)
                        BoxShadow(
                          offset: const Offset(0, 21),
                          blurRadius: 23.0,
                          color: Theme.of(context).shadowColor,
                        )
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                      bottomLeft: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: ExamViewable(
                    nearestExam,
                    showSubject: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 6.0),
                  ),
                ),
            ],
          ),
        );
      }));
    } else {
      tiles.clear();

      List<Grade> ghostGrades = calculatorProvider.ghosts;
      ghostGrades.sort((a, b) => -a.date.compareTo(b.date));

      List<GradeTile> _gradeTiles = [];
      for (Grade grade in ghostGrades) {
        _gradeTiles.add(GradeTile(
          grade,
          viewOverride: true,
        ));
      }

      tiles.add(
        _gradeTiles.isNotEmpty
            ? Panel(
                key: ValueKey(gradeCalcMode),
                title: Text(
                  "Ghost Grades".i18n,
                ),
                child: Column(
                  children: _gradeTiles,
                ),
              )
            : const SizedBox(),
      );
    }

    if (tiles.isNotEmpty || gradeCalcMode) {
      if (!gradeCalcMode) {
        tiles.insert(1, FailWarning(subjectAvgs: subjectAvgs));

        // tiles.insert(4, const PanelHeader(padding: EdgeInsets.only(top: 12.0)));
        // tiles.add(const PanelFooter(padding: EdgeInsets.only(bottom: 12.0)));
      }
      tiles.add(Padding(
        padding: EdgeInsets.only(bottom: !gradeCalcMode ? 24.0 : 250.0),
      ));
    } else {
      tiles.insert(
        0,
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Empty(subtitle: "empty".i18n),
        ),
      );
    }

    // print('rounding:');
    // print(settingsProvider.rounding);

    subjectAvg = subjectAvgs.isNotEmpty
        ? subjectAvgs.values.fold(
                0.0,
                (double a, double b) =>
                    a.round().toDouble() + b.round().toDouble()) /
            subjectAvgs.length
        : 0.0;


    tiles.add(Provider.of<PlusProvider>(context, listen: false).hasPremium
        ? const SizedBox()
        : const Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: PremiumInline(features: [
              PremiumInlineFeature.goal,
              PremiumInlineFeature.stats,
            ]),
          ));

    // padding
    tiles.add(const SizedBox(height: 32.0));

    subjectTiles = List.castFrom(tiles);
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    gradeProvider = Provider.of<GradeProvider>(context);
    updateProvider = Provider.of<UpdateProvider>(context);
    calculatorProvider = Provider.of<GradeCalculatorProvider>(context);
    homeworkProvider = Provider.of<HomeworkProvider>(context);
    examProvider = Provider.of<ExamProvider>(context);
    settingsProvider = Provider.of<SettingsProvider>(context);

    context.watch<PlusProvider>();

    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];

    final double totalClassAvg = gradeProvider.groupAverages.isEmpty
        ? 0.0
        : gradeProvider.groupAverages
                .map((e) => e.average)
                .fold(0.0, (double a, double b) => a + b) /
            gradeProvider.groupAverages.length;

    final now =
        (importedViewMode ? jsonGrades : gradeProvider.grades).isNotEmpty
            ? (importedViewMode ? jsonGrades : gradeProvider.grades)
                .reduce((v, e) => e.date.isAfter(v.date) ? e : v)
                .date
            : DateTime.now();

    final currentStudentAvg = AverageHelper.averageEvals(!gradeCalcMode
        ? (importedViewMode ? jsonGrades : gradeProvider.grades)
            .where((e) => e.type == GradeType.midYear)
            .toList()
        : calculatorProvider.grades);

    final prevStudentAvg = AverageHelper.averageEvals((importedViewMode
            ? jsonGrades
            : gradeProvider.grades)
        .where((e) => e.type == GradeType.midYear)
        .where((e) => e.date.isBefore(now.subtract(const Duration(days: 30))))
        .toList());

    List<Grade> graphGrades = !gradeCalcMode
        ? (importedViewMode ? jsonGrades : gradeProvider.grades)
            .where((e) =>
                e.type == GradeType.midYear &&
                (avgDropValue == 0 ||
                    e.date.isAfter(
                        DateTime.now().subtract(Duration(days: avgDropValue)))))
            .toList()
        : calculatorProvider.grades
            .where(((e) =>
                avgDropValue == 0 ||
                e.date.isAfter(
                    DateTime.now().subtract(Duration(days: avgDropValue)))))
            .toList();

    generateTiles();

    return Scaffold(
      key: _scaffoldKey,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            centerTitle: false,
            pinned: true,
            floating: false,
            snap: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0.0,
            elevation: 0,
            shadowColor: Colors.transparent,
            automaticallyImplyLeading: false,
            actions: [
              if (!gradeCalcMode)
                Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: IconButton(
                    onPressed: () => showQuickSettings(context),
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
            title: Row(
              children: [
                const SizedBox(width: 8.0),
                Text(
                  "page_title_grades".i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 28.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (currentStudentAvg > 0)
                  AnimatedOpacity(
                    opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          currentStudentAvg.toStringAsFixed(2),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Hero avg card — scrolls away
          if (currentStudentAvg > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(28.0),
                  ),
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "page_title_grades".i18n,
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currentStudentAvg.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 58.0,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8.0),
                                    child: TrendDisplay(
                                      previous: prevStudentAvg,
                                      current: currentStudentAvg,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (subjectAvg > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 14.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.65),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    subjectAvg.toStringAsFixed(2),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                          ],
                          if (totalClassAvg >= 1.0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_rounded,
                                    size: 14.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.65),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    totalClassAvg.toStringAsFixed(2),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontSize: 22.0,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14.0),
                      Row(
                        children: [
                          AverageSelector(
                            value: avgDropValue,
                            onChanged: (v) => setState(() {
                              avgDropValue = v ?? 0;
                              generateTiles();
                            }),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showGradesStatsModal(
                                context, graphGrades, totalClassAvg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    size: 16.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    "stats".i18n,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        body: RefreshIndicator(
          onRefresh: () => gradeProvider.fetch(),
          color: Theme.of(context).colorScheme.secondary,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: max(subjectTiles.length, 1),
            itemBuilder: (context, index) {
              if (subjectTiles.isNotEmpty) {
                EdgeInsetsGeometry panelPadding =
                    const EdgeInsets.symmetric(horizontal: 24.0);

                if (subjectTiles[index].runtimeType == GradeSubjectTile) {
                  return Padding(
                      padding: panelPadding,
                      child: PanelBody(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: subjectTiles[index],
                      ));
                } else {
                  return Padding(
                      padding: panelPadding, child: subjectTiles[index]);
                }
              } else {
                return Container();
              }
            },
          ),
        ),
      ),
    );
  }

  void _showGradesStatsModal(BuildContext context, List<Grade> grades, double classAvg) {
    List<int> counts = List.generate(
        5, (i) => grades.where((e) => e.value.value == i + 1).length);
    int total = counts.reduce((a, b) => a + b);
    double maxCount =
        counts.reduce((a, b) => a > b ? a : b) + counts.reduce((a, b) => a > b ? a : b) / 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'grades_cnt'.i18n.fill([total.toString()]),
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.only(top: 12.0, right: 12.0),
              child: GradeGraph(grades, dayThreshold: 2, classAvg: classAvg),
            ),
            const SizedBox(height: 8.0),
            ...counts.reversed
                .toList()
                .asMap()
                .entries
                .map((entry) {
              final value = 5 - entry.key;
              final count = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: GradesCountItem(
                  count: count,
                  value: value,
                  total: maxCount,
                ),
              );
            }),
          ],
        ),
      ),
      ),
    );
  }

  void gradeCalcTotal(BuildContext context) {
    calculatorProvider.clear();
    calculatorProvider
        .addAllGrades((importedViewMode ? jsonGrades : gradeProvider.grades));

    _sheetController = _scaffoldKey.currentState?.showBottomSheet(
      (context) => const RoundedBottomSheet(
          borderRadius: 14.0,
          showHandle: false,
          child: GradeCalculator(null)),
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
            title: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded),
                const SizedBox(
                  width: 10.0,
                ),
                Text('grade_calc'.i18n),
              ],
            ),
            onTap: () {
              // if (!Provider.of<PlusProvider>(context, listen: false)
              //     .hasScope(PremiumScopes.totalGradeCalculator)) {
              //   PlusLockedFeaturePopup.show(
              //       context: context, feature: PremiumFeature.gradeCalculation);
              //   return;
              // }

              // SoonAlert.show(context: context);
              gradeCalcTotal(context);

              Navigator.of(context, rootNavigator: true).pop();
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
          child: ListTile(
            title: Row(
              children: [
                const Icon(Icons.toll_rounded),
                const SizedBox(
                  width: 10.0,
                ),
                Text('import_grades'.i18n),
              ],
            ),
            trailing: importedViewMode ? const Icon(Icons.close_rounded) : null,
            onTap: () {
              if (importedViewMode) {
                importedViewMode = false;

                generateTiles();
                setState(() {});

                Navigator.of(context, rootNavigator: true).pop();
                return;
              }

              if (!Provider.of<PlusProvider>(context, listen: false)
                  .hasScope(PremiumScopes.gradeExporting)) {
                return;
              }

              // show file picker
              FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              ).then((value) {
                if (value != null) {
                  final File file = File(value.files.single.path!);
                  final String content = file.readAsStringSync();
                  final List<dynamic> json = jsonDecode(content);

                  jsonGrades = json.map((e) => Grade.fromJson(e)).toList();
                  importedViewMode = true;

                  generateTiles();
                  setState(() {});
                }
              });

              Navigator.of(context, rootNavigator: true).pop();
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
            title: Row(
              children: [
                const Icon(Icons.edit_document),
                const SizedBox(
                  width: 10.0,
                ),
                Text('show_exams_homework'.i18n),
              ],
            ),
            value: Provider.of<SettingsProvider>(context, listen: false)
                .qSubjectsSubTiles,
            onChanged: (v) {
              Provider.of<SettingsProvider>(context, listen: false)
                  .update(qSubjectsSubTiles: v);

              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        ),
      ]),
    );
  }
}
