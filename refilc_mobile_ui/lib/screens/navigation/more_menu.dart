import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refilc/api/providers/user_provider.dart';
import 'package:refilc/models/settings.dart';
import 'package:refilc_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:refilc_mobile_ui/common/profile_image/profile_image.dart';
import 'package:refilc_mobile_ui/common/screens.i18n.dart';
import 'package:refilc_mobile_ui/pages/absences/absences_page.dart';
import 'package:refilc_mobile_ui/pages/messages/messages_page.dart';
import 'package:refilc_mobile_ui/pages/notes/notes_page.dart';
import 'package:refilc_mobile_ui/screens/settings/profile_screen.dart';
import 'package:refilc_mobile_ui/screens/settings/settings_screen.dart';

class MoreMenu extends StatelessWidget {
  const MoreMenu({super.key, required this.outsideContext});

  final BuildContext outsideContext;

  static void show(BuildContext context) {
    showRoundedModalBottomSheet(
      context,
      showHandle: true,
      child: MoreMenu(outsideContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    final firstName = settings.presentationMode
        ? "János"
        : (() {
            final parts = user.displayName?.split(" ") ?? ["?"];
            return parts.length > 1 ? parts[1] : parts[0];
          })();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile hero card with gradient
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(outsideContext, rootNavigator: true).push(
                CupertinoPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(28.0),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  ProfileImage(
                    heroTag: "profile-more",
                    name: firstName,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.2),
                    badge: false,
                    role: user.role,
                    profilePictureString: user.picture,
                    gradeStreak: (user.gradeStreak ?? 0) > 1,
                    radius: 28.0,
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.presentationMode
                              ? "Teszt János"
                              : (user.displayName ?? ""),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          "profile".i18n,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.65),
                            fontSize: 13.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.5),
                    size: 20.0,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // Action cards row
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: "messages".i18n,
                  color: colorScheme.secondaryContainer,
                  iconColor: colorScheme.onSecondaryContainer,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(outsideContext, rootNavigator: true).push(
                      CupertinoPageRoute(
                          builder: (_) => const MessagesPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _ActionCard(
                  icon: Icons.person_off_rounded,
                  title: "absences".i18n,
                  color: colorScheme.tertiaryContainer,
                  iconColor: colorScheme.onTertiaryContainer,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(outsideContext, rootNavigator: true).push(
                      CupertinoPageRoute(
                          builder: (_) => const AbsencesPage()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _ActionCard(
                  icon: Icons.menu_book_rounded,
                  title: "notes".i18n,
                  color: colorScheme.primaryContainer,
                  iconColor: colorScheme.onPrimaryContainer,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(outsideContext, rootNavigator: true).push(
                      CupertinoPageRoute(builder: (_) => const NotesPage()),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Settings button
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(outsideContext, rootNavigator: true).push(
                CupertinoPageRoute(
                    builder: (context) => const SettingsScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22.0),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 18.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      size: 22.0,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      "settings".i18n,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20.0,
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90.0,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28.0, color: iconColor),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: iconColor,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
