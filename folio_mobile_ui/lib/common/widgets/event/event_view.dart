import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/colors/utils.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/event.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/round_border_icon.dart';

class EventView extends StatelessWidget {
  const EventView(this.event, {super.key});

  final Event event;

  static void show(Event event, {required BuildContext context}) =>
      showRoundedModalBottomSheet(
        context,
        child: EventView(event),
        showHandle: false,
      );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12.0),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              // Background SVG + gradient (Positioned – doesn't affect Stack height)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 200.0,
                  child: Stack(
                    children: [
                      SvgPicture.asset(
                        "assets/svg/cover_arts/line.svg",
                        // ignore: deprecated_member_use
                        color: ColorsUtils()
                            .fade(
                                context,
                                Theme.of(context).colorScheme.secondary,
                                darkenAmount: 0.1,
                                lightenAmount: 0.1)
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
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                          Icons.campaign_outlined,
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

                    // Header card
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
                                  .format(event.start)
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
                            event.title,
                            style: TextStyle(
                              color: AppColors.of(context).text,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content card
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
                      padding: const EdgeInsets.all(14.0),
                      child: SelectableLinkify(
                        text: event.content.escapeHtml(),
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

                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 8.0),
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
