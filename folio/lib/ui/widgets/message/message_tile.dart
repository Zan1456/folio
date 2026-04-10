import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessageTile extends StatelessWidget {
  const MessageTile(
    this.message, {
    super.key,
    this.messages,
    this.padding,
    this.onTap,
    this.censored = false,
  });

  final Message message;
  final List<Message>? messages;
  final EdgeInsetsGeometry? padding;
  final Function()? onTap;
  final bool censored;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
        child: ListTile(
          onTap: onTap,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
          leading: censored
              ? Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.of(context).text.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(60.0),
                  ),
                )
              : RoundBorderIcon(
                  icon: const Icon(
                    Icons.mail_outline_rounded,
                    size: 22.0,
                  ),
                  padding: 6.0,
                  width: 1.0,
                ),
          title: censored
              ? Wrap(
                  children: [
                    Container(
                      width: 105,
                      height: 15,
                      decoration: BoxDecoration(
                        color:
                            AppColors.of(context).text.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        !Provider.of<SettingsProvider>(context, listen: false)
                                .presentationMode
                            ? message.author
                            : "Béla",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15.5),
                      ),
                    ),
                    if (message.attachments.isNotEmpty)
                      const Icon(Icons.attach_file_rounded, size: 16.0)
                  ],
                ),
          subtitle: censored
              ? Wrap(
                  children: [
                    Container(
                      width: 150,
                      height: 10,
                      decoration: BoxDecoration(
                        color:
                            AppColors.of(context).text.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                )
              : Text(
                  message.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14.0),
                ),
          trailing: censored
              ? Wrap(
                  children: [
                    Container(
                      width: 35,
                      height: 15,
                      decoration: BoxDecoration(
                        color:
                            AppColors.of(context).text.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ],
                )
              : Text(
                  message.date.format(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.0,
                    color: AppColors.of(context).text.withValues(alpha: .75),
                  ),
                ),
        ),
      ),
    );
  }
}
