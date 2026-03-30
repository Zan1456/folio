import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HeadsUpCountdown extends StatefulWidget {
  const HeadsUpCountdown(
      {super.key, required this.maxTime, required this.elapsedTime});

  final double maxTime;
  final double elapsedTime;

  @override
  State<HeadsUpCountdown> createState() => _HeadsUpCountdownState();
}

class _HeadsUpCountdownState extends State<HeadsUpCountdown> {
  static const _style = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 70.0,
    letterSpacing: -.5,
  );

  late final Timer _timer;
  late final ValueNotifier<int> _remaining;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final initialRemaining =
        (widget.maxTime - widget.elapsedTime).round().clamp(0, widget.maxTime.round());
    _remaining = ValueNotifier<int>(initialRemaining);
    WakelockPlus.enable();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _remaining.value - 1;
      _remaining.value = next < 0 ? 0 : next;
      if (!_finished && next <= 0) {
        _finished = true;
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _remaining.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: ValueListenableBuilder<int>(
          valueListenable: _remaining,
          builder: (context, remaining, _) {
            final dur = Duration(seconds: remaining);
            final finished = remaining <= 0;
            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: finished ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if ((dur.inHours % 24) > 0) ...[
                        AnimatedFlipCounter(
                          value: dur.inHours % 24,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          textStyle: _style,
                        ),
                        const Text(":", style: _style),
                      ],
                      AnimatedFlipCounter(
                        duration: const Duration(milliseconds: 400),
                        value: dur.inMinutes % 60,
                        curve: Curves.easeOut,
                        wholeDigits: (dur.inHours % 24) > 0 ? 2 : 1,
                        textStyle: _style,
                      ),
                      const Text(":", style: _style),
                      AnimatedFlipCounter(
                        duration: const Duration(milliseconds: 300),
                        value: dur.inSeconds % 60,
                        curve: Curves.easeOut,
                        wholeDigits: 2,
                        textStyle: _style,
                      ),
                    ],
                  ),
                ),
                if (finished)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(
                      Icons.notifications_active,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
