import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:provider/provider.dart';
import 'package:refilc/helpers/subject.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc/theme/colors/colors.dart';
import 'package:refilc/theme/colors/utils.dart';
import 'package:refilc/utils/format.dart';
import 'package:refilc_kreta_api/models/grade.dart';
import 'package:refilc_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:refilc_mobile_ui/common/round_border_icon.dart';
import 'package:refilc/ui/widgets/grade/grade_tile.dart';
import 'package:refilc_mobile_ui/pages/grades/subject_grades_container.dart';
import 'grade_view.i18n.dart';

class GradeViewable extends StatelessWidget {
  const GradeViewable(this.grade, {super.key, this.padding});

  final Grade grade;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final subject = SubjectGradesContainer.of(context) != null;
    final tile = GradeTile(grade, padding: subject ? EdgeInsets.zero : padding);

    return GestureDetector(
      onTap: () => GradePopup.show(context: context, grade: grade),
      child: subject ? SubjectGradesContainer(child: tile) : tile,
    );
  }
}

class GradePopup extends StatelessWidget {
  const GradePopup({
    super.key,
    required this.grade,
    required this.outsideContext,
  });

  final Grade grade;
  final BuildContext outsideContext;

  static void show({
    required BuildContext context,
    required Grade grade,
  }) =>
      showRoundedModalBottomSheet(
        context,
        child: GradePopup(
          grade: grade,
          outsideContext: context,
        ),
        showHandle: false,
      );

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final subjectName = grade.subject.isRenamed && settings.renamedSubjectsEnabled
        ? grade.subject.renamedTo ?? grade.subject.name.capital()
        : grade.subject.name.capital();

    final teacherName = settings.presentationMode
        ? "Tanár"
        : (grade.teacher.isRenamed
                ? grade.teacher.renamedTo
                : grade.teacher.name) ??
            '';

    final hasDescription = grade.description.isNotEmpty;
    final hasMode = grade.mode.description.isNotEmpty;
    final hasWriteDate = grade.writeDate.year != 0;
    final weightText = grade.value.weight != 100 && grade.value.weight > 0
        ? " · ${grade.value.weight}%"
        : "";

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
                    context: context, subject: grade.subject),
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

                  // Grade value circle (large)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    child: grade.value.value > 0
                        ? GradeValueWidget(
                            grade.value,
                            size: 52.0,
                            fill: true,
                          )
                        : RoundBorderIcon(
                            color: ColorsUtils()
                                .darken(
                                  Theme.of(context).colorScheme.secondary,
                                  amount: 0.1,
                                )
                                .withValues(alpha: 0.9),
                            width: 1.5,
                            padding: 10.0,
                            icon: Icon(
                              SubjectIcon.resolveVariant(
                                  context: context, subject: grade.subject),
                              size: 32.0,
                              color: ColorsUtils()
                                  .darken(
                                    Theme.of(context).colorScheme.secondary,
                                    amount: 0.1,
                                  )
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                  ),

                  const SizedBox(height: 48.0),

                  // Header: subject + teacher + date
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(12.0),
                        bottom: Radius.circular(
                            (hasDescription || hasMode || hasWriteDate)
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
                                    .format(grade.date)
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
                            if (weightText.isNotEmpty) ...[
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
                                  "${grade.value.weight}%",
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
                            fontStyle: grade.subject.isRenamed &&
                                    settings.renamedSubjectsItalics
                                ? FontStyle.italic
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          "${grade.value.valueName}$weightText",
                          style: TextStyle(
                            color: AppColors.of(context)
                                .text
                                .withValues(alpha: 0.9),
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (teacherName.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            teacherName,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.7),
                              fontSize: 13.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Description
                  if (hasDescription) ...[
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(6.0),
                          bottom: Radius.circular(
                              (hasMode || hasWriteDate) ? 6.0 : 12.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "description".i18n,
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
                            grade.description,
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

                  // Mode
                  if (hasMode) ...[
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(6.0),
                          bottom:
                              Radius.circular(hasWriteDate ? 6.0 : 12.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "mode".i18n,
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
                            grade.mode.description,
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

                  // Write date
                  if (hasWriteDate) ...[
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
                            "date".i18n,
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
                            grade.writeDate.format(context),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
