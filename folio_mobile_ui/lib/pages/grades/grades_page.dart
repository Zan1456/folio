import 'dart:math';

import 'package:flutter/material.dart';
import 'package:folio/helpers/average_helper.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/ui/widgets/grade/grade_tile.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/models/group_average.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_mobile_ui/common/average_display.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/haptic.dart';
import 'package:folio_mobile_ui/common/panel/panel.dart';
import 'package:folio_mobile_ui/common/trend_display.dart';
import 'package:folio_mobile_ui/common/widgets/cretification/certification_tile.dart';
import 'package:folio_mobile_ui/common/widgets/grade/grade_subject_tile.dart';
import 'package:folio_mobile_ui/common/widgets/grade/grade_viewable.dart';
import 'package:folio_mobile_ui/pages/grades/calculator/grade_calculator.dart';
import 'package:folio_mobile_ui/pages/grades/calculator/grade_calculator_provider.dart';
import 'package:folio_mobile_ui/pages/grades/graph.dart';
import 'package:folio_mobile_ui/pages/grades/subject_grades_container.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_route_handler.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_screen.dart';
import 'package:provider/provider.dart';

import 'grades_page.i18n.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  static void jump(BuildContext context) {
    NavigationScreen.of(context)
        ?.customRoute(navigationPageRoute((context) => const GradesPage()));
    NavigationScreen.of(context)?.setPage("grades");
  }

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  int _periodDays = 0;
  GradeSubject? _selectedSubject;
  double _selectedGroupAvg = 0.0;
  PersistentBottomSheetController? _sheetController;

  static const _periods = [0, 90, 30, 14, 7];
  static const _periodKeys = [
    'annual_average',
    '3_months_average',
    '30_days_average',
    '14_days_average',
    '7_days_average',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;
    // 1. Close calculator sheet if open
    if (_sheetController != null) {
      _sheetController!.close();
      return true;
    }
    // 2. Go back to subjects tab when on subject detail tab
    if (_tabController.index == 1) {
      _tabController.animateTo(0);
      return true;
    }
    // 3. Close modal route if on top of inner navigator
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return true;
    }
    return false;
  }

  List<Grade> _applyPeriod(List<Grade> grades) {
    if (_periodDays == 0) return grades;
    final cutoff = DateTime.now().subtract(Duration(days: _periodDays));
    return grades.where((g) => g.date.isAfter(cutoff)).toList();
  }

  void _openCalculator(BuildContext context) {
    final calcProvider =
        Provider.of<GradeCalculatorProvider>(context, listen: false);
    final gradeProvider = Provider.of<GradeProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    performHapticFeedback(settings.vibrate);
    calcProvider.clear();
    calcProvider.addAllGrades(gradeProvider.grades);

    final subject = _tabController.index == 1 ? _selectedSubject : null;

    _sheetController = _scaffoldKey.currentState?.showBottomSheet(
      (ctx) => RoundedBottomSheet(
        borderRadius: 14.0,
        showHandle: false,
        child: GradeCalculator(subject),
      ),
      backgroundColor: const Color(0x00000000),
      elevation: 12.0,
    );

    _sheetController?.closed.then((_) {
      if (mounted) {
        calcProvider.clear();
        setState(() => _sheetController = null);
      }
    });
  }

  void _showPeriodModal(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    performHapticFeedback(settings.vibrate);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _periods.asMap().entries.map((entry) {
              final isSelected = _periodDays == entry.value;
              return ListTile(
                title: Text(
                  _periodKeys[entry.key].i18n,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(ctx).colorScheme.secondary)
                    : null,
                onTap: () {
                  setState(() => _periodDays = entry.value);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showStatsModal(
      BuildContext context, List<Grade> grades, double classAvg) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    performHapticFeedback(settings.vibrate);
    final counts = List.generate(
        5, (i) => grades.where((g) => g.value.value == i + 1).length);
    final total = counts.fold(0, (a, b) => a + b);
    final maxCount = counts.isNotEmpty ? counts.reduce(max).toDouble() : 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'grades_cnt'.i18n.fill([total.toString()]),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (grades.length >= 2) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GradeGraph(grades, classAvg: classAvg),
                ),
              ],
              const SizedBox(height: 16),
              ...counts.reversed.toList().asMap().entries.map((e) {
                final value = 5 - e.key;
                final count = e.value;
                final color = gradeColor(context: ctx, value: value.toDouble());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            value.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: maxCount > 0 ? count / maxCount : 0,
                            backgroundColor: Theme.of(ctx)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                                color.withValues(alpha: 0.75)),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 24,
                        child: Text(
                          count.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradeProvider = Provider.of<GradeProvider>(context);
    final calcProvider = Provider.of<GradeCalculatorProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final isCalcMode = calcProvider.ghosts.isNotEmpty;
    final rawGrades = isCalcMode ? calcProvider.grades : gradeProvider.grades;
    final allMidYear = rawGrades
        .where((g) =>
            g.type == GradeType.midYear ||
            (isCalcMode && g.type == GradeType.ghost))
        .toList();
    final filtered = _applyPeriod(allMidYear);

    final subjects = rawGrades
        .map((g) => GradeSubject(
              id: g.subject.id,
              name: g.subject.name,
              category: g.subject.category,
              renamedTo: g.subject.renamedTo,
              customRounding: g.subject.customRounding,
              teacher: g.teacher,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final subjectAvgMap = <GradeSubject, double>{};
    for (final s in subjects) {
      final avg = AverageHelper.averageEvals(
          filtered.where((g) => g.subject == s).toList());
      if (avg > 0) subjectAvgMap[s] = avg;
    }

    final currentAvg = AverageHelper.averageEvals(filtered);
    final prevAvg = AverageHelper.averageEvals(allMidYear
        .where((g) =>
            g.date.isBefore(DateTime.now().subtract(const Duration(days: 30))))
        .toList());

    final totalClassAvg = gradeProvider.groupAverages.isEmpty
        ? 0.0
        : gradeProvider.groupAverages
                .map((e) => e.average)
                .fold(0.0, (a, b) => a + b) /
            gradeProvider.groupAverages.length;

    final subjectAvg = subjectAvgMap.isEmpty
        ? 0.0
        : subjectAvgMap.values.fold(0.0, (a, b) => a + b) /
            subjectAvgMap.length;

    final currentPeriodKey = _periodKeys[_periods.indexOf(_periodDays)];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              'page_title_grades'.i18n,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (currentAvg > 0) ...[
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentAvg.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_sheetController == null &&
              _tabController.index == 1 &&
              !isCalcMode)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(
                  isCalcMode
                      ? Icons.calculate_rounded
                      : Icons.calculate_outlined,
                  color: isCalcMode
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => _openCalculator(context),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'subjects_tab'.i18n),
            Tab(text: 'grades_tab'.i18n),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SubjectsTab(
            gradeProvider: gradeProvider,
            settings: settings,
            subjects: subjects,
            subjectAvgMap: subjectAvgMap,
            currentAvg: currentAvg,
            prevAvg: prevAvg,
            totalClassAvg: totalClassAvg,
            subjectAvg: subjectAvg,
            filteredGrades: filtered,
            periodDays: _periodDays,
            currentPeriodKey: currentPeriodKey,
            onPeriodTap: () => _showPeriodModal(context),
            onSubjectTap: (subject, groupAvg) {
              setState(() {
                _selectedSubject = subject;
                _selectedGroupAvg = groupAvg;
              });
              _tabController.animateTo(1);
            },
            onShowStats: (grades) =>
                _showStatsModal(context, grades, totalClassAvg),
          ),
          _selectedSubject != null
              ? _SubjectGradesView(
                  key: ValueKey(_selectedSubject),
                  subject: _selectedSubject!,
                  groupAverage: _selectedGroupAvg,
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 52,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'select_subject'.i18n,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
// ─── Tab 0: Tantárgyak ───────────────────────────────────────────────────────

class _SubjectsTab extends StatelessWidget {
  const _SubjectsTab({
    required this.gradeProvider,
    required this.settings,
    required this.subjects,
    required this.subjectAvgMap,
    required this.currentAvg,
    required this.prevAvg,
    required this.totalClassAvg,
    required this.subjectAvg,
    required this.filteredGrades,
    required this.periodDays,
    required this.currentPeriodKey,
    required this.onPeriodTap,
    required this.onSubjectTap,
    required this.onShowStats,
  });

  final GradeProvider gradeProvider;
  final SettingsProvider settings;
  final List<GradeSubject> subjects;
  final Map<GradeSubject, double> subjectAvgMap;
  final double currentAvg, prevAvg, totalClassAvg, subjectAvg;
  final List<Grade> filteredGrades;
  final int periodDays;
  final String currentPeriodKey;
  final VoidCallback onPeriodTap;
  final void Function(GradeSubject, double) onSubjectTap;
  final ValueChanged<List<Grade>> onShowStats;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => gradeProvider.fetch(),
      color: Theme.of(context).colorScheme.secondary,
      child: ListView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 72),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        children: [
          if (currentAvg > 0)
            _HeroCard(
              currentAvg: currentAvg,
              prevAvg: prevAvg,
              totalClassAvg: totalClassAvg,
              subjectAvg: subjectAvg,
              currentPeriodKey: currentPeriodKey,
              onPeriodTap: onPeriodTap,
              onShowStats: () => onShowStats(filteredGrades),
            ),
          const SizedBox(height: 8),
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  'empty'.i18n,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ...subjects.map((subject) {
              final avg = subjectAvgMap[subject] ?? 0.0;
              final nullAvg =
                  GroupAverage(average: 0.0, subject: subject, uid: '0');
              final groupAvg = gradeProvider.groupAverages
                  .firstWhere((ga) => ga.subject == subject,
                      orElse: () => nullAvg)
                  .average;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: settings.shadowEffect
                        ? [
                            BoxShadow(
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                              color: Theme.of(context).shadowColor,
                            )
                          ]
                        : null,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: GradeSubjectTile(
                      subject,
                      average: avg,
                      groupAverage: periodDays == 0 ? groupAvg : 0.0,
                      onTap: () {
                        performHapticFeedback(settings.vibrate);
                        onSubjectTap(subject, groupAvg);
                      },
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Hero card ───────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.currentAvg,
    required this.prevAvg,
    required this.totalClassAvg,
    required this.subjectAvg,
    required this.currentPeriodKey,
    required this.onPeriodTap,
    required this.onShowStats,
  });

  final double currentAvg, prevAvg, totalClassAvg, subjectAvg;
  final String currentPeriodKey;
  final VoidCallback onPeriodTap;
  final VoidCallback onShowStats;

  @override
  Widget build(BuildContext context) {
    final onColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main row: avg + badges ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Label + avg
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'page_title_grades'.i18n,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      currentAvg.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: onColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Right side: TrendDisplay + badges
                if (prevAvg > 0 && currentAvg != prevAvg) ...[
                  TrendDisplay(previous: prevAvg, current: currentAvg),
                  const SizedBox(width: 4),
                ],
                if (subjectAvg > 0) ...[
                  _Badge(
                      icon: Icons.menu_book_rounded,
                      value: subjectAvg,
                      onColor: onColor),
                  const SizedBox(width: 8),
                ],
                if (totalClassAvg >= 1.0)
                  _Badge(
                      icon: Icons.group_rounded,
                      value: totalClassAvg,
                      onColor: onColor),
              ],
            ),
            const SizedBox(height: 14),
            // ── Bottom row: period chip + stats ──
            Row(
              children: [
                GestureDetector(
                  onTap: onPeriodTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: onColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 14, color: onColor.withValues(alpha: 0.75)),
                        const SizedBox(width: 5),
                        Text(
                          currentPeriodKey.i18n,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: onColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onShowStats,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: onColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 15, color: onColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 5),
                        Text(
                          'stats'.i18n,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: onColor.withValues(alpha: 0.8),
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
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.icon, required this.value, required this.onColor});
  final IconData icon;
  final double value;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: onColor.withValues(alpha: 0.55)),
          const SizedBox(height: 3),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: onColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Jegyek (subject detail) ──────────────────────────────────────────

class _SubjectGradesView extends StatelessWidget {
  const _SubjectGradesView({
    super.key,
    required this.subject,
    required this.groupAverage,
  });

  final GradeSubject subject;
  final double groupAverage;

  bool _canShowGraph(List<Grade> grades) {
    final mid = grades.where((g) => g.type == GradeType.midYear).toList();
    if (mid.length < 2) return false;
    final ms = mid.map((g) => g.date.millisecondsSinceEpoch);
    return ms.reduce(max) - ms.reduce(min) >=
        const Duration(days: 5).inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final gradeProvider = Provider.of<GradeProvider>(context);
    final calcProvider = Provider.of<GradeCalculatorProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final isCalcMode = calcProvider.ghosts.isNotEmpty;
    final raw = isCalcMode ? calcProvider.grades : gradeProvider.grades;
    final subjectGrades = raw.where((g) => g.subject == subject).toList()
      ..sort((a, b) => -a.date.compareTo(b.date));

    final midYear = subjectGrades
        .where((g) =>
            g.type == GradeType.midYear ||
            (isCalcMode && g.type == GradeType.ghost))
        .toList();
    final average = AverageHelper.averageEvals(midYear);

    final latestDate = subjectGrades.isNotEmpty
        ? subjectGrades
            .map((g) => g.date)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();
    final prevAvg = AverageHelper.averageEvals(midYear
        .where((g) =>
            g.date.isBefore(latestDate.subtract(const Duration(days: 30))))
        .toList());

    // Separate ghost grades from regular grades
    final ghostTiles = <Widget>[];
    final regularTiles = <Widget>[];
    for (final grade in subjectGrades) {
      if (grade.type == GradeType.ghost) {
        ghostTiles.add(GradeTile(grade, viewOverride: true));
      } else if (grade.type == GradeType.midYear) {
        regularTiles.add(GradeViewable(grade));
      } else {
        regularTiles.add(CertificationTile(
          grade,
          padding: EdgeInsets.only(
            bottom: 8,
            top: subjectGrades.first.id == grade.id ? 0 : 8,
          ),
          newStyle: true,
        ));
      }
    }

    return SubjectGradesContainer(
      child: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 72,
        ),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 8),

          // ── Header ──
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.renamedTo ?? subject.name.capital(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontStyle: settings.renamedSubjectsItalics &&
                                  subject.isRenamed
                              ? FontStyle.italic
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ((subject.teacher?.isRenamed ?? false) &&
                                    settings.renamedTeachersEnabled
                                ? subject.teacher?.renamedTo
                                : subject.teacher?.name.capital()) ??
                            '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (groupAverage > 0) ...[
                          AverageDisplay(average: groupAverage, border: true),
                          const SizedBox(width: 6),
                        ],
                        if (average > 0 &&
                            prevAvg > 0 &&
                            average != prevAvg) ...[
                          TrendDisplay(current: average, previous: prevAvg),
                          const SizedBox(width: 6),
                        ],
                        if (average > 0) AverageDisplay(average: average),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Graph ──
          if (_canShowGraph(subjectGrades)) ...[
            const SizedBox(height: 12),
            Panel(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 12, 4),
                child: GradeGraph(subjectGrades, classAvg: groupAverage),
              ),
            ),
          ],

          // ── Ghost grade tiles (above regular) ──
          if (ghostTiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Panel(
              child: Column(children: [
                const SizedBox(height: 4),
                ...ghostTiles,
                const SizedBox(height: 4),
              ]),
            ),
          ],

          // ── Regular grade tiles ──
          if (regularTiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Panel(
              child: Column(children: [
                const SizedBox(height: 4),
                ...regularTiles,
                const SizedBox(height: 4),
              ]),
            ),
          ],

          SizedBox(height: isCalcMode ? 269 : 0),
        ],
      ),
    );
  }
}
