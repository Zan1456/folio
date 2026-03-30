import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';

class BottomCard extends StatelessWidget {
  const BottomCard({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42.0,
            height: 4.0,
            margin: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(45.0),
              color: AppColors.of(context).text.withValues(alpha: 0.12),
            ),
          ),
          if (child != null) child!,
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.0),
        ],
      ),
    );
  }
}

Future<void> showBottomCard({
  required BuildContext context,
  Widget? child,
  bool rootNavigator = true,
}) async =>
    await showModalBottomSheet(
        backgroundColor: const Color(0x00000000),
        useRootNavigator: rootNavigator,
        elevation: 0,
        isDismissible: true,
        isScrollControlled: true,
        context: context,
        builder: (context) => BottomCard(child: child));
