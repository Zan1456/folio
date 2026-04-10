import 'package:i18n_extension/i18n_extension.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/models/exam.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_kreta_api/models/lesson.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_mobile_ui/common/panel/panel.dart';
import 'package:folio_mobile_ui/common/widgets/exam/exam_viewable.dart';
import 'package:folio_mobile_ui/common/widgets/homework/homework_viewable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'lesson_tile.i18n.dart';

class LessonTile extends StatelessWidget {
  const LessonTile(
    this.lesson, {
    super.key,
    this.onTap,
    this.swapDesc = false,
    this.subjectPageView = false,
    this.swapRoom = false,
    this.currentLessonIndicator = true,
    this.padding,
    this.contentPadding,
    this.showSubTiles = true,
  });

  final Lesson lesson;
  final bool swapDesc;
  final void Function()? onTap;
  final bool subjectPageView;
  final bool swapRoom;
  final bool currentLessonIndicator;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final bool showSubTiles;

  @override
  Widget build(BuildContext context) {
    List<Widget> subtiles = [];

    final colorScheme = Theme.of(context).colorScheme;
    SettingsProvider settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    String lessonIndexTrailing = "";
    if (RegExp(r'\d').hasMatch(lesson.lessonIndex)) lessonIndexTrailing = ".";

    final now = DateTime.now();
    final isCurrent = lesson.start.isBefore(now) &&
        lesson.end.isAfter(now) &&
        lesson.status?.name != "Elmaradt";
    final isCancelled = lesson.status?.name == "Elmaradt";
    final isSubstitute =
        lesson.substituteTeacher != null && lesson.substituteTeacher?.name != "";

    // Card background color
    Color cardColor;
    Color accentColor;
    Color onCardColor;
    if (isCancelled) {
      cardColor = colorScheme.errorContainer;
      accentColor = colorScheme.error;
      onCardColor = colorScheme.onErrorContainer;
    } else if (isSubstitute) {
      cardColor = AppColors.of(context).orange.withValues(alpha: 0.18);
      accentColor = AppColors.of(context).orange;
      onCardColor = Theme.of(context).colorScheme.onSurface;
    } else if (isCurrent) {
      cardColor = colorScheme.secondaryContainer;
      accentColor = colorScheme.secondary;
      onCardColor = colorScheme.onSecondaryContainer;
    } else if (lesson.isEmpty) {
      cardColor = colorScheme.surfaceContainerLow;
      accentColor = colorScheme.onSurface.withValues(alpha: 0.4);
      onCardColor = colorScheme.onSurface.withValues(alpha: 0.5);
    } else {
      cardColor = colorScheme.surfaceContainerHigh;
      accentColor = colorScheme.secondary;
      onCardColor = colorScheme.onSurface;
    }

    // Sidebar colors
    final sidebarIndexColor = isCurrent || isCancelled || isSubstitute
        ? accentColor
        : colorScheme.onSurface.withValues(alpha: 0.7);
    final sidebarTimeColor = colorScheme.onSurface.withValues(alpha: 0.45);

    if (!lesson.studentPresence) {
      subtiles.add(LessonSubtile(
        type: LessonSubtileType.absence,
        title: "absence".i18n,
        onCardColor: onCardColor,
      ));
    }

    if (lesson.homeworkId != "") {
      Homework homework = Provider.of<HomeworkProvider>(context, listen: false)
          .homework
          .firstWhere((h) => h.id == lesson.homeworkId,
              orElse: () => Homework.fromJson({}));
      if (homework.id != "") {
        subtiles.add(LessonSubtile(
          type: LessonSubtileType.homework,
          title: homework.content,
          onCardColor: onCardColor,
          onPressed: () => HomeworkPopup.show(homework: homework, context: context),
        ));
      }
    }

    if (lesson.exam != "") {
      Exam exam = Provider.of<ExamProvider>(context, listen: false)
          .exams
          .firstWhere((t) => t.id == lesson.exam,
              orElse: () => Exam.fromJson({}));
      if (exam.id != "") {
        subtiles.add(LessonSubtile(
          type: LessonSubtileType.exam,
          title: exam.description != ""
              ? exam.description
              : exam.mode?.description ?? "exam".i18n,
          onCardColor: onCardColor,
          onPressed: () => ExamPopup.show(context: context, exam: exam),
        ));
      }
    }

    final cleanDesc = lesson.description
        .replaceAll(lesson.subject.name.specialChars().toLowerCase(), '');

    // Subject page view: compact inline layout (date-based)
    if (subjectPageView) {
      return Padding(
        padding: padding ?? const EdgeInsets.only(bottom: 6.0),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(18.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: accentColor.withValues(alpha: 0.12),
            highlightColor: accentColor.withValues(alpha: 0.08),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16.0, 12.0, 16.0, (subtiles.isNotEmpty && showSubTiles) ? 8.0 : 14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${DateFormat("E, H:mm", I18n.of(context).locale.toString()).format(lesson.start)}-${DateFormat("H:mm").format(lesson.end)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                            color: onCardColor,
                          ),
                        ),
                      ),
                      if (!lesson.isEmpty && lesson.room.isNotEmpty) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 100.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            lesson.room.replaceAll("_", " "),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              height: 1.2,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isCurrent || isCancelled || isSubstitute
                                  ? accentColor
                                  : colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (showSubTiles && subtiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(children: subtiles),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Timetable view: sidebar (index + times) + card
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 6.0),
      child: Visibility(
        visible: lesson.subject.id != '' || lesson.isEmpty,
        replacement: Padding(
          padding: const EdgeInsets.only(top: 6.0, left: 4.0),
          child: PanelTitle(title: Text(lesson.name)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left sidebar: index + times ──────────────────────────────
            SizedBox(
              width: 44.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    lesson.lessonIndex + lessonIndexTrailing,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: sidebarIndexColor,
                    ),
                  ),
                  if (!lesson.isEmpty) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      DateFormat("H:mm").format(lesson.start),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: sidebarTimeColor,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      DateFormat("H:mm").format(lesson.end),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: sidebarTimeColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6.0),
            // ── Card ──────────────────────────────────────────────────────
            Expanded(
              child: Material(
                color: cardColor,
                borderRadius: BorderRadius.circular(18.0),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  splashColor: accentColor.withValues(alpha: 0.12),
                  highlightColor: accentColor.withValues(alpha: 0.08),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        14.0, 12.0, 14.0, (subtiles.isNotEmpty && showSubTiles) ? 8.0 : 13.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject name + room badge on the same row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                !lesson.isEmpty
                                    ? lesson.subject.renamedTo ??
                                        lesson.subject.name.capital()
                                    : "empty".i18n,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.0,
                                  color: onCardColor,
                                  fontStyle: lesson.subject.isRenamed &&
                                          settingsProvider.renamedSubjectsItalics
                                      ? FontStyle.italic
                                      : null,
                                ),
                              ),
                            ),
                            if (!lesson.isEmpty && lesson.room.isNotEmpty) ...[
                              const SizedBox(width: 8.0),
                              Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 100.0),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 3.0),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  lesson.room.replaceAll("_", " "),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    height: 1.2,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent || isCancelled || isSubstitute
                                        ? accentColor
                                        : colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Description (if any)
                        if (!lesson.isEmpty && cleanDesc.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              cleanDesc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.0,
                                color: onCardColor.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        // Subtiles
                        if (showSubTiles && subtiles.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(children: subtiles),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum LessonSubtileType { homework, exam, absence }

class LessonSubtile extends StatelessWidget {
  const LessonSubtile({
    super.key,
    this.onPressed,
    required this.title,
    required this.type,
    required this.onCardColor,
  });

  final Function()? onPressed;
  final String title;
  final LessonSubtileType type;
  final Color onCardColor;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor = onCardColor.withValues(alpha: 0.7);

    switch (type) {
      case LessonSubtileType.absence:
        icon = Icons.block_rounded;
        iconColor = AppColors.of(context).red;
        break;
      case LessonSubtileType.exam:
        icon = Icons.insert_drive_file_rounded;
        break;
      case LessonSubtileType.homework:
        icon = Icons.home_rounded;
        break;
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 5.0, 0, 2.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 16.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                title.escapeHtml(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: onCardColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
