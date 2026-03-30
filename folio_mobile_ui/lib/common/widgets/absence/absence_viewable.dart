// ignore_for_file: use_build_context_synchronously

import 'package:flutter_svg/svg.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/colors/utils.dart';
import 'package:folio/utils/format.dart';
import 'package:folio/utils/reverse_search.dart';
import 'package:folio_kreta_api/models/absence.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/custom_snack_bar.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';
import 'package:folio_mobile_ui/common/widgets/absence/absence_tile.dart';
import 'package:folio_mobile_ui/common/widgets/absence_group/absence_group_container.dart';
import 'package:folio_mobile_ui/pages/timetable/timetable_page.dart';
import 'package:flutter/material.dart';

import 'absence_view.i18n.dart';

class AbsenceViewable extends StatelessWidget {
  const AbsenceViewable(this.absence, {super.key, this.padding});

  final Absence absence;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final group = AbsenceGroupContainer.of(context) != null;
    final tile = AbsenceTile(absence, padding: padding);

    return GestureDetector(
      onTap: () => AbsencePopup.show(context: context, absence: absence),
      child: group ? AbsenceGroupContainer(child: tile) : tile,
    );
  }
}

class AbsencePopup extends StatelessWidget {
  const AbsencePopup({
    super.key,
    required this.absence,
    required this.outsideContext,
  });

  final Absence absence;
  final BuildContext outsideContext;

  static void show({
    required BuildContext context,
    required Absence absence,
  }) =>
      showRoundedModalBottomSheet(
        context,
        child: AbsencePopup(
          absence: absence,
          outsideContext: context,
        ),
        showHandle: false,
      );

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final subjectName =
        absence.subject.isRenamed && settings.renamedSubjectsEnabled
            ? absence.subject.renamedTo ?? absence.subject.name.capital()
            : absence.subject.name.capital();

    final teacherName = (absence.teacher.isRenamed
            ? absence.teacher.renamedTo
            : absence.teacher.name) ??
        '';

    final justColor =
        AbsenceTile.justificationColor(absence.state, context: context);
    final justIcon = AbsenceTile.justificationIcon(absence.state);

    final hasDelay = absence.delay > 0;
    final hasLesson = absence.lessonIndex != null;
    final hasJustification = absence.justification != null;
    final hasMode = absence.mode != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12.0),
        ),
      ),
      child: Stack(
        children: [
          // Background SVG + gradient
          Stack(
            children: [
              SvgPicture.asset(
                SubjectBooklet.resolveVariant(
                    context: context, subject: absence.subject),
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
                    top: Radius.circular(12.0),
                  ),
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
                height: 200.0,
              ),
            ],
          ),

          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ColorsUtils()
                          .fade(
                              context, Theme.of(context).colorScheme.secondary,
                              darkenAmount: 0.1, lightenAmount: 0.1)
                          .withValues(alpha: 0.33),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),

                  const SizedBox(height: 38.0),

                  // Justification state icon
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    child: RoundBorderIcon(
                      color: justColor.withValues(alpha: 0.9),
                      width: 1.5,
                      padding: 10.0,
                      icon: Icon(
                        justIcon,
                        size: 32.0,
                        color: justColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 55.0),

                  // Header card: subject, teacher, date + optional delay badge
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(12.0),
                        bottom: Radius.circular(
                            (hasLesson || hasJustification || hasMode)
                                ? 6.0
                                : 12.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.5, vertical: 3.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                DateFormat('MMM d', I18n.locale.countryCode)
                                    .format(absence.date)
                                    .capital(),
                                style: TextStyle(
                                  height: 1.1,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: .9),
                                ),
                              ),
                            ),
                            if (hasDelay) ...[
                              const SizedBox(width: 6.0),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5.5, vertical: 3.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Text(
                                  "${absence.delay} ${"minutes".i18n}",
                                  style: TextStyle(
                                    height: 1.1,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: .9),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          subjectName,
                          style: TextStyle(
                            color: AppColors.of(context).text,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            fontStyle: absence.subject.isRenamed &&
                                    settings.renamedSubjectsItalics
                                ? FontStyle.italic
                                : null,
                          ),
                        ),
                        if (teacherName.isNotEmpty) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            teacherName,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.9),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Lesson time card
                  if (hasLesson) ...[
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(6.0),
                          bottom: Radius.circular(
                              (hasJustification || hasMode) ? 6.0 : 12.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lesson".i18n,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.6),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            "${absence.lessonIndex}. (${absence.lessonStart.format(context, timeOnly: true)}"
                            " - "
                            "${absence.lessonEnd.format(context, timeOnly: true)})",
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.9),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Justification card
                  if (hasJustification) ...[
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(6.0),
                          bottom: Radius.circular(hasMode ? 6.0 : 12.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Excuse".i18n,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.6),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            absence.justification?.description ?? "",
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.9),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mode card
                  if (hasMode) ...[
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Mode".i18n,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.6),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            absence.mode?.description ?? "",
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.9),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Show in timetable button
                  const SizedBox(height: 12.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      ReverseSearch.getLessonByAbsence(
                              absence, outsideContext)
                          .then((lesson) {
                        if (lesson != null) {
                          TimetablePage.jump(outsideContext, lesson: lesson);
                        } else {
                          ScaffoldMessenger.of(outsideContext)
                              .showSnackBar(CustomSnackBar(
                            content: Text("Cannot find lesson".i18n,
                                style:
                                    const TextStyle(color: Colors.white)),
                            backgroundColor:
                                AppColors.of(outsideContext).red,
                            context: outsideContext,
                          ));
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18.0,
                            color: AppColors.of(context)
                                .text
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            "show in timetable".i18n,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.9),
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 8.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
