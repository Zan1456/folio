// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as tabs;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:refilc/api/providers/database_provider.dart';
import 'package:refilc/api/providers/user_provider.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc/models/user.dart';
import 'package:refilc_kreta_api/client/client.dart';
import 'package:refilc_kreta_api/providers/absence_provider.dart';
import 'package:refilc_kreta_api/providers/event_provider.dart';
import 'package:refilc_kreta_api/providers/exam_provider.dart';
import 'package:refilc_kreta_api/providers/grade_provider.dart';
import 'package:refilc_kreta_api/providers/homework_provider.dart';
import 'package:refilc_kreta_api/providers/message_provider.dart';
import 'package:refilc_kreta_api/providers/note_provider.dart';
import 'package:refilc_kreta_api/providers/timetable_provider.dart';
import 'package:refilc_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu.dart';
import 'package:refilc_mobile_ui/common/profile_image/profile_image.dart';
import 'package:refilc_mobile_ui/screens/settings/accounts/account_tile.dart';
import 'package:refilc_mobile_ui/screens/settings/settings_helper.dart';
import 'package:refilc_mobile_ui/screens/settings/user/nickname.dart';
import 'package:refilc_mobile_ui/screens/settings/user/profile_pic.dart';
import 'profile_screen.i18n.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  late UserProvider user;
  late SettingsProvider settings;
  late KretaClient kretaClient;
  List<Widget> accountTiles = [];

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

  void buildAccountTiles() {
    accountTiles = [];
    user.getUsers().forEach((account) {
      if (account.id == user.id) return;

      String firstName;
      List<String> nameParts =
          (account.nickname != '' ? account.nickname : account.displayName)
              .split(" ");
      if (!settings.presentationMode) {
        firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];
      } else {
        firstName = "János";
      }

      accountTiles.add(
        AccountTile(
          name: Text(
              !settings.presentationMode
                  ? (account.nickname != '' ? account.nickname : account.name)
                  : "János",
              style: const TextStyle(fontWeight: FontWeight.w500)),
          username: Text(
              !settings.presentationMode ? account.username : "01234567890"),
          profileImage: ProfileImage(
            name: firstName,
            role: account.role,
            profilePictureString: account.picture,
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
          onTap: () async {
            user.setUser(account.id);

            String? err = await refresh();
            if (err != null) {
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
                        await Provider.of<DatabaseProvider>(context,
                                listen: false)
                            .store
                            .removeUser(userId);

                        if (user.getUsers().isNotEmpty) {
                          user.setUser(user.getUsers().first.id);
                          restore().then(
                              (_) => user.setUser(user.getUsers().first.id));
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
          },
          onTapMenu: () => _showEditBottomSheet(account),
        ),
      );
    });
  }

  void _showEditBottomSheet(User u) {
    showBottomSheetMenu(context, items: [
      UserMenuNickname(u),
      UserMenuProfilePic(u),
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

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    settings = Provider.of<SettingsProvider>(context);
    kretaClient = Provider.of<KretaClient>(context, listen: false);

    final colorScheme = Theme.of(context).colorScheme;
    final student = user.student;

    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    final firstName = settings.presentationMode
        ? "János"
        : (nameParts.length > 1 ? nameParts[1] : nameParts[0]);
    final displayName = settings.presentationMode
        ? "Teszt János"
        : (user.displayName ?? "?");
    final username = settings.presentationMode ? "01234567890" : (user.name ?? "");

    buildAccountTiles();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top > 0 ? 8.0 : 20.0,
                left: 20.0,
                right: 20.0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18.0,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    "profile".i18n,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24.0),

                  // Hero profile card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showEditBottomSheet(user.getUser(user.id ?? "")),
                          child: ProfileImage(
                            heroTag: "profile",
                            radius: 52.0,
                            name: firstName,
                            role: user.role,
                            profilePictureString: user.picture,
                            gradeStreak: (user.gradeStreak ?? 0) > 1,
                            backgroundColor: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        GestureDetector(
                          onTap: () => _showEditBottomSheet(user.getUser(user.id ?? "")),
                          child: Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onPrimaryContainer,
                            ),
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

                  const SizedBox(height: 16.0),

                  // Personal info section
                  if (student != null) ...[
                    _ProfileSection(
                      label: "personal_info".i18n,
                      color: colorScheme.secondaryContainer,
                      labelColor: colorScheme.onSecondaryContainer,
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.cake_rounded,
                            label: "birthdate".i18n,
                            value: DateFormat("yyyy. MM. dd.").format(student.birth),
                            accentColor: colorScheme.onSecondaryContainer,
                            isLast: student.className == null &&
                                student.address == null &&
                                student.parents.isEmpty &&
                                student.gradeDelay == 0,
                          ),
                          _InfoRow(
                            icon: Icons.school_rounded,
                            label: "school".i18n,
                            value: student.school.name,
                            accentColor: colorScheme.onSecondaryContainer,
                            isLast: student.className == null &&
                                student.address == null &&
                                student.parents.isEmpty &&
                                student.gradeDelay == 0,
                          ),
                          if (student.className != null)
                            _InfoRow(
                              icon: Icons.grid_view_rounded,
                              label: "class".i18n,
                              value: student.className!,
                              accentColor: colorScheme.onSecondaryContainer,
                              isLast: student.address == null &&
                                  student.parents.isEmpty &&
                                  student.gradeDelay == 0,
                            ),
                          if (student.address != null)
                            _InfoRow(
                              icon: Icons.location_on_rounded,
                              label: "address".i18n,
                              value: student.address!,
                              accentColor: colorScheme.onSecondaryContainer,
                              isLast: student.parents.isEmpty &&
                                  student.gradeDelay == 0,
                            ),
                          if (student.parents.isNotEmpty)
                            _InfoRow(
                              icon: Icons.group_rounded,
                              label: "parents".i18n,
                              value: student.parents.join(", "),
                              accentColor: colorScheme.onSecondaryContainer,
                              isLast: student.gradeDelay == 0,
                            ),
                          if (student.gradeDelay > 0)
                            _InfoRow(
                              icon: Icons.schedule_rounded,
                              label: "grade_delay".i18n,
                              value: "hrs".i18n.fill([student.gradeDelay]),
                              accentColor: colorScheme.onSecondaryContainer,
                              isLast: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],

                  // Account actions section
                  _ProfileSection(
                    label: "account".i18n,
                    color: colorScheme.tertiaryContainer,
                    labelColor: colorScheme.onTertiaryContainer,
                    child: Column(
                      children: [
                        _ActionRow(
                          icon: Icons.open_in_new_rounded,
                          label: "open_dkt".i18n,
                          accentColor: colorScheme.onTertiaryContainer,
                          isLast: false,
                          onTap: _openDKT,
                        ),
                        _ActionRow(
                          icon: Icons.edit_rounded,
                          label: "edit".i18n,
                          subtitle: "edit_desc".i18n,
                          accentColor: colorScheme.onTertiaryContainer,
                          isLast: false,
                          onTap: () => _showEditBottomSheet(
                              user.getUser(user.id ?? "")),
                        ),
                        _ActionRow(
                          icon: Icons.swap_horiz_rounded,
                          label: "switch_account".i18n,
                          accentColor: colorScheme.onTertiaryContainer,
                          isLast: false,
                          onTap: () {
                            SettingsHelper.changeCurrentUser(
                              context,
                              accountTiles,
                              accountTiles.length + 2,
                              "add_user".i18n,
                            );
                          },
                        ),
                        _ActionRow(
                          icon: Icons.logout_rounded,
                          label: "log_out".i18n,
                          accentColor: colorScheme.error,
                          isLast: true,
                          destructive: true,
                          onTap: () async {
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
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil("login", (_) => false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 32.0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.label,
    required this.color,
    required this.labelColor,
    required this.child,
  });

  final String label;
  final Color color;
  final Color labelColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 13.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.0,
            color: accentColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accentColor,
    this.subtitle,
    this.isLast = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isLast;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor =
        destructive ? colorScheme.error : colorScheme.onSurface;
    final iconColor = destructive ? colorScheme.error : accentColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, size: 22.0, color: iconColor.withValues(alpha: 0.85)),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.0,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
