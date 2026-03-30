import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/colors/utils.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';
import 'package:folio/ui/widgets/message/message_tile.dart';
import 'package:folio_mobile_ui/common/widgets/message/attachment_tile.dart';
import 'message_view_tile.i18n.dart';

class MessageViewable extends StatelessWidget {
  const MessageViewable(this.message, {super.key});

  final Message message;

  @override
  Widget build(BuildContext context) {
    bool pressed = false;
    return GestureDetector(
      onTap: () {
        if (pressed) return;
        pressed = true;
        MessagePopup.show(context: context, message: message);
        Future.delayed(const Duration(seconds: 2), () {
          pressed = false;
        });
      },
      child: MessageTile(message),
    );
  }
}

class MessagePopup extends StatefulWidget {
  const MessagePopup({
    super.key,
    required this.message,
    required this.outsideContext,
  });

  final Message message;
  final BuildContext outsideContext;

  static void show({
    required BuildContext context,
    required Message message,
  }) =>
      showRoundedModalBottomSheet(
        context,
        child: MessagePopup(
          message: message,
          outsideContext: context,
        ),
        showHandle: false,
      );

  @override
  State<MessagePopup> createState() => _MessagePopupState();
}

class _MessagePopupState extends State<MessagePopup> {
  bool _showAllRecipients = false;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);
    final message = widget.message;

    final iAmRecipient =
        message.recipients.any((r) => r.name == user.student?.name);
    final otherRecipients =
        message.recipients.where((r) => r.name != user.student?.name).toList();
    final allNames =
        message.recipients.map((r) => r.name).toSet().toList();

    String recipientLabel = "";
    if (_showAllRecipients) {
      recipientLabel = allNames.join("\n");
    } else if (iAmRecipient) {
      recipientLabel = "me".i18n;
      if (otherRecipients.isNotEmpty) {
        recipientLabel += " +${otherRecipients.length}";
      }
    } else {
      recipientLabel = allNames.take(3).join(", ");
      if (allNames.length > 3) recipientLabel += " +${allNames.length - 3}";
    }

    final canExpand = message.recipients.length > 1 ||
        (!iAmRecipient && allNames.length > 3);

    final authorName = settings.presentationMode ? "Tanár" : message.author;
    final hasAttachments = message.attachments.isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.65,
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12.0),
          ),
        ),
        child: Stack(
          children: [
            // Background SVG + gradient
            Stack(
              children: [
                SvgPicture.asset(
                  "assets/svg/cover_arts/line.svg",
                  // ignore: deprecated_member_use
                  color: ColorsUtils()
                      .fade(context, Theme.of(context).colorScheme.secondary,
                          darkenAmount: 0.1, lightenAmount: 0.1)
                      .withValues(alpha: 0.33),
                  width: MediaQuery.of(context).size.width,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.1),
                        Theme.of(context)
                            .scaffoldBackgroundColor
                            .withValues(alpha: 0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                      stops: const [0.0, 0.3, 0.6, 0.95],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  width: MediaQuery.of(context).size.width,
                  height: 200.0,
                ),
              ],
            ),

            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ColorsUtils()
                              .fade(context,
                                  Theme.of(context).colorScheme.secondary,
                                  darkenAmount: 0.1, lightenAmount: 0.1)
                              .withValues(alpha: 0.33),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),

                      const SizedBox(height: 38.0),

                      // Centered icon
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                        child: RoundBorderIcon(
                          color: ColorsUtils()
                              .darken(
                                Theme.of(context).colorScheme.secondary,
                                amount: 0.1,
                              )
                              .withValues(alpha: 0.9),
                          width: 1.5,
                          padding: 10.0,
                          icon: Icon(
                            Icons.mail_outline_rounded,
                            size: 32.0,
                            color: ColorsUtils()
                                .darken(
                                  Theme.of(context).colorScheme.secondary,
                                  amount: 0.1,
                                )
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 55.0),

                      // Header card: subject + author + date
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12.0),
                            bottom: Radius.circular(6.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5.5, vertical: 3.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                DateFormat('MMM d', I18n.locale.countryCode)
                                    .format(message.date)
                                    .capital(),
                                style: TextStyle(
                                  height: 1.1,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: .9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              message.subject,
                              style: TextStyle(
                                color: AppColors.of(context).text,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              authorName,
                              style: TextStyle(
                                color: AppColors.of(context)
                                    .text
                                    .withValues(alpha: 0.9),
                                fontSize: 14.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (recipientLabel.isNotEmpty) ...[
                              const SizedBox(height: 4.0),
                              GestureDetector(
                                onTap: canExpand
                                    ? () => setState(() =>
                                        _showAllRecipients =
                                            !_showAllRecipients)
                                    : null,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${"to".i18n} $recipientLabel",
                                        style: TextStyle(
                                          color: AppColors.of(context)
                                              .text
                                              .withValues(alpha: 0.6),
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    if (canExpand)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 4.0),
                                        child: Icon(
                                          _showAllRecipients
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          size: 16.0,
                                          color: AppColors.of(context)
                                              .text
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Content card
                      const SizedBox(height: 6.0),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.vertical(
                            top: const Radius.circular(6.0),
                            bottom: hasAttachments
                                ? const Radius.circular(6.0)
                                : const Radius.circular(12.0),
                          ),
                        ),
                        padding: const EdgeInsets.all(14.0),
                        child: SelectableLinkify(
                          text: message.content.escapeHtml(),
                          options: const LinkifyOptions(
                              looseUrl: true, removeWww: true),
                          onOpen: (link) {
                            launchUrl(
                              Uri.parse(link.url),
                              customTabsOptions: CustomTabsOptions(
                                showTitle: true,
                                colorSchemes: CustomTabsColorSchemes(
                                  defaultPrams: CustomTabsColorSchemeParams(
                                    toolbarColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                  ),
                                ),
                              ),
                            );
                          },
                          style: TextStyle(
                            color: AppColors.of(context)
                                .text
                                .withValues(alpha: 0.9),
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      // Attachments card
                      if (hasAttachments) ...[
                        const SizedBox(height: 6.0),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6.0),
                              bottom: Radius.circular(12.0),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          child: Column(
                            children: message.attachments
                                .map((a) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0, horizontal: 8.0),
                                      child: AttachmentTile(a),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],

                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 8.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
