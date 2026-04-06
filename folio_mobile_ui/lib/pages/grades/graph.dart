import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:folio/helpers/average_helper.dart';
import 'package:folio/ui/widgets/grade/grade_tile.dart';
import 'package:folio_kreta_api/models/grade.dart';

class GradeGraph extends StatelessWidget {
  const GradeGraph(
    this.grades, {
    super.key,
    this.classAvg = 0.0,
  });

  final List<Grade> grades;
  final double classAvg;

  @override
  Widget build(BuildContext context) {
    final points = grades
        .where((g) =>
            (g.type == GradeType.midYear || g.type == GradeType.ghost) &&
            g.value.value > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (points.length < 2) return const SizedBox();

    // Running average: each spot = avg of all grades up to that index
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      final avg = AverageHelper.averageEvals(points.sublist(0, i + 1));
      spots.add(FlSpot(i.toDouble(), avg));
    }

    // Grade-color gradient anchored to the ACTUAL data range (not chart height).
    // fl_chart applies the gradient relative to the line's bounding box in
    // canvas space, so we compute stops based on real min/max spot values so
    // that the color always reflects the absolute 1-5 scale.
    final minDataY = spots.map((s) => s.y).reduce(min).clamp(1.0, 5.0);
    final maxDataY = spots.map((s) => s.y).reduce(max).clamp(1.0, 5.0);
    final dataRange = max(0.01, maxDataY - minDataY);

    final List<Color> lineColors = [];
    final List<double> lineStops = [];
    lineColors.add(gradeColor(context: context, value: minDataY));
    lineStops.add(0.0);
    // insert a color-stop at every integer grade boundary within the range
    for (int g = minDataY.floor() + 1; g <= maxDataY.ceil(); g++) {
      final v = g.clamp(1, 5).toDouble();
      if (v > minDataY && v < maxDataY) {
        lineColors.add(gradeColor(context: context, value: v));
        lineStops.add(((v - minDataY) / dataRange).clamp(0.001, 0.999));
      }
    }
    lineColors.add(gradeColor(context: context, value: maxDataY));
    lineStops.add(1.0);
    // LinearGradient requires ≥ 2 colors
    if (lineColors.length == 1) {
      lineColors.add(lineColors.first);
      lineStops.add(1.0);
    }

    final lineGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: lineColors,
      stops: lineStops,
    );

    // Area gradient: simple fade from the mid-value colour to transparent
    final midColor =
        gradeColor(context: context, value: (minDataY + maxDataY) / 2);
    final areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        midColor.withValues(alpha: 0.18),
        midColor.withValues(alpha: 0.0),
      ],
    );

    final labelColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return SizedBox(
      height: 150.0,
      child: LineChart(
        LineChartData(
          minY: 1.0,
          maxY: 5.0,
          minX: 0,
          maxX: (points.length - 1).toDouble().clamp(1.0, double.infinity),
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.07),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  if (value < 1 ||
                      value > 5 ||
                      value != value.roundToDouble()) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (classAvg >= 1.0)
                HorizontalLine(
                  y: classAvg.clamp(1.0, 5.0),
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.22),
                  strokeWidth: 1.5,
                  dashArray: [4, 6],
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.55,
              gradient: lineGradient,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: areaGradient,
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toStringAsFixed(2),
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: gradeColor(context: context, value: spot.y),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
