import 'package:folio/theme/colors/colors.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/note.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';
import 'package:flutter/material.dart';

class NoteTile extends StatelessWidget {
  const NoteTile(this.note, {super.key, this.onTap, this.padding});

  final Note note;
  final void Function()? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
        child: Theme(
          data: Theme.of(context).copyWith(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
          ),
          child: ListTile(
            visualDensity: VisualDensity.compact,
            contentPadding: const EdgeInsets.only(left: 8.0, right: 10.0),
            onTap: onTap,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0)),
            leading: RoundBorderIcon(
              icon: const Icon(
                Icons.sticky_note_2_outlined,
                size: 22.0,
              ),
              padding: 6.0,
              width: 1.0,
            ),
            title: Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              note.content.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              note.date.format(context),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.0,
                color: AppColors.of(context).text.withValues(alpha: .75),
              ),
            ),
            minLeadingWidth: 0,
          ),
        ),
      ),
    );
  }
}
