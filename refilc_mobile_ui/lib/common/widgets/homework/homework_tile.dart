import 'package:refilc/helpers/subject.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc/theme/colors/colors.dart';
import 'package:refilc_kreta_api/models/homework.dart';
import 'package:refilc/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refilc_mobile_ui/common/round_border_icon.dart';

class HomeworkTile extends StatelessWidget {
  const HomeworkTile(
    this.homework, {
    super.key,
    this.onTap,
    this.padding,
    this.censored = false,
  });

  final Homework homework;
  final void Function()? onTap;
  final EdgeInsetsGeometry? padding;
  final bool censored;

  @override
  Widget build(BuildContext context) {
    SettingsProvider settingsProvider = Provider.of<SettingsProvider>(context);

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.only(left: 8.0, right: 10.0),
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          leading: censored
              ? Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).text.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(60.0),
                  ),
                )
              : RoundBorderIcon(
                  icon: const Icon(
                    Icons.home_rounded,
                    size: 22.0,
                  ),
                  padding: 6.0,
                  width: 1.0,
                ),
          title: censored
              ? Wrap(
                  children: [
                    Container(
                      width: 160,
                      height: 15,
                      decoration: BoxDecoration(
                        color:
                            AppColors.of(context).text.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                )
              : Text(
                  homework.content.escapeHtml().replaceAll('\n', ' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
          subtitle: censored
              ? Wrap(
                  children: [
                    Container(
                      width: 100,
                      height: 10,
                      decoration: BoxDecoration(
                        color:
                            AppColors.of(context).text.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                )
              : Text(
                  homework.subject.renamedTo ?? homework.subject.name.capital(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.0,
                      fontStyle: homework.subject.isRenamed &&
                              settingsProvider.renamedSubjectsItalics
                          ? FontStyle.italic
                          : null),
                ),
          trailing: censored
              ? Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).text.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )
              : Icon(
                  SubjectIcon.resolveVariant(
                      context: context, subject: homework.subject),
                  color: AppColors.of(context).text.withValues(alpha: .5),
                ),
          minLeadingWidth: 0,
        ),
      ),
    );
  }
}
