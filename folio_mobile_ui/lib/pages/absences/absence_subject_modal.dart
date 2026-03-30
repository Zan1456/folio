// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/colors/utils.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/absence.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_mobile_ui/common/widgets/absence/absence_tile.dart';
import 'package:folio_mobile_ui/common/widgets/absence/absence_viewable.dart';
import 'absence_subject_modal.i18n.dart';

class AbsenceSubjectModal extends StatelessWidget {
  const AbsenceSubjectModal({
    super.key,
    required this.subject,
    required this.absences,
    required this.outsideContext,
  });

  final GradeSubject subject;
  final List<Absence> absences;
  final BuildContext outsideContext;

  static void show({
    required BuildContext context,
    required GradeSubject subject,
    required List<Absence> absences,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0x00000000),
      elevation: 0,
      isDismissible: true,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => AbsenceSubjectModal(
        subject: subject,
        absences: absences,
        outsideContext: context,
      ),
    );
  }

  String _stateLabel(Justification state) {
    switch (state) {
      case Justification.excused:
        return "excused_state".i18n;
      case Justification.pending:
        return "pending_state".i18n;
      case Justification.unexcused:
        return "unexcused_state".i18n;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final subjectName = subject.isRenamed && settings.renamedSubjectsEnabled
        ? subject.renamedTo ?? subject.name.capital()
        : subject.name.capital();

    // Sort newest first then group by day
    final sorted = [...absences]..sort((a, b) => b.date.compareTo(a.date));
    final Map<String, List<Absence>> grouped = {};
    for (final absence in sorted) {
      final key = DateFormat('yyyy-MM-dd').format(absence.date);
      grouped.putIfAbsent(key, () => []).add(absence);
    }
    // Sort within each day by lesson index ascending
    for (final list in grouped.values) {
      list.sort((a, b) => (a.lessonIndex ?? 0).compareTo(b.lessonIndex ?? 0));
    }
    final dayGroups = grouped.entries.toList();

    final handleColor = ColorsUtils()
        .fade(context, Theme.of(context).colorScheme.secondary,
            darkenAmount: 0.1, lightenAmount: 0.1)
        .withValues(alpha: 0.33);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      child: Stack(
        children: [
          // SVG background (same as AbsencePopup)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                SvgPicture.asset(
                  SubjectBooklet.resolveVariant(
                      context: context, subject: subject),
                  // ignore: deprecated_member_use
                  color: ColorsUtils()
                      .fade(context, Theme.of(context).colorScheme.secondary,
                          darkenAmount: 0.1, lightenAmount: 0.1)
                      .withValues(alpha: 0.33),
                  width: MediaQuery.of(context).size.width,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12.0)),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.1),
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.3, 0.6, 0.95],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: 160.0,
                ),
              ],
            ),
          ),

          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: handleColor,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),

                const SizedBox(height: 22.0),

                // Subject name
                Text(
                  subjectName,
                  style: TextStyle(
                    color: AppColors.of(context).text,
                    fontSize: 22.0,
                    fontWeight: FontWeight.w700,
                    fontStyle:
                        subject.isRenamed && settings.renamedSubjectsItalics
                            ? FontStyle.italic
                            : null,
                  ),
                ),

                const SizedBox(height: 18.0),

                // Day groups
                ...dayGroups.asMap().entries.map((groupEntry) {
                  final groupIdx = groupEntry.key;
                  final dayAbsences = groupEntry.value.value;
                  final date = dayAbsences.first.date;

                  return Padding(
                    padding: EdgeInsets.only(top: groupIdx == 0 ? 0.0 : 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 6.0, left: 2.0),
                          child: Text(
                            date.format(context, weekday: true),
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.5),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Absence tiles with connected borders
                        ...dayAbsences.asMap().entries.map((e) {
                          final idx = e.key;
                          final absence = e.value;
                          final isFirst = idx == 0;
                          final isLast = idx == dayAbsences.length - 1;
                          final topRadius = isFirst ? 12.0 : 3.0;
                          final bottomRadius = isLast ? 12.0 : 3.0;

                          final justColor = AbsenceTile.justificationColor(
                              absence.state,
                              context: context);
                          final justIcon =
                              AbsenceTile.justificationIcon(absence.state);
                          final stateLabel = _stateLabel(absence.state);

                          return Padding(
                            padding:
                                EdgeInsets.only(top: isFirst ? 0.0 : 2.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => AbsencePopup.show(
                                context: outsideContext,
                                absence: absence,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(topRadius),
                                    bottom: Radius.circular(bottomRadius),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    // State icon
                                    Container(
                                      width: 36.0,
                                      height: 36.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: justColor.withValues(alpha: 0.18),
                                      ),
                                      child: Center(
                                        child: Icon(justIcon,
                                            color: justColor, size: 19.0),
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),

                                    // Lesson info
                                    Expanded(
                                      child: absence.lessonIndex != null
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${absence.lessonIndex}. ${"lesson".i18n}",
                                                  style: TextStyle(
                                                    color: AppColors.of(context)
                                                        .text,
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  "${absence.lessonStart.format(context, timeOnly: true)} – ${absence.lessonEnd.format(context, timeOnly: true)}",
                                                  style: TextStyle(
                                                    color: AppColors.of(context)
                                                        .text
                                                        .withValues(alpha: 0.55),
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              stateLabel,
                                              style: TextStyle(
                                                color:
                                                    AppColors.of(context).text,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),

                                    const SizedBox(width: 8.0),

                                    // State badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0, vertical: 4.0),
                                      decoration: BoxDecoration(
                                        color:
                                            justColor.withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Text(
                                        stateLabel,
                                        style: TextStyle(
                                          color: justColor,
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),

                SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 18.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
