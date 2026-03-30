import 'package:folio/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class GoalInput extends StatelessWidget {
  const GoalInput(
      {super.key,
      required this.currentAverage,
      required this.value,
      required this.onChanged});

  final double currentAverage;
  final double value;
  final void Function(double value) onChanged;

  void offsetToValue(Offset offset, Size size) {
    double v = ((offset.dx / size.width * 4 + 1) * 10).round() / 10;
    v = v.clamp(1.5, 5);
    v = v.clamp(((currentAverage * 10).round() / 10), 5);
    setValue(v);
  }

  void setValue(double v) {
    if (v != value) {
      HapticFeedback.lightImpact();
    }
    onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider settings = Provider.of<SettingsProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(builder: (context, size) {
          return GestureDetector(
            onTapDown: (details) {
              offsetToValue(details.localPosition, size.biggest);
            },
            onHorizontalDragUpdate: (details) {
              offsetToValue(details.localPosition, size.biggest);
            },
            child: SizedBox(
              height: 32.0,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: CustomPaint(
                  painter: GoalSliderPainter(
                      value: (value - 1) / 4,
                      settings: settings,
                      goalValue: value),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class GoalSliderPainter extends CustomPainter {
  final double value;
  final SettingsProvider settings;
  final double goalValue;

  GoalSliderPainter(
      {required this.value, required this.settings, required this.goalValue});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    const cpadding = 4;
    final rect = Rect.fromLTWH(0, 0, size.width + radius, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(99.0),
      ),
      Paint()..color = Colors.black.withOpacity(.1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(99.0),
      ),
      Paint()
        ..shader = LinearGradient(colors: [
          settings.gradeColors[0],
          settings.gradeColors[1],
          settings.gradeColors[2],
          settings.gradeColors[3],
          settings.gradeColors[4],
        ]).createShader(rect),
    );

    double w = size.width + radius;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            (w - (w * 0.986)) / 2,
            (size.height - (size.height * 0.85)) / 2,
            w * 0.986,
            size.height * 0.85),
        const Radius.circular(99.0),
      ),
      Paint()..color = Colors.white.withOpacity(.8),
    );

    canvas.drawOval(
      Rect.fromCircle(
          center: Offset(size.width * value, size.height / 2),
          radius: radius - cpadding),
      Paint()..color = Colors.white,
    );
    canvas.drawOval(
      Rect.fromCircle(
          center: Offset(size.width * value, size.height / 2),
          radius: (radius - cpadding) * 0.8),
      Paint()..color = gradeColor(goalValue.round(), settings),
    );

    for (int i = 1; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCircle(
            center: Offset(size.width / 4 * i, size.height / 2), radius: 4),
        Paint()..color = Colors.white.withOpacity(.6),
      );
    }
  }

  @override
  bool shouldRepaint(GoalSliderPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

double gradeToAvg(int grade) {
  return grade - 0.5;
}

Color gradeColor(int grade, SettingsProvider settings) {
  return [
    settings.gradeColors[0],
    settings.gradeColors[1],
    settings.gradeColors[2],
    settings.gradeColors[3],
    settings.gradeColors[4],
  ].elementAt(grade.clamp(1, 5) - 1);
}
