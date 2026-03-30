import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/pages/grades/grades_page.i18n.dart';

final Map<int, String> avgDropItems = {
  0: "annual_average",
  90: "3_months_average",
  30: "30_days_average",
  14: "14_days_average",
  7: "7_days_average",
};

class AverageSelector extends StatelessWidget {
  const AverageSelector({super.key, this.onChanged, required this.value});

  final Function(int?)? onChanged;
  final int value;

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AverageSelectorModal(
        value: value,
        onChanged: (v) {
          Navigator.of(ctx).pop();
          onChanged?.call(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onPrimaryContainer
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 13.0,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer
                  .withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6.0),
            Text(
              avgDropItems[value]!.i18n,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 4.0),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16.0,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer
                  .withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _AverageSelectorModal extends StatelessWidget {
  const _AverageSelectorModal({required this.value, this.onChanged});

  final int value;
  final Function(int?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            // Title
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 6.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      size: 17.0,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    "avg_period".i18n,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            // Options
            ...avgDropItems.entries.map((entry) {
              final isSelected = entry.key == value;
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 3.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.0),
                    onTap: () => onChanged?.call(entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 13.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Row(
                        children: [
                          Text(
                            entry.value.i18n,
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(
                              Icons.check_rounded,
                              size: 18.0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
