// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as tabs;
import 'package:image_crop_plus/image_crop_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/models/user.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/event_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu_item.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';
import 'package:folio_mobile_ui/common/profile_image/profile_image.dart';
import 'package:folio_mobile_ui/common/splitted_panel/splitted_panel.dart';
import 'package:folio_mobile_ui/screens/settings/accounts/account_tile.dart';
import 'profile_screen.i18n.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late UserProvider user;
  late SettingsProvider settings;
  late KretaClient kretaClient;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> restore() => Future.wait([
        Provider.of<GradeProvider>(context, listen: false).restore(),
        Provider.of<TimetableProvider>(context, listen: false).restoreUser(),
        Provider.of<ExamProvider>(context, listen: false).restore(),
        Provider.of<HomeworkProvider>(context, listen: false).restore(),
        Provider.of<MessageProvider>(context, listen: false).restore(),
        Provider.of<MessageProvider>(context, listen: false).restoreRecipients(),
        Provider.of<NoteProvider>(context, listen: false).restore(),
        Provider.of<EventProvider>(context, listen: false).restore(),
        Provider.of<AbsenceProvider>(context, listen: false).restore(),
      ]);

  Future<String?> refresh() =>
      Provider.of<KretaClient>(context, listen: false).refreshLogin();

  void _editNickname(User u) {
    showRoundedModalBottomSheet(
      context,
      child: _NicknameBottomSheet(u: u),
    );
  }

  void _editProfilePic(User u) {
    showRoundedModalBottomSheet(
      context,
      child: _ProfilePicBottomSheet(u: u),
    );
  }

  void _showAccountRemoveSheet(User account) {
    final colorScheme = Theme.of(context).colorScheme;
    showBottomSheetMenu(context, items: [
      BottomSheetMenuItem(
        icon: Icon(Icons.delete_rounded, color: colorScheme.error),
        title: Text(
          "remove_account".i18n,
          style: TextStyle(color: colorScheme.error),
        ),
        onPressed: () async {
          Navigator.of(context).pop();
          user.removeUser(account.id);
          await Provider.of<DatabaseProvider>(context, listen: false)
              .store
              .removeUser(account.id);
        },
      ),
    ]);
  }

  void _openDKT() => tabs.launchUrl(
        Uri.parse(
            "https://dkttanulo.e-kreta.hu/sso?id_token=${kretaClient.idToken}"),
        customTabsOptions: tabs.CustomTabsOptions(
          showTitle: true,
          colorSchemes: tabs.CustomTabsColorSchemes(
            defaultPrams: tabs.CustomTabsColorSchemeParams(
              toolbarColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ),
      );

  Future<void> _switchAccount(User account) async {
    user.setUser(account.id);

    kretaClient.accessToken = account.accessToken;
    kretaClient.refreshToken = account.refreshToken;
    kretaClient.idpApplicationCookie = account.idpApplication;

    final String? result = await refresh();

    if (result != 'success') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0)),
          title: Text('oopsie'.i18n),
          content: Text('session_expired'.i18n),
          actions: [
            TextButton(
              onPressed: () async {
                String? userId = user.id;
                if (userId == null) return;
                user.removeUser(userId);
                await Provider.of<DatabaseProvider>(context, listen: false)
                    .store
                    .removeUser(userId);
                if (user.getUsers().isNotEmpty) {
                  user.setUser(user.getUsers().first.id);
                  restore()
                      .then((_) => user.setUser(user.getUsers().first.id));
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed("login_back");
                } else {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil("login", (_) => false);
                }
              },
              child: const Text("Ok"),
            ),
          ],
        ),
      );
      return;
    }

    restore().then((_) => user.setUser(account.id));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    settings = Provider.of<SettingsProvider>(context);
    kretaClient = Provider.of<KretaClient>(context, listen: false);

    final colorScheme = Theme.of(context).colorScheme;
    final student = user.student;

    final List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    final String firstName = settings.presentationMode
        ? "János"
        : (nameParts.length > 1 ? nameParts[1] : nameParts[0]);
    final String displayName = settings.presentationMode
        ? "Teszt János"
        : (user.displayName ?? "?");
    final String username =
        settings.presentationMode ? "01234567890" : (user.name ?? "");

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28.0)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.0,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            "profile".i18n,
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) => TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      labelColor: colorScheme.secondary,
                      unselectedLabelColor: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.65),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 13.5),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 6.0),
                      indicator: BoxDecoration(
                        color:
                            colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      overlayColor: WidgetStateProperty.all(
                        colorScheme.secondary.withValues(alpha: 0.08),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                          12.0, 8.0, 12.0, 14.0),
                      tabs: [
                        Tab(text: "profile".i18n),
                        Tab(text: "your_data".i18n),
                        Tab(text: "accounts".i18n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfilTab(
                    context, colorScheme, firstName, displayName, username),
                _buildAdataidTab(context, colorScheme, student),
                _buildFiokokTab(
                    context, colorScheme, firstName, displayName, username),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 0: Profil ────────────────────────────────────────────────────────

  Widget _buildProfilTab(BuildContext context, ColorScheme colorScheme,
      String firstName, String displayName, String username) {
    final currentUser = user.getUser(user.id ?? "");

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16.0),

          // Hero card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(28.0),
              ),
              child: Column(
                children: [
                  ProfileImage(
                    heroTag: "profile",
                    radius: 52.0,
                    name: firstName,
                    role: user.role,
                    profilePictureString: user.picture,
                    gradeStreak: (user.gradeStreak ?? 0) > 1,
                    backgroundColor: colorScheme.primary,
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if ((user.gradeStreak ?? 0) > 1) ...[
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/apple_fire_emoji.png',
                            width: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            "${user.gradeStreak} ${"grade_streak_subtitle".i18n}",
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // Edit panel: profile pic + nickname + DKT
          SplittedPanel(
            padding: const EdgeInsets.only(
                bottom: 0.0, left: 24.0, right: 24.0),
            cardPadding: const EdgeInsets.all(4.0),
            children: [
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () => _editProfilePic(currentUser),
                leading: Icon(
                  Icons.camera_alt_rounded,
                  size: 22.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.85),
                ),
                title: Text("edit_profile_picture".i18n),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.3),
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                    bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () => _editNickname(currentUser),
                leading: Icon(
                  Icons.edit_rounded,
                  size: 22.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.85),
                ),
                title: Text("edit_nickname".i18n),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.3),
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0),
                    bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: _openDKT,
                leading: Icon(
                  Icons.open_in_new_rounded,
                  size: 22.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.85),
                ),
                title: Text("open_dkt".i18n),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.3),
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0),
                    bottom: Radius.circular(12.0)),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24.0),
        ],
      ),
    );
  }

  // ── Tab 1: Adataid ───────────────────────────────────────────────────────

  Widget _buildAdataidTab(
      BuildContext context, ColorScheme colorScheme, dynamic student) {
    if (student == null) {
      return Center(
        child: Text(
          "—",
          style: TextStyle(
              fontSize: 15.0,
              color: colorScheme.onSurface.withValues(alpha: 0.35)),
        ),
      );
    }

    final List<_InfoItem> items = [
      _InfoItem(
        icon: Icons.cake_rounded,
        label: "birthdate".i18n,
        value: DateFormat("yyyy. MM. dd.").format(student.birth),
      ),
      _InfoItem(
        icon: Icons.school_rounded,
        label: "school".i18n,
        value: student.school.name,
      ),
      if (student.className != null)
        _InfoItem(
          icon: Icons.grid_view_rounded,
          label: "class".i18n,
          value: student.className!,
        ),
      if (student.address != null)
        _InfoItem(
          icon: Icons.location_on_rounded,
          label: "address".i18n,
          value: student.address!,
        ),
      if (student.parents.isNotEmpty)
        _InfoItem(
          icon: Icons.group_rounded,
          label: "parents".i18n,
          value: student.parents.join(", "),
        ),
      if (student.gradeDelay > 0)
        _InfoItem(
          icon: Icons.schedule_rounded,
          label: "grade_delay".i18n,
          value: "hrs".i18n.fill([student.gradeDelay]),
        ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8.0),
          _sectionHeader(context, "personal_info".i18n),
          SplittedPanel(
            padding: const EdgeInsets.only(
                bottom: 0.0, left: 24.0, right: 24.0),
            cardPadding: const EdgeInsets.all(4.0),
            children: [
              for (int i = 0; i < items.length; i++)
                _buildInfoButton(context, items[i], i, items.length),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24.0),
        ],
      ),
    );
  }

  Widget _buildInfoButton(
      BuildContext context, _InfoItem item, int index, int total) {
    return PanelButton(
      padding: const EdgeInsets.only(left: 14.0, right: 14.0),
      onPressed: null,
      leading: Icon(
        item.icon,
        size: 22.0,
        color: AppColors.of(context).text.withValues(alpha: 0.65),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.of(context).text.withValues(alpha: 0.5),
            ),
          ),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).text,
            ),
          ),
        ],
      ),
      borderRadius: _itemRadius(index, total),
    );
  }

  // ── Tab 2: Fiókok ────────────────────────────────────────────────────────

  Widget _buildFiokokTab(BuildContext context, ColorScheme colorScheme,
      String firstName, String displayName, String username) {
    final currentUser = user.getUser(user.id ?? "");
    final otherAccounts =
        user.getUsers().where((a) => a.id != user.id).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8.0),

          _sectionHeader(context, "account".i18n),
          SplittedPanel(
            padding: const EdgeInsets.only(
                bottom: 0.0, left: 24.0, right: 24.0),
            cardPadding: const EdgeInsets.all(4.0),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: AccountTile(
                  name: Text(displayName,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                  username: Text(username),
                  profileImage: ProfileImage(
                    name: firstName,
                    role: user.role,
                    profilePictureString: user.picture,
                    backgroundColor: colorScheme.primary,
                  ),
                  onTapMenu: () => _showAccountRemoveSheet(currentUser),
                ),
              ),
            ],
          ),

          if (otherAccounts.isNotEmpty) ...[
            const SizedBox(height: 4.0),
            _sectionHeader(context, "switch_account".i18n),
            SplittedPanel(
              padding: const EdgeInsets.only(
                  bottom: 0.0, left: 24.0, right: 24.0),
              cardPadding: const EdgeInsets.all(4.0),
              children: [
                for (int i = 0; i < otherAccounts.length; i++)
                  _buildOtherAccountItem(context, colorScheme,
                      otherAccounts[i], i, otherAccounts.length),
              ],
            ),
          ],

          const SizedBox(height: 4.0),

          SplittedPanel(
            padding: const EdgeInsets.only(
                bottom: 0.0, left: 24.0, right: 24.0),
            cardPadding: const EdgeInsets.all(4.0),
            children: [
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () =>
                    Navigator.of(context).pushNamed("login_back"),
                leading: Icon(
                  Icons.person_add_rounded,
                  size: 22.0,
                  color: AppColors.of(context)
                      .text
                      .withValues(alpha: 0.85),
                ),
                title: Text("add_user".i18n),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20.0,
                  color: AppColors.of(context)
                      .text
                      .withValues(alpha: 0.3),
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12.0),
                    bottom: Radius.circular(4.0)),
              ),
              PanelButton(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                onPressed: () async {
                  String? userId = user.id;
                  if (userId == null) return;
                  user.removeUser(userId);
                  await Provider.of<DatabaseProvider>(context,
                          listen: false)
                      .store
                      .removeUser(userId);
                  if (user.getUsers().isNotEmpty) {
                    user.setUser(user.getUsers().first.id);
                    restore().then(
                        (_) => user.setUser(user.getUsers().first.id));
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        "login", (_) => false);
                  }
                },
                leading: Icon(
                  Icons.logout_rounded,
                  size: 22.0,
                  color: colorScheme.error.withValues(alpha: 0.85),
                ),
                title: Text(
                  "log_out".i18n,
                  style: TextStyle(color: colorScheme.error),
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4.0),
                    bottom: Radius.circular(12.0)),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24.0),
        ],
      ),
    );
  }

  Widget _buildOtherAccountItem(BuildContext context,
      ColorScheme colorScheme, User account, int index, int total) {
    final List<String> nameParts =
        (account.nickname.isNotEmpty
                ? account.nickname
                : account.displayName)
            .split(" ");
    final String firstName = settings.presentationMode
        ? "János"
        : (nameParts.length > 1 ? nameParts[1] : nameParts[0]);

    return ClipRRect(
      borderRadius: _itemRadius(index, total),
      child: AccountTile(
        name: Text(
          settings.presentationMode
              ? "János"
              : (account.nickname.isNotEmpty
                  ? account.nickname
                  : account.name),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        username: Text(
          settings.presentationMode ? "01234567890" : account.username,
        ),
        profileImage: ProfileImage(
          name: firstName,
          role: account.role,
          profilePictureString: account.picture,
          backgroundColor: colorScheme.tertiary,
        ),
        onTap: () => _switchAccount(account),
        onTapMenu: () => _showAccountRemoveSheet(account),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 10.0, bottom: 6.0, left: 28.0),
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
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _itemRadius(int index, int total) {
    if (total == 1) return BorderRadius.circular(12.0);
    if (index == 0) {
      return const BorderRadius.vertical(
          top: Radius.circular(12.0), bottom: Radius.circular(4.0));
    }
    if (index == total - 1) {
      return const BorderRadius.vertical(
          top: Radius.circular(4.0), bottom: Radius.circular(12.0));
    }
    return BorderRadius.circular(4.0);
  }
}

// ── Info item model ───────────────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(
      {required this.icon, required this.label, required this.value});
}

// ── Nickname bottom sheet ─────────────────────────────────────────────────────

class _NicknameBottomSheet extends StatefulWidget {
  const _NicknameBottomSheet({required this.u});
  final User u;

  @override
  State<_NicknameBottomSheet> createState() => _NicknameBottomSheetState();
}

class _NicknameBottomSheetState extends State<_NicknameBottomSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.u.nickname);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 4.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "edit_nickname".i18n,
              style: const TextStyle(
                  fontSize: 17.0, fontWeight: FontWeight.w700),
            ),
          ),
          TextField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh,
              hintText: widget.u.name,
              suffixIcon: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18.0),
                onPressed: () => setState(() => _ctrl.text = ""),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text("cancel".i18n,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8.0),
              FilledButton(
                child: Text("done".i18n),
                onPressed: () {
                  widget.u.nickname = _ctrl.text.trim();
                  Provider.of<DatabaseProvider>(context, listen: false)
                      .store
                      .storeUser(widget.u);
                  Provider.of<UserProvider>(context, listen: false)
                      .refresh();
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Profile picture bottom sheet ──────────────────────────────────────────────

class _ProfilePicBottomSheet extends StatefulWidget {
  const _ProfilePicBottomSheet({required this.u});
  final User u;

  @override
  State<_ProfilePicBottomSheet> createState() =>
      _ProfilePicBottomSheetState();
}

class _ProfilePicBottomSheetState extends State<_ProfilePicBottomSheet> {
  final cropKey = GlobalKey<CropState>();
  File? _file;
  File? _sample;
  File? _lastCropped;

  Future<void> _pickImage() async {
    try {
      final picked =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final imageFile = File(picked.path);
      final sample = await ImageCrop.sampleImage(
        file: imageFile,
        preferredSize: MediaQuery.of(context).size.longestSide.ceil(),
      );
      _sample?.delete();
      _file?.delete();
      setState(() {
        _sample = sample;
        _file = imageFile;
      });
    } on PlatformException catch (e) {
      log('Failed to pick image: $e');
    }
  }

  Future<void> _cropAndSave() async {
    final scale = cropKey.currentState!.scale;
    final area = cropKey.currentState!.area;
    if (area == null || _file == null) return;

    final sample = await ImageCrop.sampleImage(
      file: _file!,
      preferredSize: (2000 / scale).round(),
    );
    final file = await ImageCrop.cropImage(file: sample, area: area);
    sample.delete();
    _lastCropped?.delete();
    _lastCropped = file;

    final bytes = await _lastCropped!.readAsBytes();
    widget.u.picture = base64Encode(bytes);
    if (!mounted) return;
    Provider.of<DatabaseProvider>(context, listen: false)
        .store
        .storeUser(widget.u);
    Provider.of<UserProvider>(context, listen: false).refresh();
  }

  @override
  void dispose() {
    _file?.delete();
    _sample?.delete();
    _lastCropped?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              "edit_profile_picture".i18n,
              style: const TextStyle(
                  fontSize: 17.0, fontWeight: FontWeight.w700),
            ),
          ),

          // Crop or pick
          if (_sample != null)
            SizedBox(
              height: 280.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Crop.file(
                  _sample!,
                  key: cropKey,
                  aspectRatio: 1.0,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 32.0, horizontal: 8.0),
                child: Column(
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 36.0,
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 8.0),
                    Text(
                      "select_profile_picture".i18n,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12.0),

          Row(
            children: [
              // Remove picture
              if (widget.u.picture.isNotEmpty)
                TextButton(
                  child: Text(
                    "remove_profile_picture".i18n,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.error),
                  ),
                  onPressed: () {
                    widget.u.picture = "";
                    Provider.of<DatabaseProvider>(context, listen: false)
                        .store
                        .storeUser(widget.u);
                    Provider.of<UserProvider>(context, listen: false)
                        .refresh();
                    Navigator.of(context).pop(true);
                  },
                ),
              const Spacer(),
              TextButton(
                child: Text("cancel".i18n,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8.0),
              FilledButton(
                child: Text("done".i18n),
                onPressed: () async {
                  if (_sample != null) await _cropAndSave();
                  if (mounted) Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
