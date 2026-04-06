import 'dart:math';

import 'package:folio_kreta_api/models/category.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_kreta_api/models/teacher.dart';
import 'package:folio_mobile_ui/common/custom_snack_bar.dart';
import 'package:folio/ui/widgets/grade/grade_tile.dart';
import 'package:folio_mobile_ui/pages/grades/calculator/grade_calculator_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'grade_calculator.i18n.dart';

class GradeCalculator extends StatefulWidget {
  const GradeCalculator(this.subject, {super.key});

  final GradeSubject? subject;

  @override
  GradeCalculatorState createState() => GradeCalculatorState();
}

class GradeCalculatorState extends State<GradeCalculator> {
  late GradeCalculatorProvider calculatorProvider;

  int newValue = 5;
  int newWeight = 100;

  @override
  Widget build(BuildContext context) {
    calculatorProvider = Provider.of<GradeCalculatorProvider>(context);
    final bottom = MediaQuery.of(context).padding.bottom + 82;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 32,
            height: 3,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Grade buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final grade = i + 1;
              final selected = newValue == grade;
              final gColor =
                  gradeColor(context: context, value: grade.toDouble());
              return GestureDetector(
                onTap: () => setState(() => newValue = grade),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: selected ? 50 : 42,
                  height: selected ? 50 : 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? gColor
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: gColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      grade.toString(),
                      style: TextStyle(
                        fontSize: selected ? 22 : 17,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Weight slider
          Row(
            children: [
              Text(
                '%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Slider(
                  value: newWeight.toDouble(),
                  min: 0,
                  max: 400,
                  divisions: 16,
                  label: '$newWeight%',
                  activeColor: Theme.of(context).colorScheme.secondary,
                  onChanged: (v) => setState(() => newWeight = v.round()),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '$newWeight%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Add button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (calculatorProvider.ghosts.length >= 50) {
                  ScaffoldMessenger.of(context).showSnackBar(CustomSnackBar(
                      content: Text("limit_reached".i18n), context: context));
                  return;
                }

                DateTime date;
                if (calculatorProvider.ghosts.isNotEmpty) {
                  final g = List<Grade>.from(calculatorProvider.ghosts)
                    ..sort((a, b) => -a.writeDate.compareTo(b.writeDate));
                  date = g.first.date.add(const Duration(days: 7));
                } else {
                  final g = calculatorProvider.grades
                      .where((e) =>
                          e.type == GradeType.midYear &&
                          (e.subject == widget.subject ||
                              widget.subject == null))
                      .toList()
                    ..sort((a, b) => -a.writeDate.compareTo(b.writeDate));
                  date = g.isNotEmpty ? g.first.date : DateTime.now();
                }

                calculatorProvider.addGhost(Grade(
                  id: _randomId(),
                  date: date,
                  writeDate: date,
                  description: "Ghost Grade".i18n,
                  value: GradeValue(newValue, "", "", newWeight),
                  teacher: Teacher.fromString("Ghost"),
                  type: GradeType.ghost,
                  form: "",
                  subject: widget.subject ??
                      GradeSubject(
                        id: _randomId(),
                        category: Category(id: _randomId()),
                        name: 'All',
                      ),
                  mode: Category.fromJson({}),
                  seenDate: DateTime(0),
                  groupId: "",
                ));
              },
              child: Text(
                "Add Grade".i18n,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _randomId() => Random().nextInt(1000000000).toString();
}
