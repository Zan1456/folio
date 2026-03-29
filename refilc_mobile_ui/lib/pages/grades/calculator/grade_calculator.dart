import 'dart:math';

import 'package:refilc_kreta_api/models/category.dart';
import 'package:refilc_kreta_api/models/grade.dart';
import 'package:refilc_kreta_api/models/subject.dart';
import 'package:refilc_kreta_api/models/teacher.dart';
import 'package:refilc_mobile_ui/common/custom_snack_bar.dart';
import 'package:refilc/ui/widgets/grade/grade_tile.dart';
import 'package:refilc_mobile_ui/pages/grades/calculator/grade_calculator_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _weightController = TextEditingController(text: "100");

  double newValue = 5.0;
  double newWeight = 100.0;

  @override
  Widget build(BuildContext context) {
    calculatorProvider = Provider.of<GradeCalculatorProvider>(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Text(
              "Grade Calculator".i18n,
              style:
                  const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
            ),
          ),

          // Grade selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              int grade = index + 1;
              bool selected = newValue.toInt() == grade;
              Color gColor =
                  gradeColor(context: context, value: grade.toDouble());
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => newValue = grade.toDouble());
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: selected ? 56.0 : 48.0,
                  height: selected ? 56.0 : 48.0,
                  decoration: BoxDecoration(
                    color: selected
                        ? gColor
                        : Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: gColor.withValues(alpha: 0.4),
                              blurRadius: 12.0,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      grade.toString(),
                      style: TextStyle(
                        fontSize: selected ? 26.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32.0),

          // Grade weight
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.percent,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Slider(
                    thumbColor: Theme.of(context).colorScheme.secondary,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    inactiveColor: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.2),
                    value: newWeight.clamp(50, 400),
                    min: 50.0,
                    max: 400.0,
                    divisions: 7,
                    label: "${newWeight.toInt()}%",
                    onChanged: (value) => setState(() {
                      newWeight = value;
                      _weightController.text = newWeight.toInt().toString();
                    }),
                  ),
                ),
                SizedBox(
                  width: 50.0,
                  child: TextField(
                    controller: _weightController,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20.0),
                    autocorrect: false,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        newWeight = double.tryParse(value) ?? 100.0;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Text(
                    "%",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32.0),

          // Add button
          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
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
                  List<Grade> grades = calculatorProvider.ghosts;
                  grades.sort((a, b) => -a.writeDate.compareTo(b.writeDate));
                  date = grades.first.date.add(const Duration(days: 7));
                } else {
                  List<Grade> grades = calculatorProvider.grades
                      .where((e) =>
                          e.type == GradeType.midYear &&
                          (e.subject == widget.subject ||
                              widget.subject == null))
                      .toList();
                  grades.sort((a, b) => -a.writeDate.compareTo(b.writeDate));
                  date = () {
                    try {
                      return grades.first.date;
                    } catch (e) {
                      return DateTime.now();
                    }
                  }();
                }

                calculatorProvider.addGhost(Grade(
                  id: randomId(),
                  date: date,
                  writeDate: date,
                  description: "Ghost Grade".i18n,
                  value:
                      GradeValue(newValue.toInt(), "", "", newWeight.toInt()),
                  teacher: Teacher.fromString("Ghost"),
                  type: GradeType.ghost,
                  form: "",
                  subject: widget.subject ??
                      GradeSubject(
                        id: randomId(),
                        category: Category(id: randomId()),
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
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  String randomId() {
    var rng = Random();
    return rng.nextInt(1000000000).toString();
  }
}
