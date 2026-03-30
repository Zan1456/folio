import 'package:folio/models/ad.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';

class AdTile extends StatelessWidget {
  const AdTile(this.ad,
      {super.key, this.onTap, this.padding, this.showExternalIcon = true});

  final Ad ad;
  final Function()? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showExternalIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
      child: PanelButton(
        padding: const EdgeInsets.only(left: 8.0, right: 16.0),
        onPressed: onTap,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ad.title,
            ),
            Text(
              ad.description,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.of(context).text.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        leading: ad.logoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50.0),
                child: Image.network(
                  width: 42.0,
                  height: 42.0,
                  ad.logoUrl.toString(),
                  errorBuilder: (context, error, stackTrace) {
                    ad.logoUrl = null;
                    return const SizedBox();
                  },
                ),
              )
            : null,
        trailing: showExternalIcon
            ? const Icon(
                Icons.open_in_new_rounded,
                size: 20.0,
              )
            : null,
      ),
    );
  }
}
