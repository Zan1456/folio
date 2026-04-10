// ignore_for_file: unnecessary_null_comparison

import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/services.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_mobile_ui/common/progress_bar.dart';
import 'package:folio_mobile_ui/pages/home/live_card/heads_up_countdown.dart';
import 'package:folio_mobile_ui/pages/home/live_card/segmented_countdown.dart';
import 'package:folio_mobile_ui/screens/summary/summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:folio/utils/format.dart';
import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio_mobile_ui/pages/home/live_card/live_card_widget.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';
import 'live_card.i18n.dart';

class LiveCard extends StatefulWidget {
  const LiveCard({super.key});

  @override
  LiveCardStateA createState() => LiveCardStateA();
}

class LiveCardStateA extends State<LiveCard> {
  late void Function() listener;
  late UserProvider _userProvider;
  late LiveCardProvider liveCard;

  @override
  void initState() {
    super.initState();
    listener = () => setState(() {});
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    liveCard = Provider.of<LiveCardProvider>(context, listen: false);
    _userProvider.addListener(liveCard.update);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _userProvider.removeListener(liveCard.update);
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _labelRow(String label, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.of(context).text.withValues(alpha: 0.42),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: AppColors.of(context).text.withValues(alpha: 0.48),
            ),
          ),
      ],
    );
  }

  Widget _subjectRow(
    String name, {
    required IconData icon,
    required String room,
    bool italic = false,
  }) {
    return Row(
      children: [
        Container(
          width: 38.0,
          height: 38.0,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            icon,
            size: 19.0,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.w700,
              fontStyle: italic ? FontStyle.italic : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (room.isNotEmpty) ...[
          const SizedBox(width: 8.0),
          _roomPill(room),
        ],
      ],
    );
  }

  Widget _roomPill(String room, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.secondary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 88.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        room,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: c.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _progressRow({
    required DateTime start,
    required DateTime end,
    required Duration bellDelay,
    void Function(double maxTime, double elapsed)? onTap,
  }) {
    return _LiveCardProgress(
      start: start,
      end: end,
      bellDelay: bellDelay,
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.of(context).text.withValues(alpha: 0.08),
    );
  }

  Widget _nextRow(
    dynamic nextLesson, {
    bool italic = false,
    String Function()? subjectName,
  }) {
    if (nextLesson == null) {
      return Container(
        color: AppColors.of(context).text.withValues(alpha: 0.03),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
        child: Row(
          children: [
            Icon(
              Icons.home_outlined,
              size: 15.0,
              color: AppColors.of(context).text.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8.0),
            Text(
              'go_home'.i18n,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: AppColors.of(context).text.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final name = subjectName != null
        ? subjectName()
        : ((nextLesson.subject?.isRenamed ?? false)
                ? nextLesson.subject.renamedTo
                : nextLesson.subject?.name?.capital()) ??
            '';
    final room = nextLesson.room as String? ?? '';
    final start = nextLesson.start as DateTime?;

    return Container(
      color: AppColors.of(context).text.withValues(alpha: 0.03),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
      child: Row(
        children: [
          Icon(
            Icons.arrow_forward_rounded,
            size: 13.0,
            color: AppColors.of(context).text.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                fontStyle: italic ? FontStyle.italic : null,
                color: AppColors.of(context).text.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (room.isNotEmpty) ...[
            const SizedBox(width: 6.0),
            Container(
              constraints: const BoxConstraints(maxWidth: 72.0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                room,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
          if (start != null) ...[
            const SizedBox(width: 6.0),
            Text(
              DateFormat('H:mm').format(start),
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: AppColors.of(context).text.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showHeadsUp(double maxTime, double elapsedTime) async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    final result = await showDialog(
      barrierColor: Colors.black,
      context: context,
      builder: (context) =>
          HeadsUpCountdown(maxTime: maxTime, elapsedTime: elapsedTime),
    );
    if (result != null) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    liveCard = Provider.of<LiveCardProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (!liveCard.show) return const SizedBox.shrink();

    final bellDelay = liveCard.delay;
    Widget child;

    switch (liveCard.currentState) {
      // ── Year-end summary ────────────────────────────────────────────────────
      case LiveCardState.summary:
        child = LiveCardWidget(
          key: const Key('livecard.summary'),
          onTap: () =>
              SummaryScreen.show(context: context, currentPage: 'start'),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'year_end_title'.i18n,
                        style: const TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'year_end_action'.i18n,
                        style: TextStyle(
                          fontSize: 14.0,
                          color:
                              AppColors.of(context).text.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.of(context).text.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        );
        break;

      // ── Morning — countdown to first lesson ─────────────────────────────────
      case LiveCardState.morning:
        final greeting = 'good_morning'.i18n;
        child = LiveCardWidget(
          key: const Key('livecard.morning'),
          onTap: () async {
            await MapsLauncher.launchQuery(
                '${_userProvider.student?.school.city ?? ''} ${_userProvider.student?.school.name ?? ''}');
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelRow(greeting),
                    const SizedBox(height: 4.0),
                    Text(
                      'until_first_lesson'.i18n,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color:
                            AppColors.of(context).text.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    if (liveCard.nextLesson != null)
                      SegmentedCountdown(date: liveCard.nextLesson!.start),
                  ],
                ),
              ),
              if (liveCard.nextLesson != null) ...[
                _divider(),
                _nextRow(
                  liveCard.nextLesson,
                  italic: liveCard.nextLesson!.subject.isRenamed &&
                      settingsProvider.renamedSubjectsEnabled &&
                      settingsProvider.renamedSubjectsItalics,
                  subjectName: () =>
                      (liveCard.nextLesson!.subject.isRenamed
                          ? liveCard.nextLesson!.subject.renamedTo
                          : liveCard.nextLesson!.subject.name.capital()) ??
                      '',
                ),
              ],
            ],
          ),
        );
        break;

      // ── Afternoon / Night ────────────────────────────────────────────────────
      case LiveCardState.afternoon:
      case LiveCardState.night:
        final greeting = liveCard.currentState == LiveCardState.afternoon
            ? 'good_afternoon'.i18n
            : 'good_evening'.i18n;
        child = LiveCardWidget(
          key: Key('livecard.${liveCard.currentState.name}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
            child: Row(
              children: [
                Icon(
                  liveCard.currentState == LiveCardState.afternoon
                      ? Icons.local_cafe_rounded
                      : Icons.nightlight_round,
                  size: 22.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      // ── During lesson ────────────────────────────────────────────────────────
      case LiveCardState.duringLesson:
        if (liveCard.currentLesson == null) {
          child = const SizedBox.shrink();
          break;
        }

        final lessonName = (liveCard.currentLesson!.subject.isRenamed &&
                    settingsProvider.renamedSubjectsEnabled
                ? liveCard.currentLesson!.subject.renamedTo
                : liveCard.currentLesson!.subject.name.capital()) ??
            '';
        final lessonItalic = liveCard.currentLesson!.subject.isRenamed &&
            settingsProvider.renamedSubjectsEnabled &&
            settingsProvider.renamedSubjectsItalics;

        final nextSubjectName =
            (liveCard.nextLesson?.subject.isRenamed == true &&
                        settingsProvider.renamedSubjectsEnabled
                    ? liveCard.nextLesson?.subject.renamedTo
                    : liveCard.nextLesson?.subject.name.capital()) ??
                '';
        final nextItalic = liveCard.nextLesson?.subject.isRenamed == true &&
            settingsProvider.renamedSubjectsEnabled &&
            settingsProvider.renamedSubjectsItalics;

        child = LiveCardWidget(
          key: const Key('livecard.duringLesson'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _subjectRow(
                      lessonName,
                      icon: SubjectIcon.resolveVariant(
                        context: context,
                        subject: liveCard.currentLesson!.subject,
                      ),
                      room: liveCard.currentLesson!.room,
                      italic: lessonItalic,
                    ),
                    if (liveCard.currentLesson!.description.isNotEmpty) ...[
                      const SizedBox(height: 5.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 50.0),
                        child: Text(
                          liveCard.currentLesson!.description,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: AppColors.of(context)
                                .text
                                .withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12.0),
                    _progressRow(
                      start: liveCard.currentLesson!.start,
                      end: liveCard.currentLesson!.end,
                      bellDelay: bellDelay,
                      onTap: (mt, et) => _showHeadsUp(mt, et),
                    ),
                  ],
                ),
              ),
              _divider(),
              _nextRow(
                liveCard.nextLesson,
                italic: nextItalic,
                subjectName: () => nextSubjectName,
              ),
            ],
          ),
        );
        break;

      // ── During break ─────────────────────────────────────────────────────────
      case LiveCardState.duringBreak:
        if (liveCard.prevLesson == null || liveCard.nextLesson == null) {
          child = const SizedBox.shrink();
          break;
        }

        final diff = liveCard.getFloorDifference();

        final breakDescription =
            liveCard.nextLesson!.room != liveCard.prevLesson!.room
                ? localizeFill("go $diff".i18n, [
                    diff != "to room"
                        ? (liveCard.nextLesson!.getFloor() ?? 0)
                        : liveCard.nextLesson!.room
                  ])
                : "stay".i18n;

        final breakTimes =
            '${DateFormat("H:mm").format(liveCard.prevLesson!.end)} – ${DateFormat("H:mm").format(liveCard.nextLesson!.start)}';

        final nextSubjectName = (liveCard.nextLesson!.subject.isRenamed &&
                    settingsProvider.renamedSubjectsEnabled
                ? liveCard.nextLesson!.subject.renamedTo
                : liveCard.nextLesson!.subject.name.capital()) ??
            '';
        final nextItalic = liveCard.nextLesson!.subject.isRenamed &&
            settingsProvider.renamedSubjectsEnabled &&
            settingsProvider.renamedSubjectsItalics;

        child = LiveCardWidget(
          key: const Key('livecard.duringBreak'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelRow(
                      'break'.i18n,
                      trailing: breakTimes,
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Container(
                          width: 38.0,
                          height: 38.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Icon(
                            Icons.local_cafe_outlined,
                            size: 19.0,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            breakDescription,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    _progressRow(
                      start: liveCard.prevLesson!.end,
                      end: liveCard.nextLesson!.start,
                      bellDelay: bellDelay,
                      onTap: (mt, et) => _showHeadsUp(mt, et),
                    ),
                  ],
                ),
              ),
              _divider(),
              _nextRow(
                liveCard.nextLesson,
                italic: nextItalic,
                subjectName: () => nextSubjectName,
              ),
            ],
          ),
        );
        break;

      default:
        child = const SizedBox.shrink();
    }

    return PageTransitionSwitcher(
      transitionBuilder: (
        Widget child,
        Animation<double> primaryAnimation,
        Animation<double> secondaryAnimation,
      ) {
        return SharedAxisTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Self-contained progress row that drives its own 1-second timer.
/// Only this widget repaints every second — the parent LiveCard stays still.
class _LiveCardProgress extends StatefulWidget {
  const _LiveCardProgress({
    required this.start,
    required this.end,
    required this.bellDelay,
    this.onTap,
  });

  final DateTime start;
  final DateTime end;
  final Duration bellDelay;
  final void Function(double maxTime, double elapsed)? onTap;

  @override
  State<_LiveCardProgress> createState() => _LiveCardProgressState();
}

class _LiveCardProgressState extends State<_LiveCardProgress> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxTime = widget.end.difference(widget.start).inSeconds.toDouble();
    final elapsedTime =
        DateTime.now().difference(widget.start).inSeconds.toDouble() +
            widget.bellDelay.inSeconds;
    final showMinutes = maxTime - elapsedTime > 60;
    final progressMax = showMinutes ? maxTime / 60 : maxTime;
    final progressCurrent = showMinutes ? elapsedTime / 60 : elapsedTime;
    final remaining =
        (progressMax - progressCurrent).clamp(0, double.infinity).round();
    final label = showMinutes
        ? "remaining min".plural(remaining)
        : "remaining sec".plural(remaining);

    return Row(
      children: [
        Expanded(
          child: ProgressBar(
            value: (progressCurrent / progressMax).clamp(0.0, 1.0),
            height: 5.0,
          ),
        ),
        const SizedBox(width: 10.0),
        GestureDetector(
          onTap: widget.onTap != null
              ? () => widget.onTap!(maxTime, elapsedTime)
              : null,
          behavior: HitTestBehavior.opaque,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).text.withValues(alpha: 0.48),
            ),
          ),
        ),
      ],
    );
  }
}
