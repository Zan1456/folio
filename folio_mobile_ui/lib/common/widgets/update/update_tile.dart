import 'package:folio/flavor.dart';
import 'package:folio/models/release.dart';
import 'package:flutter/material.dart';
import 'update_tile.i18n.dart';

class UpdateTile extends StatelessWidget {
  const UpdateTile(this.release, {super.key, this.onTap, this.padding});

  final Release release;
  final Function()? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Icon(Icons.system_update_rounded,
                    size: 22.0, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "update_available".i18n,
                      style: tt.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      release.tag,
                      style: tt.bodySmall!.copyWith(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: cs.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      kIsPlayStore
                          ? Icons.open_in_new_rounded
                          : Icons.download_rounded,
                      size: 15.0,
                      color: cs.onPrimaryContainer,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      kIsPlayStore ? "Play Store" : "download".i18n,
                      style: tt.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
