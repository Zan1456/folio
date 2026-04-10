/*
    Folio, the unofficial client for e-Kréta
    Copyright (C) 2025  Folio team

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:folio/helpers/notification_helper.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:folio/helpers/quick_actions.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio/api/providers/liveactivity/platform_channel.dart';
import 'package:folio/helpers/android_live_activity_helper.dart';
import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio/api/providers/update_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/observer.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_mobile_ui/common/action_button.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';
import 'package:folio_mobile_ui/common/splitted_panel/splitted_panel.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_viewable.dart';
import 'package:folio_mobile_ui/screens/settings/live_activity_consent_dialog.dart';
import 'package:folio_mobile_ui/screens/settings/navbar_order_screen.dart';
import 'package:folio_mobile_ui/screens/settings/privacy_view.dart';
import 'package:folio_mobile_ui/screens/settings/settings_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_screen.i18n.dart';
// ignore: unused_import
import 'submenu/submenu_screen.i18n.dart' hide SettingsLocalization;

class _SettingsSection {
  final String category;
  final List<String> searchTerms;
  final Widget widget;
  const _SettingsSection({
    required this.category,
    required this.searchTerms,
    required this.widget,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  int devmodeCountdown = 5;
  Future<Map>? futureRelease;

  late UserProvider user;
  late UpdateProvider updateProvider;
  late SettingsProvider settings;

  late AnimationController _hideContainersController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editSubjectNameCtrl = TextEditingController();
  final TextEditingController _editTeacherNameCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _chipScrollController = ScrollController();
  String _searchQuery = '';
  String? _activeNavCategory;
  bool _themeColorOpen = false;

  final Map<String, GlobalKey> _sectionKeys = {
    'general': GlobalKey(),
    'appearance': GlobalKey(),
    'grades': GlobalKey(),
    'notifications': GlobalKey(),
    'other': GlobalKey(),
  };

  final Map<String, GlobalKey> _chipKeys = {
    'general': GlobalKey(),
    'appearance': GlobalKey(),
    'grades': GlobalKey(),
    'notifications': GlobalKey(),
    'other': GlobalKey(),
  };

  double? _tempRounding;
  double? _tempCountdownMinutes;

  late List<Grade> _editedSubjects;

  @override
  void initState() {
    super.initState();
    _hideContainersController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _scrollController.addListener(_updateActiveCategory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      futureRelease = Provider.of<UpdateProvider>(context, listen: false)
          .installedVersion();
      setState(() {});

      setState(() {});
    });
  }

  @override
  void dispose() {
    _hideContainersController.dispose();
    _searchController.dispose();
    _editSubjectNameCtrl.dispose();
    _editTeacherNameCtrl.dispose();
    _scrollController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  void _updateActiveCategory() {
    String? topmost;
    double topmostY = -double.maxFinite;
    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= 180 && dy > topmostY) {
        topmostY = dy;
        topmost = entry.key;
      }
    }
    if (topmost != null && topmost != _activeNavCategory) {
      setState(() => _activeNavCategory = topmost);
      _scrollChipIntoView(topmost);
    }
  }

  void _scrollChipIntoView(String catKey) {
    final chipCtx = _chipKeys[catKey]?.currentContext;
    if (chipCtx == null) return;
    Scrollable.ensureVisible(
      chipCtx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  void _scrollToSection(String category) {
    final ctx = _sectionKeys[category]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  // ── Rename helpers ────────────────────────────────────────

  Future<void> _convertProviders() async {
    await Provider.of<GradeProvider>(context, listen: false)
        .convertBySettings();
    await Provider.of<TimetableProvider>(context, listen: false)
        .convertBySettings();
    await Provider.of<AbsenceProvider>(context, listen: false)
        .convertBySettings();
  }

  /// Shows a scrollable list of all subjects. Tapping one opens the rename
  /// dialog for that subject + teacher pair.
  void _showRenamePickerPopup() {
    final gradeProvider = Provider.of<GradeProvider>(context, listen: false);

    final List<Grade> allSubjects = [];
    final seen = <String>{};
    for (final g in gradeProvider.grades) {
      if (seen.contains(g.subject.id)) continue;
      seen.add(g.subject.id);
      allSubjects.add(g);
    }
    allSubjects.sort((a, b) => a.subject.name.compareTo(b.subject.name));

    final settingsProv = Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
              child: Row(
                children: [
                  Icon(Icons.school_outlined,
                      size: 20.0,
                      color: AppColors.of(context).text.withValues(alpha: .85)),
                  const SizedBox(width: 10.0),
                  Text(
                    "rename_subjects".i18n,
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).text,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420.0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allSubjects.length,
                itemBuilder: (_, i) {
                  final g = allSubjects[i];
                  final subName =
                      g.subject.isRenamed && settingsProv.renamedSubjectsEnabled
                          ? g.subject.renamedTo ?? g.subject.name.capital()
                          : g.subject.name.capital();
                  final teachName =
                      g.teacher.isRenamed && settingsProv.renamedTeachersEnabled
                          ? g.teacher.renamedTo ?? g.teacher.name.capital()
                          : g.teacher.name.capital();
                  final isRenamed = g.subject.isRenamed || g.teacher.isRenamed;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 2.0),
                    leading: Icon(
                      SubjectIcon.resolveVariant(
                          context: context, subject: g.subject),
                      size: 22.0,
                      color: isRenamed
                          ? Theme.of(context).colorScheme.secondary
                          : AppColors.of(context).text.withValues(alpha: .75),
                    ),
                    title: Text(
                      subName ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            isRenamed && settingsProv.renamedSubjectsItalics
                                ? FontStyle.italic
                                : FontStyle.normal,
                        color:
                            AppColors.of(context).text.withValues(alpha: .95),
                      ),
                    ),
                    subtitle: Text(
                      teachName ?? '',
                      style: TextStyle(
                        fontSize: 13.0,
                        color:
                            AppColors.of(context).text.withValues(alpha: .55),
                      ),
                    ),
                    trailing: isRenamed
                        ? Icon(Icons.edit_rounded,
                            size: 16.0,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: .7))
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _showEditSubjectPopup(g);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog to rename the subject + teacher of a given [grade].
  void _showEditSubjectPopup(Grade grade) {
    _editSubjectNameCtrl.text = grade.subject.renamedTo ?? '';
    _editTeacherNameCtrl.text = grade.teacher.renamedTo ?? '';

    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18.0))),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 0.0),
          title: Row(
            children: [
              Icon(
                SubjectIcon.resolveVariant(
                    context: context, subject: grade.subject),
                size: 20.0,
                color: AppColors.of(context).text.withValues(alpha: .85),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  grade.subject.name.capital() ?? '',
                  style: const TextStyle(fontSize: 17.0),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () async {
                  final subs =
                      await db.userQuery.renamedSubjects(userId: userProv.id!);
                  subs.remove(grade.subject.id);
                  await db.userStore
                      .storeRenamedSubjects(subs, userId: userProv.id!);
                  final teach =
                      await db.userQuery.renamedTeachers(userId: userProv.id!);
                  teach.remove(grade.teacher.id);
                  await db.userStore
                      .storeRenamedTeachers(teach, userId: userProv.id!);
                  await _convertProviders();
                  Navigator.of(ctx).pop();
                  setState(() {});
                },
                icon: Icon(Icons.delete_rounded,
                    size: 18.0,
                    color: AppColors.of(context).text.withValues(alpha: .55)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "rename_it".i18n,
                style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).text.withValues(alpha: .55)),
              ),
              const SizedBox(height: 6.0),
              TextField(
                controller: _editSubjectNameCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                  hintText: "modified_name".i18n,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 16.0),
                    onPressed: () => setS(() => _editSubjectNameCtrl.text = ''),
                  ),
                ),
              ),
              const SizedBox(height: 14.0),
              Text(
                "rename_te".i18n,
                style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).text.withValues(alpha: .55)),
              ),
              const SizedBox(height: 6.0),
              TextField(
                controller: _editTeacherNameCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                  hintText: "modified_name".i18n,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.grey, size: 16.0),
                    onPressed: () => setS(() => _editTeacherNameCtrl.text = ''),
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
          actions: [
            TextButton(
              child: Text("cancel".i18n,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: Text("done".i18n,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onPressed: () async {
                final subs =
                    await db.userQuery.renamedSubjects(userId: userProv.id!);
                subs[grade.subject.id] = _editSubjectNameCtrl.text;
                await db.userStore
                    .storeRenamedSubjects(subs, userId: userProv.id!);
                final teach =
                    await db.userQuery.renamedTeachers(userId: userProv.id!);
                teach[grade.teacher.id ?? ''] = _editTeacherNameCtrl.text;
                await db.userStore
                    .storeRenamedTeachers(teach, userId: userProv.id!);
                await _convertProviders();
                Navigator.of(ctx).pop();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      _editSubjectNameCtrl.text = '';
      _editTeacherNameCtrl.text = '';
    });
  }

  Widget _buildSectionHeader(String catKey, String label) {
    return Padding(
      key: _sectionKeys[catKey],
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 18.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(width: 10.0),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _haptic() {
    switch (settings.vibrate) {
      case VibrationStrength.off:
        break;
      case VibrationStrength.light:
        HapticFeedback.selectionClick();
      case VibrationStrength.medium:
        HapticFeedback.lightImpact();
      case VibrationStrength.strong:
        HapticFeedback.mediumImpact();
    }
  }

  Future<void> _checkFirebaseStatus(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    if (currentUser == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16.0),
            Text('firebase_checking'.i18n),
          ],
        ),
      ),
    );

    final status = await NotificationHelper.checkStatus(currentUser, db);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final (IconData icon, Color color, String message) = switch (status) {
      NotificationRegistrationStatus.registered => (
          Icons.check_circle_rounded,
          Colors.green,
          'firebase_reg_registered'.i18n,
        ),
      NotificationRegistrationStatus.tokenMismatch => (
          Icons.warning_rounded,
          Colors.orange,
          'firebase_reg_token_mismatch'.i18n,
        ),
      NotificationRegistrationStatus.notRegistered => (
          Icons.cancel_rounded,
          Colors.red,
          'firebase_reg_not_registered'.i18n,
        ),
      NotificationRegistrationStatus.noToken => (
          Icons.warning_rounded,
          Colors.orange,
          'firebase_reg_no_token'.i18n,
        ),
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, color: color, size: 36.0),
        title: Text('firebase_reg_title'.i18n),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('done'.i18n),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required IconData icon,
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required void Function(double) onChanged,
    void Function(double)? onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14.0, 12.0, 8.0, 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon,
                size: 20.0,
                color: AppColors.of(context).text.withValues(alpha: .85)),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).text.withValues(alpha: .9),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                valueText,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: Theme.of(context).colorScheme.secondary,
              thumbColor: Theme.of(context).colorScheme.secondary,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    settings = Provider.of<SettingsProvider>(context);
    updateProvider = Provider.of<UpdateProvider>(context);

    if (settings.developerMode) devmodeCountdown = -1;

    final gradeProvider = Provider.of<GradeProvider>(context);
    _editedSubjects = gradeProvider.grades
        .where((e) => e.teacher.isRenamed || e.subject.isRenamed)
        .toSet()
        .toList()
      ..sort((a, b) => a.subject.name.compareTo(b.subject.name));

    final allSections = _buildAllSections(context);

    final bool isSearching = _searchQuery.isNotEmpty;

    final Map<String, List<Widget>> grouped = {
      'general': [],
      'appearance': [],
      'grades': [],
      'notifications': [],
      'other': [],
    };
    final List<Widget> searchResults = [];

    for (final s in allSections) {
      if (isSearching) {
        if (s.searchTerms
            .any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()))) {
          searchResults.add(s.widget);
        }
      } else {
        grouped[s.category]?.add(s.widget);
      }
    }

    final navCategories = <Map<String, dynamic>>[
      {
        'key': 'general',
        'label': 'general'.i18n,
        'icon': Icons.settings_rounded
      },
      {
        'key': 'appearance',
        'label': 'personalization'.i18n,
        'icon': Icons.visibility_rounded
      },
      {
        'key': 'grades',
        'label': 'grades'.i18n,
        'icon': Icons.bar_chart_rounded
      },
      {
        'key': 'notifications',
        'label': 'notifications_section'.i18n,
        'icon': Icons.notifications_outlined
      },
      {'key': 'other', 'label': 'other'.i18n, 'icon': Icons.more_horiz_rounded},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (Messages-style) ───────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28.0)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + title row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            "settings".i18n,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isSearching)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18.0,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 14.0),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      decoration: InputDecoration(
                        hintText: "search".i18n,
                        hintStyle: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20.0,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 11.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.12),
                      ),
                    ),
                  ),

                  // ── Category chips (inside header, messages-style) ──
                  if (!isSearching)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _chipScrollController,
                      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 14.0),
                      child: Row(
                        children: navCategories.map((c) {
                          final catKey = c['key'] as String;
                          final isActive = _activeNavCategory == catKey;
                          return Padding(
                            key: _chipKeys[catKey],
                            padding: const EdgeInsets.only(right: 4.0),
                            child: GestureDetector(
                              onTap: () => _scrollToSection(catKey),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      c['icon'] as IconData,
                                      size: 15.0,
                                      color: isActive
                                          ? Theme.of(context)
                                              .colorScheme
                                              .secondary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                              .withValues(alpha: 0.65),
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      c['label'] as String,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isActive
                                            ? Theme.of(context)
                                                .colorScheme
                                                .secondary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                                .withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────
          Expanded(
            child: AnimatedBuilder(
              animation: _hideContainersController,
              builder: (context, child) => Opacity(
                opacity: 1 - _hideContainersController.value,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2.0),

                        // Update banner (always at top)
                        if (!isSearching && updateProvider.available)
                          UpdateViewable(updateProvider.releases.first),

                        // Content
                        if (isSearching) ...[
                          const SizedBox(height: 8.0),
                          if (searchResults.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 32.0),
                              child: Center(
                                child: Text(
                                  '🔍',
                                  style: TextStyle(
                                    fontSize: 36.0,
                                    color: AppColors.of(context)
                                        .text
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...searchResults,
                        ] else ...[
                          if (grouped['general']!.isNotEmpty) ...[
                            _buildSectionHeader('general', 'general'.i18n),
                            ...grouped['general']!,
                          ],
                          if (grouped['appearance']!.isNotEmpty) ...[
                            _buildSectionHeader(
                                'appearance', 'personalization'.i18n),
                            ...grouped['appearance']!,
                          ],
                          if (grouped['grades']!.isNotEmpty) ...[
                            _buildSectionHeader('grades', 'grades'.i18n),
                            ...grouped['grades']!,
                          ],
                          if (grouped['notifications']!.isNotEmpty) ...[
                            _buildSectionHeader(
                                'notifications', 'notifications_section'.i18n),
                            ...grouped['notifications']!,
                          ],
                          if (grouped['other']!.isNotEmpty) ...[
                            _buildSectionHeader('other', 'other'.i18n),
                            ...grouped['other']!,
                          ],
                        ],

                        const SizedBox(height: 20.0),

                        // Version info
                        SafeArea(
                          top: false,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                if (devmodeCountdown > 0) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    duration: const Duration(milliseconds: 200),
                                    content: Text("devmoretaps"
                                        .i18n
                                        .replaceFirst(
                                            '%s', '$devmodeCountdown')),
                                  ));
                                  setState(() => devmodeCountdown--);
                                } else if (devmodeCountdown == 0) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text("devactivated".i18n),
                                  ));
                                  settings.update(developerMode: true);
                                  setState(() => devmodeCountdown--);
                                }
                              },
                              child: FutureBuilder<Map>(
                                future: futureRelease,
                                builder: (context, snapshot) {
                                  final version = snapshot.hasData
                                      ? 'v${snapshot.data!['version']}+${snapshot.data!['build_number']}'
                                      : '...';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.of(context)
                                          .text
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Text(
                                      version,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.of(context)
                                                .text
                                                .withValues(alpha: 0.55),
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20.0),

                        // Developer settings (shown below version after unlocking)
                        if (settings.developerMode) ...[
                          const SizedBox(height: 20.0),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_SettingsSection> _buildAllSections(BuildContext context) {
    return [
      // ── GENERAL ──────────────────────────────────────────────

      // Bell delay + Show breaks
      _SettingsSection(
        category: 'general',
        searchTerms: [
          'csengő',
          'késés',
          'bell',
          'delay',
          'harang',
          'szünet',
          'breaks',
          'szünetek'
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () {
                  SettingsHelper.bellDelay(context);
                  setState(() {});
                },
                title: Text("bell_delay".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.bellDelayEnabled ? .95 : .25))),
                leading: Icon(
                  settings.bellDelayEnabled
                      ? Icons.notifications_outlined
                      : Icons.notifications_off_rounded,
                  size: 22.0,
                  color: AppColors.of(context)
                      .text
                      .withValues(alpha: settings.bellDelayEnabled ? .95 : .25),
                ),
                trailingDivider: true,
                trailing: Switch(
                  onChanged: (v) {
                    _haptic();
                    settings.update(bellDelayEnabled: v);
                  },
                  value: settings.bellDelayEnabled,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0), bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () {
                  settings.update(showBreaks: !settings.showBreaks);
                  setState(() {});
                },
                title: Text("show_breaks".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.showBreaks ? .95 : .25))),
                leading: Icon(
                    settings.showBreaks
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 22.0,
                    color: AppColors.of(context)
                        .text
                        .withValues(alpha: settings.showBreaks ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) {
                    _haptic();
                    settings.update(showBreaks: v);
                  },
                  value: settings.showBreaks,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Live activity (iOS only)
      if (Platform.isIOS)
        _SettingsSection(
          category: 'general',
          searchTerms: ['live activity', 'élő tevékenység', 'dinamikus'],
          widget: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: SplittedPanel(
              cardPadding: const EdgeInsets.all(4.0),
              isSeparated: true,
              children: [
                PanelButton(
                  padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                  onPressed: () {
                    if (!settings.liveActivityEnabled &&
                        !settings.liveActivityConsentAccepted) {
                      LiveActivityConsentDialog.show(context)
                          .then((_) => setState(() {}));
                      return;
                    }
                    final newVal = !settings.liveActivityEnabled;
                    settings.update(liveActivityEnabled: newVal);
                    if (!newVal) {
                      PlatformChannel.endLiveActivity();
                      LiveCardProvider.serverSync.unregister();
                      LiveCardProvider.hasActivityStarted = false;
                    }
                    setState(() {});
                  },
                  title: Text("live_activity_enabled".i18n,
                      style: TextStyle(
                          color: AppColors.of(context).text.withValues(
                              alpha:
                                  settings.liveActivityEnabled ? .95 : .25))),
                  leading: Icon(Icons.show_chart_rounded,
                      size: 22.0,
                      color: AppColors.of(context).text.withValues(
                          alpha: settings.liveActivityEnabled ? .95 : .25)),
                  trailing: Switch(
                    onChanged: (v) {
                      if (v && !settings.liveActivityConsentAccepted) {
                        LiveActivityConsentDialog.show(context)
                            .then((_) => setState(() {}));
                        return;
                      }
                      _haptic();
                      settings.update(liveActivityEnabled: v);
                      if (!v) {
                        PlatformChannel.endLiveActivity();
                        LiveCardProvider.serverSync.unregister();
                        LiveCardProvider.hasActivityStarted = false;
                      }
                      setState(() {});
                    },
                    value: settings.liveActivityEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                      bottom: Radius.circular(12.0)),
                ),
              ],
            ),
          ),
        ),

      // Push Notifications: master toggle + per-category
      _SettingsSection(
        category: 'notifications',
        searchTerms: [
          'push értesítés',
          'értesítések',
          'push notification',
          'notifications',
          'jegy értesítés',
          'hiányzás értesítés',
          'üzenet értesítés',
          'óra értesítés',
          'firebase',
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              // Master on/off toggle (long press → Firebase registration check)
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () {
                  _haptic();
                  settings.update(
                      notificationsEnabled: !settings.notificationsEnabled);
                  setState(() {});
                },
                onLongPress: () => _checkFirebaseStatus(context),
                title: Text(
                  'push_notifications'.i18n,
                  style: TextStyle(
                      color: AppColors.of(context).text.withValues(
                          alpha:
                              settings.notificationsEnabled ? .95 : .25)),
                ),
                leading: Icon(
                  settings.notificationsEnabled
                      ? Icons.notifications_rounded
                      : Icons.notifications_off_rounded,
                  size: 22.0,
                  color: AppColors.of(context).text.withValues(
                      alpha: settings.notificationsEnabled ? .95 : .25),
                ),
                trailing: Switch(
                  onChanged: (v) {
                    _haptic();
                    settings.update(notificationsEnabled: v);
                    setState(() {});
                  },
                  value: settings.notificationsEnabled,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12.0),
                  bottom: Radius.circular(
                      settings.notificationsEnabled ? 4.0 : 12.0),
                ),
              ),
              if (settings.notificationsEnabled) ...[
                // Grades
                PanelButton(
                  padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                  onPressed: () {
                    _haptic();
                    settings.update(
                        notificationsGradesEnabled:
                            !settings.notificationsGradesEnabled);
                    setState(() {});
                  },
                  title: Text(
                    'notification_grades'.i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.notificationsGradesEnabled
                                ? .95
                                : .25)),
                  ),
                  leading: Icon(
                    Icons.bookmark_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha:
                            settings.notificationsGradesEnabled ? .95 : .25),
                  ),
                  trailing: Switch(
                    onChanged: (v) {
                      _haptic();
                      settings.update(notificationsGradesEnabled: v);
                      setState(() {});
                    },
                    value: settings.notificationsGradesEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4.0),
                      bottom: Radius.circular(4.0)),
                ),
                // Absences
                PanelButton(
                  padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                  onPressed: () {
                    _haptic();
                    settings.update(
                        notificationsAbsencesEnabled:
                            !settings.notificationsAbsencesEnabled);
                    setState(() {});
                  },
                  title: Text(
                    'notification_absences'.i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.notificationsAbsencesEnabled
                                ? .95
                                : .25)),
                  ),
                  leading: Icon(
                    Icons.access_time_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha:
                            settings.notificationsAbsencesEnabled ? .95 : .25),
                  ),
                  trailing: Switch(
                    onChanged: (v) {
                      _haptic();
                      settings.update(notificationsAbsencesEnabled: v);
                      setState(() {});
                    },
                    value: settings.notificationsAbsencesEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4.0),
                      bottom: Radius.circular(4.0)),
                ),
                // Messages
                PanelButton(
                  padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                  onPressed: () {
                    _haptic();
                    settings.update(
                        notificationsMessagesEnabled:
                            !settings.notificationsMessagesEnabled);
                    setState(() {});
                  },
                  title: Text(
                    'notification_messages'.i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.notificationsMessagesEnabled
                                ? .95
                                : .25)),
                  ),
                  leading: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha:
                            settings.notificationsMessagesEnabled ? .95 : .25),
                  ),
                  trailing: Switch(
                    onChanged: (v) {
                      _haptic();
                      settings.update(notificationsMessagesEnabled: v);
                      setState(() {});
                    },
                    value: settings.notificationsMessagesEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4.0),
                      bottom: Radius.circular(4.0)),
                ),
                // Lessons
                PanelButton(
                  padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                  onPressed: () {
                    _haptic();
                    settings.update(
                        notificationsLessonsEnabled:
                            !settings.notificationsLessonsEnabled);
                    setState(() {});
                  },
                  title: Text(
                    'notification_lessons'.i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.notificationsLessonsEnabled
                                ? .95
                                : .25)),
                  ),
                  leading: Icon(
                    Icons.school_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha:
                            settings.notificationsLessonsEnabled ? .95 : .25),
                  ),
                  trailing: Switch(
                    onChanged: (v) {
                      _haptic();
                      settings.update(notificationsLessonsEnabled: v);
                      setState(() {});
                    },
                    value: settings.notificationsLessonsEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4.0),
                      bottom: Radius.circular(12.0)),
                ),
              ],
            ],
          ),
        ),
      ),

      // Android Live Activity
      if (Platform.isAndroid)
        _SettingsSection(
          category: 'notifications',
          searchTerms: [
            'android',
            'live activity',
            'értesítés',
            'élő',
            'hyper',
            'hyperos',
            'notifikáció',
            'óra értesítés'
          ],
          widget: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: SplittedPanel(
              cardPadding: const EdgeInsets.all(4.0),
              isSeparated: false,
              children: [
                PanelButton(
                  padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                  onPressed: () {
                    final newVal = !settings.androidLiveActivityEnabled;
                    settings.update(androidLiveActivityEnabled: newVal);
                    if (!newVal) AndroidLiveActivityHelper.cancel();
                    setState(() {});
                  },
                  title: Text(
                    "android_live_activity".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.androidLiveActivityEnabled
                                ? .95
                                : .25)),
                  ),
                  leading: Icon(
                    Icons.show_chart_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha: settings.androidLiveActivityEnabled ? .95 : .25),
                  ),
                  trailing: Switch(
                    onChanged: (v) {
                      _haptic();
                      settings.update(androidLiveActivityEnabled: v);
                      if (!v) AndroidLiveActivityHelper.cancel();
                      setState(() {});
                    },
                    value: settings.androidLiveActivityEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(12.0),
                    bottom: Radius.circular(
                        settings.androidLiveActivityEnabled ? 4.0 : 12.0),
                  ),
                ),
                if (settings.androidLiveActivityEnabled)
                  PanelButton(
                    leading: Icon(Icons.smartphone_rounded,
                        size: 22.0,
                        color:
                            AppColors.of(context).text.withValues(alpha: .95)),
                    title: Text('android_notification_type'.i18n,
                        style: TextStyle(
                            color: AppColors.of(context)
                                .text
                                .withValues(alpha: .95))),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: settings.androidLiveNotificationType,
                        isDense: true,
                        borderRadius: BorderRadius.circular(12.0),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.of(context).text,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'native',
                            child: Text('native_android'.i18n),
                          ),
                          const DropdownMenuItem(
                            value: 'hyper_os',
                            child: Text('HyperOS'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          _haptic();
                          settings.update(androidLiveNotificationType: v);
                          setState(() {});
                        },
                      ),
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4.0),
                        bottom: Radius.circular(12.0)),
                  ),
              ],
            ),
          ),
        ),

      // Countdown settings (only when Android live activity is enabled, or on iOS)
      if (!Platform.isAndroid || settings.androidLiveActivityEnabled)
        _SettingsSection(
          category: 'notifications',
          searchTerms: [
            'visszaszámlálás',
            'countdown',
            'értesítés',
            'tanóra',
            'szünet',
            'perccel',
            'előtte',
          ],
          widget: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: SplittedPanel(
              cardPadding: const EdgeInsets.all(4.0),
              isSeparated: false,
              children: [
                // Main toggle
                PanelButton(
                  padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                  onPressed: () {
                    _haptic();
                    settings.update(
                        liveCountdownEnabled: !settings.liveCountdownEnabled);
                    setState(() {});
                  },
                  title: Text('countdown_enabled'.i18n,
                      style: TextStyle(
                          color: AppColors.of(context).text.withValues(
                              alpha:
                                  settings.liveCountdownEnabled ? .95 : .25))),
                  leading: Icon(Icons.timer_outlined,
                      size: 22.0,
                      color: AppColors.of(context).text.withValues(
                          alpha: settings.liveCountdownEnabled ? .95 : .25)),
                  trailing: Switch(
                    onChanged: (v) {
                      _haptic();
                      settings.update(liveCountdownEnabled: v);
                      setState(() {});
                    },
                    value: settings.liveCountdownEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(12.0),
                    bottom: Radius.circular(
                        settings.liveCountdownEnabled ? 4.0 : 12.0),
                  ),
                ),
                if (settings.liveCountdownEnabled) ...[
                  // Before lesson toggle
                  PanelButton(
                    padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                    onPressed: () {
                      _haptic();
                      settings.update(
                          liveCountdownBeforeLesson:
                              !settings.liveCountdownBeforeLesson);
                      setState(() {});
                    },
                    title: Text('countdown_before_lesson'.i18n,
                        style: TextStyle(
                            color: AppColors.of(context).text.withValues(
                                alpha: settings.liveCountdownBeforeLesson
                                    ? .95
                                    : .25))),
                    leading: Icon(Icons.schedule_rounded,
                        size: 22.0,
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.liveCountdownBeforeLesson
                                ? .95
                                : .25)),
                    trailing: Switch(
                      onChanged: (v) {
                        _haptic();
                        settings.update(liveCountdownBeforeLesson: v);
                        setState(() {});
                      },
                      value: settings.liveCountdownBeforeLesson,
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4.0),
                        bottom: Radius.circular(4.0)),
                  ),
                  // Minutes before (shown when before-lesson is enabled)
                  if (settings.liveCountdownBeforeLesson)
                    _buildSliderCard(
                      icon: Icons.access_time_rounded,
                      label: 'countdown_before_minutes'.i18n,
                      valueText: 'min_before'.i18n.replaceFirst(
                            '%s',
                            '${(_tempCountdownMinutes?.toInt() ?? settings.liveCountdownBeforeMinutes)}',
                          ),
                      value: _tempCountdownMinutes ??
                          settings.liveCountdownBeforeMinutes.toDouble(),
                      min: 1,
                      max: 90,
                      divisions: 89,
                      onChanged: (v) =>
                          setState(() => _tempCountdownMinutes = v),
                      onChangeEnd: (v) {
                        _haptic();
                        settings.update(liveCountdownBeforeMinutes: v.toInt());
                        setState(() => _tempCountdownMinutes = null);
                      },
                    ),
                  // During lesson toggle
                  PanelButton(
                    padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                    onPressed: () {
                      _haptic();
                      settings.update(
                          liveCountdownDuringLesson:
                              !settings.liveCountdownDuringLesson);
                      setState(() {});
                    },
                    title: Text('countdown_during_lesson'.i18n,
                        style: TextStyle(
                            color: AppColors.of(context).text.withValues(
                                alpha: settings.liveCountdownDuringLesson
                                    ? .95
                                    : .25))),
                    leading: Icon(Icons.menu_book_rounded,
                        size: 22.0,
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.liveCountdownDuringLesson
                                ? .95
                                : .25)),
                    trailing: Switch(
                      onChanged: (v) {
                        _haptic();
                        settings.update(liveCountdownDuringLesson: v);
                        setState(() {});
                      },
                      value: settings.liveCountdownDuringLesson,
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4.0),
                        bottom: Radius.circular(4.0)),
                  ),
                  // During break toggle
                  PanelButton(
                    padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                    onPressed: () {
                      _haptic();
                      settings.update(
                          liveCountdownDuringBreak:
                              !settings.liveCountdownDuringBreak);
                      setState(() {});
                    },
                    title: Text('countdown_during_break'.i18n,
                        style: TextStyle(
                            color: AppColors.of(context).text.withValues(
                                alpha: settings.liveCountdownDuringBreak
                                    ? .95
                                    : .25))),
                    leading: Icon(Icons.free_breakfast_outlined,
                        size: 22.0,
                        color: AppColors.of(context).text.withValues(
                            alpha:
                                settings.liveCountdownDuringBreak ? .95 : .25)),
                    trailing: Switch(
                      onChanged: (v) {
                        _haptic();
                        settings.update(liveCountdownDuringBreak: v);
                        setState(() {});
                      },
                      value: settings.liveCountdownDuringBreak,
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4.0),
                        bottom: Radius.circular(12.0)),
                  ),
                ],
              ],
            ),
          ),
        ),

      // Start page (dropdown)
      _SettingsSection(
        category: 'general',
        searchTerms: ['kezdőlap', 'start page', 'kezdőoldal'],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                leading: Icon(Icons.play_arrow_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: .95)),
                title: Text('startpage'.i18n,
                    style: TextStyle(
                        color:
                            AppColors.of(context).text.withValues(alpha: .95))),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<Pages>(
                    value: settings.startPage,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12.0),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.of(context).text,
                    ),
                    items: const [Pages.home, Pages.grades, Pages.timetable]
                        .map((p) => DropdownMenuItem<Pages>(
                              value: p,
                              child: Text(
                                  SettingsHelper.localizedPageTitles()[p]!
                                      .capital()),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _haptic();
                      settings.update(startPage: v);
                      setState(() {});
                    },
                  ),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Language (dropdown)
      _SettingsSection(
        category: 'general',
        searchTerms: ['nyelv', 'language', 'Hungarian', 'English'],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                leading: Icon(Icons.language_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: .95)),
                title: Text('language'.i18n,
                    style: TextStyle(
                        color:
                            AppColors.of(context).text.withValues(alpha: .95))),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.language,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12.0),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.of(context).text,
                    ),
                    items: SettingsHelper.langMap.entries
                        .map((e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value.trim()),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _haptic();
                      Provider.of<SettingsProvider>(context, listen: false)
                          .update(language: v);
                      I18n.of(context).locale = Locale(v, v.toUpperCase());
                      if (Platform.isAndroid || Platform.isIOS) {
                        setupQuickActions();
                      }
                      setState(() {});
                    },
                  ),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Vibration (dropdown)
      _SettingsSection(
        category: 'general',
        searchTerms: ['rezgés', 'vibrate', 'vibráció'],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                leading: Icon(Icons.vibration_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: .95)),
                title: Text('vibrate'.i18n,
                    style: TextStyle(
                        color:
                            AppColors.of(context).text.withValues(alpha: .95))),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<VibrationStrength>(
                    value: settings.vibrate,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12.0),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.of(context).text,
                    ),
                    items: [
                      VibrationStrength.off,
                      VibrationStrength.light,
                      VibrationStrength.medium,
                      VibrationStrength.strong,
                    ]
                        .map((v) => DropdownMenuItem<VibrationStrength>(
                              value: v,
                              child: Text(SettingsHelper
                                      .localizedVibrationTitles()[v] ??
                                  ''),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      settings.update(vibrate: v);
                      // play haptic with the newly selected strength
                      switch (v) {
                        case VibrationStrength.off:
                          break;
                        case VibrationStrength.light:
                          HapticFeedback.selectionClick();
                        case VibrationStrength.medium:
                          HapticFeedback.lightImpact();
                        case VibrationStrength.strong:
                          HapticFeedback.mediumImpact();
                      }
                      setState(() {});
                    },
                  ),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // ── APPEARANCE ───────────────────────────────────────────

      // Theme (dropdown)
      _SettingsSection(
        category: 'appearance',
        searchTerms: ['téma', 'theme', 'sötét', 'világos', 'dark', 'light'],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                leading: Icon(Icons.wb_sunny_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: .95)),
                title: Text('theme'.i18n,
                    style: TextStyle(
                        color:
                            AppColors.of(context).text.withValues(alpha: .95))),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<ThemeMode>(
                    value: settings.theme,
                    isDense: true,
                    borderRadius: BorderRadius.circular(12.0),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.of(context).text,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('light'.i18n),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('dark'.i18n),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('system'.i18n),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      _haptic();
                      settings.update(theme: v);
                      Provider.of<ThemeModeObserver>(context, listen: false)
                          .changeTheme(v);
                      setState(() {});
                    },
                  ),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Témaszín
      _SettingsSection(
        category: 'appearance',
        searchTerms: [
          'témaszín',
          'theme color',
          'szín',
          'color',
          'adaptív',
          'adaptive',
          'material you',
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: _ThemeColorPicker(
            isOpen: _themeColorOpen,
            onToggle: () => setState(() => _themeColorOpen = !_themeColorOpen),
            selectedColor: settings.adaptiveSeedColor,
            onColorSelected: (color) {
              _haptic();
              settings.update(adaptiveSeedColor: color?.value ?? 0);
              Provider.of<ThemeModeObserver>(context, listen: false)
                  .changeTheme(settings.theme, updateNavbarColor: false);
              setState(() {});
            },
          ),
        ),
      ),

      // Shadow effect
      _SettingsSection(
        category: 'appearance',
        searchTerms: ['árnyék', 'shadow', 'effect'],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () {
                  _haptic();
                  settings.update(shadowEffect: !settings.shadowEffect);
                  setState(() {});
                },
                title: Text("shadow_effect".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.shadowEffect ? .95 : .25))),
                leading: Icon(Icons.nightlight_round,
                    size: 22.0,
                    color: AppColors.of(context)
                        .text
                        .withValues(alpha: settings.shadowEffect ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) {
                    _haptic();
                    settings.update(shadowEffect: v);
                    setState(() {});
                  },
                  value: settings.shadowEffect,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Navbar order
      _SettingsSection(
        category: 'appearance',
        searchTerms: [
          'navbar',
          'navigáció',
          'navigation',
          'átrendezés',
          'reorder',
          'menü',
          'menu',
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              MenuNavbarOrder(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Rename subjects + teachers
      _SettingsSection(
        category: 'appearance',
        searchTerms: [
          'átnevezés',
          'rename',
          'tantárgy',
          'subject',
          'tanár',
          'teacher'
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () => _showRenamePickerPopup(),
                trailingDivider: true,
                title: Text("rename_subjects".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha:
                                settings.renamedSubjectsEnabled ? .95 : .25))),
                leading: Icon(Icons.school_outlined,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha: settings.renamedSubjectsEnabled ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) async {
                    _haptic();
                    settings.update(renamedSubjectsEnabled: v);
                    await _convertProviders();
                    setState(() {});
                  },
                  value: settings.renamedSubjectsEnabled,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0), bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () => _showRenamePickerPopup(),
                trailingDivider: true,
                title: Text("rename_teachers".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha:
                                settings.renamedTeachersEnabled ? .95 : .25))),
                leading: Icon(Icons.person_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha: settings.renamedTeachersEnabled ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) async {
                    _haptic();
                    settings.update(renamedTeachersEnabled: v);
                    await _convertProviders();
                    setState(() {});
                  },
                  value: settings.renamedTeachersEnabled,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Live activity color (iOS only)
      if (Platform.isIOS)
        _SettingsSection(
          category: 'appearance',
          searchTerms: ['live activity', 'szín', 'color'],
          widget: Padding(
            padding: const EdgeInsets.only(top: 9.0),
            child: SplittedPanel(
              cardPadding: const EdgeInsets.all(4.0),
              isSeparated: true,
              children: [
                PanelButton(
                  onPressed: () {
                    SettingsHelper.liveActivityColor(context);
                    setState(() {});
                  },
                  title: Text("live_activity_color".i18n,
                      style: TextStyle(
                          color: AppColors.of(context)
                              .text
                              .withValues(alpha: .95))),
                  leading: Icon(Icons.show_chart_rounded,
                      size: 22.0,
                      color: AppColors.of(context).text.withValues(alpha: .95)),
                  trailing: Container(
                    margin: const EdgeInsets.only(left: 2.0),
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: settings.liveActivityColor),
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                      bottom: Radius.circular(12.0)),
                ),
              ],
            ),
          ),
        ),

      // ── GRADES ───────────────────────────────────────────────

      // Rounding + Graph class average
      _SettingsSection(
        category: 'grades',
        searchTerms: [
          'kerekítés',
          'rounding',
          'átlag',
          'osztályátlag',
          'grafikon',
          'graph',
          'class avg'
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              _buildSliderCard(
                icon: Icons.commit_rounded,
                label: 'rounding'.i18n,
                valueText: (_tempRounding ?? settings.rounding / 10)
                    .toStringAsFixed(1),
                value: _tempRounding ?? settings.rounding / 10,
                min: 0.1,
                max: 0.9,
                divisions: 8,
                onChanged: (v) => setState(() => _tempRounding = v),
                onChangeEnd: (v) {
                  _haptic();
                  settings.update(rounding: (v * 10).toInt());
                  setState(() => _tempRounding = null);
                },
              ),
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () {
                  settings.update(graphClassAvg: !settings.graphClassAvg);
                  setState(() {});
                },
                title: Text("graph_class_avg".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.graphClassAvg ? .95 : .25))),
                leading: Icon(Icons.bar_chart_rounded,
                    size: 22.0,
                    color: AppColors.of(context)
                        .text
                        .withValues(alpha: settings.graphClassAvg ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) {
                    _haptic();
                    settings.update(graphClassAvg: v);
                  },
                  value: settings.graphClassAvg,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Surprise grades + Good student
      _SettingsSection(
        category: 'grades',
        searchTerms: [
          'meglepetés',
          'surprise',
          'jegy',
          'grade',
          'ritkaság',
          'jó tanuló',
          'goodstudent',
          'good student'
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: false,
            children: [
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () async {
                  SettingsHelper.surpriseGradeRarityText(
                    context,
                    title: 'rarity_title'.i18n,
                    cancel: 'cancel'.i18n,
                    done: 'done'.i18n,
                    rarities: [
                      "common".i18n,
                      "uncommon".i18n,
                      "rare".i18n,
                      "epic".i18n,
                      "legendary".i18n,
                    ],
                  );
                  setState(() {});
                },
                trailingDivider: true,
                title: Text("surprise_grades".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.gradeOpeningFun ? .95 : .25))),
                leading: Icon(Icons.card_giftcard_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha: settings.gradeOpeningFun ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) async {
                    _haptic();
                    settings.update(gradeOpeningFun: v);
                    setState(() {});
                  },
                  value: settings.gradeOpeningFun,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0), bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () async {
                  if (!settings.goodStudent) {
                    showDialog(
                      context: context,
                      builder: (context) => WillPopScope(
                        onWillPop: () async => false,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          title: Text("attention".i18n),
                          content: Text("goodstudent_disclaimer".i18n),
                          actions: [
                            ActionButton(
                              label: "understand".i18n,
                              onTap: () {
                                Navigator.of(context).pop();
                                settings.update(goodStudent: true);
                                Provider.of<GradeProvider>(context,
                                        listen: false)
                                    .convertBySettings();
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    settings.update(goodStudent: false);
                    Provider.of<GradeProvider>(context, listen: false)
                        .convertBySettings();
                    setState(() {});
                  }
                },
                title: Text("goodstudent".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.goodStudent ? .95 : .25))),
                leading: Icon(Icons.how_to_reg_rounded,
                    size: 22.0,
                    color: AppColors.of(context)
                        .text
                        .withValues(alpha: settings.goodStudent ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) async {
                    if (v) {
                      showDialog(
                        context: context,
                        builder: (context) => WillPopScope(
                          onWillPop: () async => false,
                          child: AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            title: Text("attention".i18n),
                            content: Text("goodstudent_disclaimer".i18n),
                            actions: [
                              ActionButton(
                                label: "understand".i18n,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  settings.update(goodStudent: true);
                                  Provider.of<GradeProvider>(context,
                                          listen: false)
                                      .convertBySettings();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      settings.update(goodStudent: false);
                      Provider.of<GradeProvider>(context, listen: false)
                          .convertBySettings();
                      setState(() {});
                    }
                  },
                  value: settings.goodStudent,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // ── OTHER ────────────────────────────────────────────────

      // Presentation mode
      _SettingsSection(
        category: 'other',
        searchTerms: [
          'bemutató',
          'presentation',
          'privacy',
          'adatok elrejtése'
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            isSeparated: true,
            children: [
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () async {
                  _haptic();
                  settings.update(presentationMode: !settings.presentationMode);
                  setState(() {});
                },
                title: Text("presentation".i18n,
                    style: TextStyle(
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.presentationMode ? .95 : .25))),
                leading: Icon(Icons.tv_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(
                        alpha: settings.presentationMode ? .95 : .25)),
                trailing: Switch(
                  onChanged: (v) async {
                    _haptic();
                    settings.update(presentationMode: v);
                    setState(() {});
                  },
                  value: settings.presentationMode,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),

      // Analytics + Feedback
      _SettingsSection(
        category: 'other',
        searchTerms: [
          'analitika',
          'analytics',
          'visszajelzés',
          'feedback',
          'hibajelentés'
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            cardPadding: const EdgeInsets.all(4.0),
            children: [
              Tooltip(
                message: "data_collected".i18n,
                padding: const EdgeInsets.all(4.0),
                margin: const EdgeInsets.all(10.0),
                textStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).text),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 40.0)
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.only(left: 14.0, right: 4.0),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12.0),
                            bottom: Radius.circular(4.0))),
                    secondary: Icon(Icons.bar_chart_rounded,
                        size: 22.0,
                        color: settings.analyticsEnabled
                            ? AppColors.of(context).text.withValues(alpha: 0.95)
                            : AppColors.of(context)
                                .text
                                .withValues(alpha: .25)),
                    title: Text(
                      "Analytics".i18n,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                        color: AppColors.of(context).text.withValues(
                            alpha: settings.analyticsEnabled ? 1.0 : .5),
                      ),
                    ),
                    subtitle: Text(
                      "Anonymous Usage Analytics".i18n,
                      style: TextStyle(
                          color: AppColors.of(context).text.withValues(
                              alpha: settings.analyticsEnabled ? .5 : .2)),
                    ),
                    onChanged: (v) {
                      _haptic();
                      settings.update(analyticsEnabled: v);
                    },
                    value: settings.analyticsEnabled,
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // About
      _SettingsSection(
        category: 'other',
        searchTerms: [
          'adatvédelem',
          'privacy',
          'discord',
          'github',
          'licenc',
          'license',
          'névjegy',
          'about'
        ],
        widget: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: SplittedPanel(
            title: Text("about".i18n),
            cardPadding: const EdgeInsets.all(4.0),
            children: [
              PanelButton(
                leading: Icon(Icons.lock_outline_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: 0.95)),
                title: Text("privacy".i18n),
                onPressed: () => _openPrivacy(context),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0), bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                leading: Icon(Icons.alternate_email_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: 0.95)),
                title: const Text("Discord"),
                onPressed: () => launchUrl(
                    Uri.parse("https://discord.gg/6DvjyPAw2T"),
                    mode: LaunchMode.externalApplication),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0), bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                leading: Icon(Icons.code_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: 0.95)),
                title: const Text("GitHub"),
                onPressed: () => launchUrl(
                    Uri.parse("https://github.com/zan1456/folio"),
                    mode: LaunchMode.externalApplication),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0), bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                leading: Icon(Icons.emoji_events_rounded,
                    size: 22.0,
                    color: AppColors.of(context).text.withValues(alpha: 0.95)),
                title: Text("licenses".i18n),
                onPressed: () => showLicensePage(context: context),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0), bottom: Radius.circular(12.0)),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _openPrivacy(BuildContext context) => PrivacyView.show(context);
}

// ── Inline Theme Color Picker ─────────────────────────────────────────────

class _ThemeColorPicker extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final Color? selectedColor;
  final void Function(Color?) onColorSelected;

  const _ThemeColorPicker({
    required this.isOpen,
    required this.onToggle,
    required this.selectedColor,
    required this.onColorSelected,
  });

  // Colors in hue order (spectrum: red → pink)
  static const List<Color> _colors = [
    Color(0xFFEF5350), // red
    Color(0xFFFF7043), // deep orange
    Color(0xFFFFA726), // orange
    Color(0xFFFFCA28), // amber
    Color(0xFFD4E157), // lime
    Color(0xFF66BB6A), // green
    Color(0xFF26A69A), // teal
    Color(0xFF29B6F6), // light blue
    Color(0xFF42A5F5), // blue
    Color(0xFF5C6BC0), // indigo
    Color(0xFF7E57C2), // deep purple
    Color(0xFFAB47BC), // purple
    Color(0xFFEC407A), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFF78909C), // blue grey
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.of(context).text;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isSystem = selectedColor == null;

    return SplittedPanel(
      cardPadding: const EdgeInsets.all(4.0),
      isSeparated: false,
      children: [
        PanelButton(
          onPressed: onToggle,
          title: Text(
            'material_you_color'.i18n,
            style: TextStyle(color: textColor.withValues(alpha: .95)),
          ),
          leading: Icon(Icons.color_lens_outlined,
              size: 22.0, color: textColor.withValues(alpha: .95)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.0,
                height: 12.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6.0),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20.0, color: textColor.withValues(alpha: .6)),
              ),
            ],
          ),
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(12.0),
            bottom: Radius.circular(isOpen ? 4.0 : 12.0),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: isOpen
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12.0)),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        // System (reset) option
                        _ColorDot(
                          color: Theme.of(context).colorScheme.primary,
                          isSelected: isSystem,
                          isSystem: true,
                          onTap: () => onColorSelected(null),
                          accentColor: accentColor,
                        ),
                        const SizedBox(width: 8.0),
                        // Divider
                        Container(
                          width: 1.5,
                          height: 32.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: textColor.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(1.0),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Color circles
                        for (final c in _colors) ...[
                          _ColorDot(
                            color: c,
                            isSelected: !isSystem &&
                                selectedColor != null &&
                                selectedColor!.value == c.value,
                            isSystem: false,
                            onTap: () => onColorSelected(c),
                            accentColor: accentColor,
                          ),
                          const SizedBox(width: 8.0),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final bool isSystem;
  final VoidCallback onTap;
  final Color accentColor;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.isSystem,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36.0,
        height: 36.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border:
              isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
        ),
        child: isSystem
            ? Icon(Icons.smartphone_rounded,
                size: 18.0,
                color: color.computeLuminance() > 0.4
                    ? Colors.black54
                    : Colors.white70)
            : isSelected
                ? const Icon(Icons.check_rounded,
                    size: 18.0, color: Colors.white)
                : null,
      ),
    );
  }
}
