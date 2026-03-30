import 'package:flutter/material.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';
import 'missed_exam_tile.i18n.dart';

class MissedExamTile extends StatelessWidget {
  const MissedExamTile(this.missedExams, {super.key, this.onTap, this.padding});

  final List<Lesson> missedExams;
  final Function()? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
      child: PanelButton(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
        leading: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              Icons.block_rounded,
              color: AppColors.of(context).red.withValues(alpha: .75),
              size: 28.0,
            )),
        title: Text("missed_exams"
            .plural(missedExams.length)
            .fill([missedExams.length])),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onPressed: onTap,
      ),
    );
  }
}
