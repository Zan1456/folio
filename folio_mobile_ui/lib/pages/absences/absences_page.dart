// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:math';

import 'package:folio/api/providers/update_provider.dart';
import 'package:folio/ui/date_widget.dart';
import 'package:folio_kreta_api/models/absence.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_mobile_ui/common/action_button.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/widgets/absence/absence_subject_tile.dart';
import 'package:folio_mobile_ui/common/widgets/absence/absence_viewable.dart';
import 'package:folio_mobile_ui/common/widgets/miss_tile.dart';
import 'package:folio_mobile_ui/pages/absences/absence_subject_modal.dart';
import 'package:folio/ui/filter/sort.dart';
import 'package:flutter/material.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_mobile_ui/common/haptic.dart';
import 'package:provider/provider.dart';
import 'absences_page.i18n.dart';

enum AbsenceFilter { absences, delays, misses }

class SubjectAbsence {
  GradeSubject subject;
  List<Absence> absences;
  double percentage;

  SubjectAbsence(
      {required this.subject, this.absences = const [], this.percentage = 0.0});
}

class AbsencesPage extends StatefulWidget {
  const AbsencesPage({super.key});

  @override
  AbsencesPageState createState() => AbsencesPageState();
}

class AbsencesPageState extends State<AbsencesPage>
    with TickerProviderStateMixin {
  late UserProvider user;
  late AbsenceProvider absenceProvider;
  late TimetableProvider timetableProvider;
  late NoteProvider noteProvider;
  late UpdateProvider updateProvider;
  late String firstName;
  late TabController _tabController;
  late List<SubjectAbsence> absences = [];
  final Map<GradeSubject, Lesson> _lessonCount = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    timetableProvider = Provider.of<TimetableProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      for (final lesson in timetableProvider.getWeek(Week.current()) ?? []) {
        if (!lesson.isEmpty &&
            lesson.subject.id != '' &&
            lesson.lessonYearIndex != null) {
          _lessonCount.update(
            lesson.subject,
            (value) {
              if (lesson.lessonYearIndex! > value.lessonYearIndex!) {
                return lesson;
              } else {
                return value;
              }
            },
            ifAbsent: () => lesson,
          );
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSubjectAbsencesModal(GradeSubject subject, List<Absence> absences) {
    AbsenceSubjectModal.show(
      context: context,
      subject: subject,
      absences: absences,
    );
  }

  void _showJustificationBreakdown(BuildContext context, List<Absence> excused) {
    final Map<String, int> typeCounts = {};
    for (final absence in excused) {
      final name = absence.justification?.name;
      final key = (name != null && name.isNotEmpty) ? name : "justification_unknown".i18n;
      typeCounts[key] = (typeCounts[key] ?? 0) + 1;
    }

    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20.0, 20.0, 20.0, MediaQuery.of(context).padding.bottom + 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "justification_breakdown_title".i18n,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12.0),
              ...typeCounts.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: AppColors.of(context).green.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        "${e.value}",
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.of(context).green,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void buildSubjectAbsences() {
    Map<GradeSubject, SubjectAbsence> _absences = {};

    for (final absence in absenceProvider.absences) {
      if (absence.delay != 0) continue;

      if (!_absences.containsKey(absence.subject)) {
        _absences[absence.subject] =
            SubjectAbsence(subject: absence.subject, absences: [absence]);
      } else {
        _absences[absence.subject]?.absences.add(absence);
      }
    }

    _absences.forEach((subject, absence) {
      final absentLessonsOfSubject = absenceProvider.absences
          .where((e) => e.subject == subject && e.delay == 0)
          .length;
      final totalLessonsOfSubject = _lessonCount[subject]?.lessonYearIndex ?? 0;

      double absentLessonsOfSubjectPercentage;

      if (absentLessonsOfSubject <= totalLessonsOfSubject) {
        absentLessonsOfSubjectPercentage =
            absentLessonsOfSubject / totalLessonsOfSubject * 100;
      } else {
        absentLessonsOfSubjectPercentage = -1;
      }

      _absences[subject]?.percentage =
          absentLessonsOfSubjectPercentage.clamp(-1, 100.0);
    });

    absences = _absences.values.toList();
    absences.sort((a, b) => -a.percentage.compareTo(b.percentage));
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    absenceProvider = Provider.of<AbsenceProvider>(context);
    noteProvider = Provider.of<NoteProvider>(context);
    updateProvider = Provider.of<UpdateProvider>(context);
    timetableProvider = Provider.of<TimetableProvider>(context);

    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];

    buildSubjectAbsences();

    return Scaffold(
      body: Column(
        children: [
          // ─── Accent Header ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28.0)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 8.0, 0.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            "Absences".i18n,
                            style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                                title: Text("attention".i18n),
                                content: Text("attention_body".i18n),
                                actions: [
                                  ActionButton(
                                    label: "Ok",
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.info_outline_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab bar
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) => TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      labelColor: Theme.of(context).colorScheme.secondary,
                      unselectedLabelColor: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.65),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
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
                      overlayColor: WidgetStateProperty.all(
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.08),
                      ),
                      onTap: (_) => performHapticFeedback(
                          Provider.of<SettingsProvider>(context, listen: false).vibrate),
                      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 14.0),
                      tabs: [
                        Tab(text: "Absences".i18n),
                        Tab(text: "Delays".i18n),
                        Tab(text: "Misses".i18n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ─── Content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              controller: _tabController,
              children: List.generate(
                  3, (index) => filterViewBuilder(context, index)),
            ),
          ),
        ],
      ),
    );
  }

  List<DateWidget> getFilterWidgets(AbsenceFilter activeData) {
    List<DateWidget> items = [];
    switch (activeData) {
      case AbsenceFilter.absences:
        for (var a in absences) {
          items.add(DateWidget(
            date: DateTime.fromMillisecondsSinceEpoch(0),
            widget: AbsenceSubjectTile(
              a.subject,
              percentage: a.percentage,
              excused: a.absences
                  .where((a) => a.state == Justification.excused)
                  .length,
              unexcused: a.absences
                  .where((a) => a.state == Justification.unexcused)
                  .length,
              pending: a.absences
                  .where((a) => a.state == Justification.pending)
                  .length,
              onTap: () => _showSubjectAbsencesModal(a.subject, a.absences),
            ),
          ));
        }
        break;
      case AbsenceFilter.delays:
        for (var absence in absenceProvider.absences) {
          if (absence.delay != 0) {
            items.add(DateWidget(
              date: absence.date,
              widget: AbsenceViewable(absence, padding: EdgeInsets.zero),
            ));
          }
        }
        break;
      case AbsenceFilter.misses:
        for (var note in noteProvider.notes) {
          if (note.type?.name == "HaziFeladatHiany" ||
              note.type?.name == "Felszereleshiany") {
            items.add(DateWidget(
              date: note.date,
              widget: MissTile(note),
            ));
          }
        }
        break;
    }
    return items;
  }

  Widget filterViewBuilder(BuildContext context, int activeData) {
    final colorScheme = Theme.of(context).colorScheme;

    // Collect counts for stats header
    List<Absence> excused = [];
    List<Absence> unexcused = [];
    List<Absence> pending = [];
    String suffix = "";
    String excusedLabel = "";
    String unexcusedLabel = "";
    String pendingLabel = "";

    if (activeData == AbsenceFilter.absences.index) {
      excused = absenceProvider.absences
          .where((e) => e.delay == 0 && e.state == Justification.excused)
          .toList();
      unexcused = absenceProvider.absences
          .where((e) => e.delay == 0 && e.state == Justification.unexcused)
          .toList();
      pending = absenceProvider.absences
          .where((e) => e.delay == 0 && e.state == Justification.pending)
          .toList();
      suffix = " ${"hr".i18n}";
      excusedLabel = "stat_1".i18n;
      unexcusedLabel = "stat_2".i18n;
      pendingLabel = "pending".i18n;
    } else if (activeData == AbsenceFilter.delays.index) {
      excused = absenceProvider.absences
          .where((e) => e.delay != 0 && e.state == Justification.excused)
          .toList();
      unexcused = absenceProvider.absences
          .where((e) => e.delay != 0 && e.state == Justification.unexcused)
          .toList();
      pending = absenceProvider.absences
          .where((e) => e.delay != 0 && e.state == Justification.pending)
          .toList();
      suffix = " ${"min".i18n}";
      excusedLabel = "stat_3".i18n;
      unexcusedLabel = "stat_4".i18n;
      pendingLabel = "pending".i18n;
    }

    final int excusedVal = activeData == AbsenceFilter.delays.index
        ? excused.map((e) => e.delay).fold(0, (a, b) => a + b)
        : excused.length;
    final int unexcusedVal = activeData == AbsenceFilter.delays.index
        ? unexcused.map((e) => e.delay).fold(0, (a, b) => a + b)
        : unexcused.length;
    final int pendingVal = activeData == AbsenceFilter.delays.index
        ? pending.map((e) => e.delay).fold(0, (a, b) => a + b)
        : pending.length;

    final filterDateWidgets =
        getFilterWidgets(AbsenceFilter.values[activeData]);

    List<Widget> listItems;
    if (activeData == AbsenceFilter.absences.index) {
      listItems =
          filterDateWidgets.map((e) => e.widget).cast<Widget>().toList();
    } else {
      listItems = sortDateWidgets(
        context,
        dateWidgets: filterDateWidgets,
        padding: EdgeInsets.zero,
        hasShadow: true,
      );
    }

    return RefreshIndicator(
      color: colorScheme.secondary,
      onRefresh: () async {
        await absenceProvider.fetch();
        await noteProvider.fetch();
      },
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            16.0, 12.0, 16.0, MediaQuery.of(context).padding.bottom + 8.0),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemCount: max(
            listItems.length +
                (activeData < AbsenceFilter.misses.index ? 1 : 0),
            1),
        itemBuilder: (context, index) {
          // Stats card at the top for absences and delays tabs
          if (index == 0 && activeData < AbsenceFilter.misses.index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  _StatCard(
                    value: excusedVal,
                    suffix: suffix,
                    label: excusedLabel,
                    color: AppColors.of(context).green,
                    cardColor: colorScheme.surfaceContainerHigh,
                    onCardColor: colorScheme.onSurface,
                    onTap: excused.isNotEmpty
                        ? () => _showJustificationBreakdown(context, excused)
                        : null,
                  ),
                  const SizedBox(width: 8.0),
                  _StatCard(
                    value: unexcusedVal,
                    suffix: suffix,
                    label: unexcusedLabel,
                    color: AppColors.of(context).red,
                    cardColor: colorScheme.surfaceContainerHigh,
                    onCardColor: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8.0),
                  _StatCard(
                    value: pendingVal,
                    suffix: suffix,
                    label: pendingLabel,
                    color: AppColors.of(context).orange,
                    cardColor: colorScheme.surfaceContainerHigh,
                    onCardColor: colorScheme.onSurface,
                  ),
                ],
              ),
            );
          }

          final itemIndex =
              index - (activeData < AbsenceFilter.misses.index ? 1 : 0);

          if (listItems.isEmpty) {
            return activeData == AbsenceFilter.delays.index
                ? Empty(subtitle: "emptyDelays".i18n)
                : activeData == AbsenceFilter.misses.index
                    ? Empty(subtitle: "emptyMisses".i18n)
                    : Empty(subtitle: "empty".i18n);
          }

          return listItems[itemIndex];
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.suffix,
    required this.label,
    required this.color,
    required this.cardColor,
    required this.onCardColor,
    this.onTap,
  });

  final int value;
  final String suffix;
  final String label;
  final Color color;
  final Color cardColor;
  final Color onCardColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: value > 0 ? color.withValues(alpha: 0.14) : cardColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$value$suffix",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
                color: value > 0 ? color : onCardColor,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: value > 0
                    ? color.withValues(alpha: 0.8)
                    : onCardColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
