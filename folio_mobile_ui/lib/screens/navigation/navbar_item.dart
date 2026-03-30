import 'package:flutter/material.dart';

class NavItem {
  final String title;
  final Widget icon;
  final Widget activeIcon;

  const NavItem(
      {required this.title, required this.icon, required this.activeIcon});
}

class NavbarItem extends StatelessWidget {
  const NavbarItem({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.onSecondaryContainer;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: active
                ? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0)
                : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: active ? colorScheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(50.0),
            ),
            child: IconTheme(
              data: IconThemeData(
                color: active ? activeColor : inactiveColor,
                size: 24.0,
              ),
              child: active ? item.activeIcon : item.icon,
            ),
          ),
          const SizedBox(height: 4.0),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: 11.0,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? activeColor : inactiveColor,
            ),
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
