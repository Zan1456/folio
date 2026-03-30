import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:provider/provider.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/colors/utils.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';
import 'package:folio_mobile_ui/common/widgets/homework/homework_attachment_tile.dart';
import 'package:folio_mobile_ui/common/widgets/homework/homework_tile.dart';

class HomeworkViewable extends StatelessWidget {
  const HomeworkViewable(this.homework, {super.key});

  final Homework homework;

  @override
  Widget build(BuildContext context) {
    return HomeworkTile(
      homework,
      onTap: () => HomeworkPopup.show(context: context, homework: homework),
    );
  }
}

class HomeworkPopup extends StatelessWidget {
  const HomeworkPopup({
    super.key,
    required this.homework,
    required this.outsideContext,
  });

  final Homework homework;
  final BuildContext outsideContext;

  static void show({
    required BuildContext context,
    required Homework homework,
  }) =>
      showRoundedModalBottomSheet(
        context,
        child: HomeworkPopup(
          homework: homework,
          outsideContext: context,
        ),
        showHandle: false,
      );

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final subjectName = homework.subject.isRenamed &&
            settings.renamedSubjectsEnabled
        ? homework.subject.renamedTo ?? homework.subject.name.capital()
        : homework.subject.name.capital();

    final teacherName = (homework.teacher.isRenamed
            ? homework.teacher.renamedTo
            : homework.teacher.name) ??
        '';

    final hasDeadline = homework.deadline.year != 0;
    final hasAttachments = homework.attachments.isNotEmpty;

    return Container(
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
                SubjectBooklet.resolveVariant(
                    context: context, subject: homework.subject),
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

          SizedBox(
            width: MediaQuery.of(context).size.width,
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
                          .fade(
                              context, Theme.of(context).colorScheme.secondary,
                              darkenAmount: 0.1, lightenAmount: 0.1)
                          .withValues(alpha: 0.33),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),

                  const SizedBox(height: 38.0),

                  // Subject icon
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
                        SubjectIcon.resolveVariant(
                            context: context, subject: homework.subject),
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

                  // Header: subject + teacher + date
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
                        Row(
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
                                    .format(homework.date)
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
                            if (hasDeadline) ...[
                              const SizedBox(width: 6.0),
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
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 11.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withValues(alpha: .9),
                                    ),
                                    const SizedBox(width: 3.0),
                                    Text(
                                      DateFormat('MMM d',
                                              I18n.locale.countryCode)
                                          .format(homework.deadline)
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
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          subjectName,
                          style: TextStyle(
                            color: AppColors.of(context).text,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            fontStyle: homework.subject.isRenamed &&
                                    settings.renamedSubjectsItalics
                                ? FontStyle.italic
                                : null,
                          ),
                        ),
                        if (teacherName.isNotEmpty) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            teacherName,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: 0.9),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Homework content
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
                      text: homework.content.escapeHtml(),
                      options:
                          const LinkifyOptions(looseUrl: true, removeWww: true),
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

                  // Attachments
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
                        children: homework.attachments
                            .map((a) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 8.0),
                                  child: HomeworkAttachmentTile(a),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
