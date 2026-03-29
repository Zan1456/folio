import 'package:refilc/helpers/subject.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc/theme/colors/colors.dart';
import 'package:refilc/utils/format.dart';
import 'package:refilc_kreta_api/models/subject.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AbsenceSubjectTile extends StatelessWidget {
  const AbsenceSubjectTile(
    this.subject, {
    super.key,
    this.percentage = 0.0,
    this.excused = 0,
    this.unexcused = 0,
    this.pending = 0,
    this.onTap,
  });

  final GradeSubject subject;
  final void Function()? onTap;
  final double percentage;
  final int excused;
  final int unexcused;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    Color cardColor;
    Color onCardColor;
    if (unexcused > 0 && percentage > 35) {
      cardColor = colorScheme.errorContainer;
      onCardColor = colorScheme.onErrorContainer;
    } else if (unexcused > 0 && percentage > 25) {
      cardColor = colorScheme.tertiaryContainer;
      onCardColor = colorScheme.onTertiaryContainer;
    } else {
      cardColor = colorScheme.surfaceContainerHigh;
      onCardColor = colorScheme.onSurface;
    }

    final pctColor = getColorByPercentage(percentage, context: context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.0),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: onCardColor.withValues(alpha: 0.08),
          highlightColor: onCardColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 12.0),
            child: Row(
              children: [
                // Subject icon
                Container(
                  padding: const EdgeInsets.all(9.0),
                  decoration: BoxDecoration(
                    color: onCardColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    SubjectIcon.resolveVariant(
                        subject: subject, context: context),
                    size: 20.0,
                    color: onCardColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(width: 12.0),
                // Subject name + absence badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.renamedTo ?? subject.name.capital(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.0,
                          color: onCardColor,
                          fontStyle: subject.isRenamed &&
                                  settingsProvider.renamedSubjectsItalics
                              ? FontStyle.italic
                              : null,
                        ),
                      ),
                      if (excused > 0 || pending > 0 || unexcused > 0) ...[
                        const SizedBox(height: 5.0),
                        Row(
                          children: [
                            if (excused > 0) ...[
                              _AbsenceBadge(
                                count: excused,
                                color: AppColors.of(context).green,
                              ),
                              const SizedBox(width: 5.0),
                            ],
                            if (pending > 0) ...[
                              _AbsenceBadge(
                                count: pending,
                                color: AppColors.of(context).orange,
                              ),
                              const SizedBox(width: 5.0),
                            ],
                            if (unexcused > 0)
                              _AbsenceBadge(
                                count: unexcused,
                                color: AppColors.of(context).red,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                // Percentage
                if (percentage >= 0)
                  Text(
                    "${percentage.round()}%",
                    style: TextStyle(
                      color: pctColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AbsenceBadge extends StatelessWidget {
  const _AbsenceBadge({required this.count, required this.color});
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

Color getColorByPercentage(double percentage,
    {required BuildContext context}) {
  Color color = AppColors.of(context).text;
  percentage = percentage.round().toDouble();
  if (percentage > 35) {
    color = AppColors.of(context).red;
  } else if (percentage > 25) {
    color = AppColors.of(context).orange;
  } else if (percentage > 15) {
    color = AppColors.of(context).yellow;
  }
  return color.withValues(alpha: .8);
}
