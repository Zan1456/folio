import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';
import 'package:folio_mobile_ui/common/screens.i18n.dart';
import 'package:folio_mobile_ui/screens/settings/settings_screen.i18n.dart';
import 'package:provider/provider.dart';

// Helpers to avoid ambiguous .i18n extension conflict
String _s(String key) => SettingsLocalization(key).i18n;
String _p(String key) => ScreensLocalization(key).i18n;

class MenuNavbarOrder extends StatelessWidget {
  const MenuNavbarOrder({
    super.key,
    this.borderRadius = const BorderRadius.vertical(
        top: Radius.circular(4.0), bottom: Radius.circular(4.0)),
  });

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return PanelButton(
      onPressed: () => showRoundedModalBottomSheet(
        context,
        showHandle: true,
        child: const _NavbarOrderSheet(),
      ),
      title: Text(_s("navbar_order")),
      leading: Icon(
        Icons.view_list_rounded,
        size: 22.0,
        color: AppColors.of(context).text.withValues(alpha: 0.95),
      ),
      trailing: Icon(
        Icons.keyboard_arrow_right_rounded,
        size: 22.0,
        color: AppColors.of(context).text.withValues(alpha: 0.95),
      ),
      borderRadius: borderRadius,
    );
  }
}

class _NavbarOrderSheet extends StatefulWidget {
  const _NavbarOrderSheet();

  @override
  _NavbarOrderSheetState createState() => _NavbarOrderSheetState();
}

class _NavbarOrderSheetState extends State<_NavbarOrderSheet> {
  static const _allPages = [
    "home",
    "grades",
    "timetable",
    "messages",
    "absences",
    "notes",
  ];

  static const int _maxNavbarItems = 4;

  late List<String> _navbarItems;
  late List<String> _moreItems;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _navbarItems = List<String>.from(settings.navbarOrder)
        .where((p) => _allPages.contains(p))
        .toList();
    _moreItems = _allPages.where((p) => !_navbarItems.contains(p)).toList();
  }

  void _save() {
    Provider.of<SettingsProvider>(context, listen: false)
        .update(navbarOrder: jsonEncode(_navbarItems));
  }

  IconData _pageIcon(String page) {
    switch (page) {
      case "home":
        return Icons.today_rounded;
      case "grades":
        return Icons.school_rounded;
      case "timetable":
        return Icons.calendar_today_rounded;
      case "messages":
        return Icons.chat_bubble_outline_rounded;
      case "absences":
        return Icons.person_off_rounded;
      case "notes":
        return Icons.menu_book_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  void _moveToNavbar(String page) {
    if (_navbarItems.length >= _maxNavbarItems) return;
    setState(() {
      _moreItems.remove(page);
      _navbarItems.add(page);
    });
    _save();
  }

  void _moveToMore(String page) {
    if (_navbarItems.length <= 1) return;
    setState(() {
      _navbarItems.remove(page);
      _moreItems.insert(0, page);
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFull = _navbarItems.length >= _maxNavbarItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + slot counter
          Padding(
            padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 16.0),
            child: Row(
              children: [
                Text(
                  _s("navbar_order"),
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).text,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: isFull
                        ? colorScheme.errorContainer
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    SettingsLocalization(
                            SettingsLocalization("navbar_slots").i18n)
                        .fill([_navbarItems.length, _maxNavbarItems]),
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: isFull
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navbar items (reorderable)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              _s("navbar_section"),
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).text.withValues(alpha: 0.45),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18.0),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _navbarItems.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _navbarItems.removeAt(oldIndex);
                  _navbarItems.insert(newIndex, item);
                });
                _save();
              },
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, child: child),
              itemBuilder: (context, index) {
                final page = _navbarItems[index];
                return ListTile(
                  key: ValueKey(page),
                  leading: Icon(_pageIcon(page), color: colorScheme.onSurface),
                  title: Text(
                    _p(page),
                    style: TextStyle(
                      color: AppColors.of(context).text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline_rounded,
                          color: _navbarItems.length > 1
                              ? colorScheme.error
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        onPressed: _navbarItems.length > 1
                            ? () => _moveToMore(page)
                            : null,
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // "Több" fixed last item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0)),
              tileColor:
                  colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              leading: Icon(Icons.more_horiz_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.35)),
              title: Text(
                _p("more"),
                style: TextStyle(
                  color: AppColors.of(context).text.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _s("navbar_more_fixed"),
                style: TextStyle(
                  fontSize: 11.0,
                  color: AppColors.of(context).text.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),

          // More menu items
          if (_moreItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 8.0, bottom: 6.0),
              child: Text(
                _s("more_section"),
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).text.withValues(alpha: 0.45),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Column(
                children: _moreItems
                    .map((page) => ListTile(
                          key: ValueKey('more_$page'),
                          leading: Icon(
                            _pageIcon(page),
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          title: Text(
                            _p(page),
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              color: !isFull
                                  ? colorScheme.primary
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                            ),
                            onPressed:
                                !isFull ? () => _moveToNavbar(page) : null,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
