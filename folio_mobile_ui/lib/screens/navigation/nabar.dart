import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/screens/navigation/navbar_item.dart';

class Navbar extends StatelessWidget {
  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final void Function(int index) onSelected;
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 10.0),
        child: Container(
          height: 64.0,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(36.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: List.generate(
              items.length,
              (index) => Expanded(
                child: NavbarItem(
                  item: items[index],
                  active: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
