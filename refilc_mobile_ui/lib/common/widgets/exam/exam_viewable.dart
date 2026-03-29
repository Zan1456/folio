// ignore_for_file: use_build_context_synchronously

import 'package:flutter_svg/svg.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:refilc/helpers/subject.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc/theme/colors/colors.dart';
import 'package:refilc/theme/colors/utils.dart';
import 'package:refilc/utils/format.dart';
import 'package:refilc_kreta_api/models/exam.dart';
import 'package:refilc_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:refilc_mobile_ui/common/round_border_icon.dart';
import 'package:refilc_mobile_ui/common/widgets/exam/exam_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exam_view.i18n.dart';

class ExamViewable extends StatelessWidget {
  const ExamViewable(this.exam,
      {super.key, this.showSubject = true, this.tilePadding});

  final Exam exam;
  final bool showSubject;
  final EdgeInsetsGeometry? tilePadding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ExamPopup.show(context: context, exam: exam);
      },
      child: ExamTile(
        exam,
        showSubject: showSubject,
        padding: tilePadding,
      ),
    );
  }
}

class ExamPopup extends StatelessWidget {
  const ExamPopup({
    super.key,
    required this.exam,
    required this.outsideContext,
  });

  final Exam exam;
  final BuildContext outsideContext;

  static bool _isShowing = false;

  static void show({
    required BuildContext context,
    required Exam exam,
  }) {
    if (_isShowing) return;
    _isShowing = true;
    showRoundedModalBottomSheet(
      context,
      child: ExamPopup(
        exam: exam,
        outsideContext: context,
      ),
      showHandle: false,
    ).then((_) => _isShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12.0),
        ),
      ),
      child: Stack(
        children: [
          Stack(
            children: [
              SvgPicture.asset(
                SubjectBooklet.resolveVariant(
                    context: context, subject: exam.subject),
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
                    stops: const [0.1, 0.5, 0.7, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                height: 175.0,
              ),
            ],
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                                context,
                                Theme.of(context).colorScheme.secondary,
                                darkenAmount: 0.1,
                                lightenAmount: 0.1)
                            .withValues(alpha: 0.33),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                    const SizedBox(height: 38.0),
                    // Subject icon
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: RoundBorderIcon(
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
                              context: context, subject: exam.subject),
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
                    const SizedBox(height: 20.0),
                    // Subject name + date header card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(6.0),
                        ),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date badge
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
                                  .format(exam.writeDate)
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
                          const SizedBox(height: 10.0),
                          // Subject name
                          Text(
                            Provider.of<SettingsProvider>(context,
                                        listen: false)
                                    .renamedSubjectsEnabled
                                ? (exam.subject.renamedTo ??
                                    exam.subject.name.capital())
                                : exam.subject.name.capital(),
                            style: TextStyle(
                              color: AppColors.of(context).text,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w700,
                              fontStyle: exam.subject.isRenamed &&
                                      Provider.of<SettingsProvider>(context,
                                              listen: false)
                                          .renamedSubjectsItalics
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                          if (exam.teacher.name.isNotEmpty) ...[
                            const SizedBox(height: 6.0),
                            Text(
                              exam.teacher.name,
                              style: TextStyle(
                                color: AppColors.of(context)
                                    .text
                                    .withValues(alpha: 0.7),
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Mode card
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(6.0),
                          bottom: Radius.circular(
                              exam.description.isNotEmpty ? 6.0 : 12.0),
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
                            (exam.mode?.description ?? 'Ismeretlen').capital(),
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
                    // Description card (if present)
                    if (exam.description.isNotEmpty) ...[
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
                              exam.description.capital(),
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
                    // Announced date card
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
                            DateFormat('yyyy. MMM d.', I18n.locale.countryCode)
                                .format(exam.date)
                                .capital(),
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
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 8.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
