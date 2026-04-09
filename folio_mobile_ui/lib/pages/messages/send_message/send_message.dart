// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/colors/utils.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/custom_snack_bar.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';
import 'package:folio_mobile_ui/pages/messages/send_message/send_message.i18n.dart';

class SendMessageSheet extends StatefulWidget {
  const SendMessageSheet(this.availableRecipients, {super.key});

  final List<SendRecipient> availableRecipients;

  static void show(BuildContext context, List<SendRecipient> recipients) =>
      showRoundedModalBottomSheet(
        context,
        child: SendMessageSheet(recipients),
        showHandle: false,
      );

  @override
  SendMessageSheetState createState() => SendMessageSheetState();
}

class SendMessageSheetState extends State<SendMessageSheet> {
  late MessageProvider messageProvider;

  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  List<SendRecipient> selectedRecipients = [];
  late List<SendRecipient> _available;

  @override
  void initState() {
    super.initState();
    _available = List.from(widget.availableRecipients);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showRecipientPicker() {
    if (_available.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              decoration: BoxDecoration(
                color: AppColors.of(context).text.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "select_recipient".i18n,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).text,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _available.length,
                itemBuilder: (_, i) {
                  final r = _available[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 2.0),
                    title: Text(
                      r.name ?? (r.id ?? 'Nincs név').toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).text,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedRecipients.add(r);
                        _available.remove(r);
                      });
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    messageProvider = Provider.of<MessageProvider>(context);

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
                  padding: EdgeInsets.fromLTRB(
                      18.0, 18.0, 18.0,
                      18.0 + MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ColorsUtils()
                              .fade(
                                  context,
                                  Theme.of(context).colorScheme.secondary,
                                  darkenAmount: 0.1,
                                  lightenAmount: 0.1)
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
                            Icons.edit_rounded,
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

                      // Recipients card
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
                            Text(
                              "send_message".i18n,
                              style: TextStyle(
                                color: AppColors.of(context).text,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: [
                                ...selectedRecipients.map(
                                  (r) => GestureDetector(
                                    onTap: () => setState(() {
                                      selectedRecipients.remove(r);
                                      _available.add(r);
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 5.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            r.name ??
                                                (r.id ?? 'Nincs név')
                                                    .toString(),
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                          ),
                                          const SizedBox(width: 4.0),
                                          Icon(
                                            Icons.close_rounded,
                                            size: 14.0,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer
                                                .withValues(alpha: 0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (_available.isNotEmpty)
                                  GestureDetector(
                                    onTap: _showRecipientPicker,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 5.0),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 15.0,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                          const SizedBox(width: 4.0),
                                          Text(
                                            "select_recipient".i18n,
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Subject card
                      const SizedBox(height: 6.0),
                      _NeutralTextField(
                        controller: _subjectController,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6.0),
                          bottom: Radius.circular(6.0),
                        ),
                        hintText: "message_subject".i18n,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                      ),

                      // Content card
                      const SizedBox(height: 6.0),
                      _NeutralTextField(
                        controller: _messageController,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6.0),
                          bottom: Radius.circular(12.0),
                        ),
                        hintText: "message_text".i18n,
                        fontWeight: FontWeight.w500,
                        fontSize: 15.0,
                        keyboardType: TextInputType.multiline,
                        maxLines: 8,
                        minLines: 4,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(500),
                        ],
                      ),

                      const SizedBox(height: 12.0),

                      // Send button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (_messageController.text.replaceAll(' ', '') ==
                                '') return;
                            if (selectedRecipients.isEmpty) return;

                            final subjectText =
                                _subjectController.text.replaceAll(' ', '') !=
                                        ''
                                    ? _subjectController.text
                                    : 'Nincs tárgy';

                            final res = await messageProvider.sendMessage(
                              recipients: selectedRecipients,
                              subject: subjectText,
                              messageText: _messageController.text,
                            );

                            if (res == 'send_permission_error') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar(
                                      content: Text('cant_send'.i18n),
                                      context: context));
                            }
                            if (res == 'successfully_sent') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  CustomSnackBar(
                                      content: Text('sent'.i18n),
                                      context: context));
                            }

                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.send_rounded, size: 18.0),
                          label: Text("send".i18n),
                          style: FilledButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                          height:
                              MediaQuery.of(context).padding.bottom + 8.0),
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

class _NeutralTextField extends StatelessWidget {
  const _NeutralTextField({
    required this.controller,
    required this.borderRadius,
    required this.hintText,
    required this.fontWeight,
    required this.fontSize,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.inputFormatters = const [],
  });

  final TextEditingController controller;
  final BorderRadiusGeometry borderRadius;
  final String hintText;
  final FontWeight fontWeight;
  final double fontSize;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final List<TextInputFormatter> inputFormatters;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.of(context).text;
    final neutralColor = textColor.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      child: TextSelectionTheme(
        data: TextSelectionThemeData(
          cursorColor: neutralColor,
          selectionColor: textColor.withValues(alpha: 0.15),
          selectionHandleColor: neutralColor,
        ),
        child: TextField(
          controller: controller,
          cursorColor: neutralColor,
          style: TextStyle(
            fontWeight: fontWeight,
            fontSize: fontSize,
            color: textColor,
          ),
          autocorrect: true,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: hintText,
            hintStyle: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
