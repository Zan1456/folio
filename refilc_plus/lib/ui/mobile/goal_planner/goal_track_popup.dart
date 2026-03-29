import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refilc/api/providers/database_provider.dart';
import 'package:refilc/api/providers/user_provider.dart';
import 'package:refilc/helpers/average_helper.dart';
import 'package:refilc/helpers/subject.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc_kreta_api/models/grade.dart';
import 'package:refilc_kreta_api/models/subject.dart';
import 'package:refilc_kreta_api/providers/grade_provider.dart';
import 'package:refilc_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:refilc_plus/models/premium_scopes.dart';
import 'package:refilc_plus/providers/plus_provider.dart';
import 'package:refilc_plus/ui/mobile/goal_planner/goal_input.dart';
import 'package:refilc_plus/ui/mobile/goal_planner/goal_planner.dart';
import 'package:refilc_plus/ui/mobile/goal_planner/goal_planner_screen.dart';
import 'package:refilc_plus/ui/mobile/goal_planner/goal_planner_screen.i18n.dart';
import 'package:refilc_plus/ui/mobile/goal_planner/route_option.dart';

class GoalTrackPopup extends StatefulWidget {
  const GoalTrackPopup({super.key, required this.subject});

  final GradeSubject subject;

  static void show(BuildContext context, {required GradeSubject subject}) =>
      showRoundedModalBottomSheet(
        context,
        child: GoalTrackPopup(subject: subject),
        showHandle: false,
        backgroundColor: Colors.transparent,
      );

  @override
  GoalTrackPopupState createState() => GoalTrackPopupState();
}

class GoalTrackPopupState extends State<GoalTrackPopup> {
  late UserProvider user;
  late DatabaseProvider dbProvider;
  late GradeProvider gradeProvider;
  late SettingsProvider settingsProvider;

  List<Grade> getSubjectGrades(GradeSubject subject) =>
      gradeProvider.grades.where((e) => e.subject == subject).toList();

  double goalValue = 4.0;
  List<Grade> grades = [];

  Plan? recommended;
  Plan? fastest;
  Plan? selectedRoute;
  List<Plan> otherPlans = [];

  bool plansPage = false;

  @override
  void initState() {
    super.initState();
    user = Provider.of<UserProvider>(context, listen: false);
    dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
  }

  Future<Map<String, String>> fetchGoalPlans() async {
    return await dbProvider.userQuery.subjectGoalPlans(userId: user.id!);
  }

  Future<Map<String, String>> fetchGoalAverages() async {
    return await dbProvider.userQuery.subjectGoalAverages(userId: user.id!);
  }

  Future<Map<String, String>> fetchGoalBees() async {
    return await dbProvider.userQuery.subjectGoalBefores(userId: user.id!);
  }

  Future<Map<String, String>> fetchGoalPinDates() async {
    return await dbProvider.userQuery.subjectGoalPinDates(userId: user.id!);
  }

  PlanResult getResult() {
    final currentAvg = GoalPlannerHelper.averageEvals(grades);

    recommended = null;
    fastest = null;
    otherPlans = [];

    if (currentAvg >= goalValue) return PlanResult.reached;

    final planner = GoalPlanner(goalValue, grades);
    final plans = planner.solve();

    plans.sort((a, b) => (a.avg - (2 * goalValue + 5) / 3)
        .abs()
        .compareTo(b.avg - (2 * goalValue + 5) / 3));

    try {
      final singleSolution = plans.every((e) => e.sigma == 0);
      recommended =
          plans.where((e) => singleSolution ? true : e.sigma > 0).first;
      plans.removeWhere((e) => e == recommended);
    } catch (_) {}

    plans.sort((a, b) => a.plan.length.compareTo(b.plan.length));

    try {
      fastest = plans.removeAt(0);
    } catch (_) {}

    if ((((recommended?.plan.length ?? 0) - (fastest?.plan.length ?? 0)) >=
            5) &&
        fastest != null) {
      recommended = fastest;
    }

    if (recommended == null) {
      recommended = null;
      fastest = null;
      otherPlans = [];
      selectedRoute = null;
      return PlanResult.unsolvable;
    }

    if (recommended!.plan.length > 20) {
      recommended = null;
      fastest = null;
      otherPlans = [];
      selectedRoute = null;
      return PlanResult.unreachable;
    }

    otherPlans = List.from(plans);

    if (!Provider.of<PlusProvider>(context)
        .hasScope(PremiumScopes.unlimitedGoalPlanner)) {
      if (otherPlans.length > 2) {
        otherPlans.removeRange(2, otherPlans.length - 1);
      }
    }

    return PlanResult.available;
  }

  void getGrades() {
    grades = getSubjectGrades(widget.subject).toList();
  }

  @override
  Widget build(BuildContext context) {
    gradeProvider = Provider.of<GradeProvider>(context);
    settingsProvider = Provider.of<SettingsProvider>(context);

    getGrades();

    final currentAvg = GoalPlannerHelper.averageEvals(grades);
    final result = getResult();
    final avg = AverageHelper.averageEvals(getSubjectGrades(widget.subject));
    final subjectName = widget.subject.isRenamed
        ? widget.subject.renamedTo ?? widget.subject.name
        : widget.subject.name;

    final double listLength = (otherPlans.length +
        (recommended != null ? 1 : 0) +
        (fastest != null && fastest != recommended ? 1 : 0));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      size: 18.0,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plansPage
                              ? 'goalplan_plans_title'.i18n
                              : 'goalplan_title'.i18n,
                          style: const TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          subjectName,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Subject icon
                  Container(
                    padding: const EdgeInsets.all(9.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      SubjectIcon.resolveVariant(
                          context: context, subject: widget.subject),
                      size: 18.0,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18.0),

              // Current avg → goal card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          avg > 0 ? avg.toStringAsFixed(2) : '—',
                          style: TextStyle(
                            fontSize: 40.0,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: avg > 0
                                ? gradeColor(avg.round(), settingsProvider)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'set_a_goal'.i18n,
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20.0,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.35),
                    ),
                    Column(
                      children: [
                        Text(
                          goalValue.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 40.0,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color:
                                gradeColor(goalValue.round(), settingsProvider),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'goalplan_title'.i18n,
                          style: TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Goal slider (first page)
              if (!plansPage) ...[
                GoalInput(
                  value: goalValue,
                  currentAverage: currentAvg,
                  onChanged: (v) => setState(() {
                    selectedRoute = null;
                    goalValue = v;
                  }),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'goalplan_subtitle'.i18n,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Route options (second page)
              if (plansPage) ...[
                if (listLength > 2)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: SingleChildScrollView(
                      child: _buildRouteOptions(result),
                    ),
                  )
                else
                  _buildRouteOptions(result),
              ],

              const SizedBox(height: 20.0),

              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!plansPage) {
                      setState(() => plansPage = true);
                      return;
                    }

                    if (selectedRoute == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${"pick_route".i18n}...')));
                      return;
                    }

                    final goalPlans = await fetchGoalPlans();
                    final goalAvgs = await fetchGoalAverages();
                    final goalBeforeGrades = await fetchGoalBees();
                    final goalPinDates = await fetchGoalPinDates();

                    goalPlans[widget.subject.id] = selectedRoute!.dbString;
                    goalAvgs[widget.subject.id] = goalValue.toStringAsFixed(2);
                    goalBeforeGrades[widget.subject.id] =
                        avg.toStringAsFixed(2);
                    goalPinDates[widget.subject.id] =
                        DateTime.now().toIso8601String();

                    await dbProvider.userStore
                        .storeSubjectGoalPlans(goalPlans, userId: user.id!);
                    await dbProvider.userStore
                        .storeSubjectGoalAverages(goalAvgs, userId: user.id!);
                    await dbProvider.userStore.storeSubjectGoalBefores(
                        goalBeforeGrades,
                        userId: user.id!);
                    await dbProvider.userStore.storeSubjectGoalPinDates(
                        goalPinDates,
                        userId: user.id!);

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: Text(
                    plansPage ? 'track_it'.i18n : 'show_my_ways'.i18n,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteOptions(PlanResult result) {
    return Column(
      children: [
        if (recommended != null)
          RouteOption(
            plan: recommended!,
            mark: RouteMark.recommended,
            selected: selectedRoute == recommended!,
            onSelected: () => setState(() => selectedRoute = recommended),
          ),
        if (fastest != null && fastest != recommended)
          RouteOption(
            plan: fastest!,
            mark: RouteMark.fastest,
            selected: selectedRoute == fastest!,
            onSelected: () => setState(() => selectedRoute = fastest),
          ),
        ...otherPlans.map((e) => RouteOption(
              plan: e,
              selected: selectedRoute == e,
              onSelected: () => setState(() => selectedRoute = e),
            )),
        if (result != PlanResult.available)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              result.name.i18n,
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
