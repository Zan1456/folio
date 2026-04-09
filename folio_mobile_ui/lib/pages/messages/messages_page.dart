import 'dart:math';

import 'package:google_fonts/google_fonts.dart';
import 'package:folio/api/providers/update_provider.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/ui/date_widget.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio/ui/filter/sort.dart';
import 'package:folio_mobile_ui/common/widgets/message/message_viewable.dart';
import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/common/haptic.dart';
import 'package:provider/provider.dart';
import 'messages_page.i18n.dart';
import 'send_message/send_message.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late UserProvider user;
  late MessageProvider messageProvider;
  late UpdateProvider updateProvider;
  late String firstName;
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    messageProvider = Provider.of<MessageProvider>(context);
    updateProvider = Provider.of<UpdateProvider>(context);

    final colorScheme = Theme.of(context).colorScheme;
    final settings = Provider.of<SettingsProvider>(context);

    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(28.0)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 0.0),
                    child: Row(
                      children: [
                        if (Navigator.of(context).canPop()) ...[
                        GestureDetector(
                          onTap: () {
                            performHapticFeedback(settings.vibrate);
                            Navigator.of(context).maybePop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        ],
                        Expanded(
                          child: Text(
                            "Messages".i18n,
                            style: settings.fontFamily != '' &&
                                    settings.titleOnlyFont
                                ? GoogleFonts.getFont(
                                    settings.fontFamily,
                                    textStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontSize: 28.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: 28.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            performHapticFeedback(settings.vibrate);
                            showSendMessageSheet(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  size: 16.0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  "Send".i18n,
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) => TabBar(
                      controller: tabController,
                      dividerColor: Colors.transparent,
                      labelColor:
                          Theme.of(context).colorScheme.secondary,
                      unselectedLabelColor: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.65),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 6.0),
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      overlayColor: WidgetStateProperty.all(
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.08),
                      ),
                      onTap: (_) => performHapticFeedback(settings.vibrate),
                      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 14.0),
                      tabs: [
                        Tab(text: "Inbox".i18n),
                        Tab(text: "Sent".i18n),
                        Tab(text: "Trash".i18n),
                        Tab(text: "Draft".i18n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const BouncingScrollPhysics(),
              controller: tabController,
              children: List.generate(
                  4, (index) => filterViewBuilder(context, index)),
            ),
          ),
        ],
      ),
    );
  }

  List<DateWidget> getFilterWidgets(MessageType activeData) {
    List<DateWidget> items = [];
    switch (activeData) {
      case MessageType.inbox:
        for (var message in messageProvider.messages) {
          if (message.type == MessageType.inbox) {
            items.add(DateWidget(
              date: message.date,
              widget: MessageViewable(message),
            ));
          }
        }
        break;
      case MessageType.sent:
        for (var message in messageProvider.messages) {
          if (message.type == MessageType.sent) {
            items.add(DateWidget(
              date: message.date,
              widget: MessageViewable(message),
            ));
          }
        }
        break;
      case MessageType.trash:
        for (var message in messageProvider.messages) {
          if (message.type == MessageType.trash) {
            items.add(DateWidget(
              date: message.date,
              widget: MessageViewable(message),
            ));
          }
        }
        break;
      case MessageType.draft:
        for (var message in messageProvider.messages) {
          if (message.type == MessageType.draft) {
            items.add(DateWidget(
              date: message.date,
              widget: MessageViewable(message),
            ));
          }
        }
        break;
    }
    return items;
  }

  Widget filterViewBuilder(context, int activeData) {
    List<Widget> filterWidgets = sortDateWidgets(context,
        dateWidgets: getFilterWidgets(MessageType.values[activeData]),
        hasShadow: true);

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () {
          return Future.wait([
            messageProvider.fetch(type: MessageType.inbox),
            messageProvider.fetch(type: MessageType.sent),
            messageProvider.fetch(type: MessageType.trash),
          ]);
        },
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) => filterWidgets.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 6.0),
                  child: filterWidgets[index],
                )
              : Empty(subtitle: "empty".i18n),
          itemCount: max(filterWidgets.length, 1),
        ),
      ),
    );
  }

  Future<void> showSendMessageSheet(BuildContext context) async {
    await messageProvider.fetchAllRecipients();

    List<SendRecipient> rs = [];

    List<int> add = [];
    for (var r in messageProvider.recipients) {
      if (!add.contains(r.id)) {
        rs.add(r);
        add.add(r.id ?? 0);
      }
    }

    SendMessageSheet.show(context, rs);
  }
}

class _MessageFilterBar extends StatelessWidget {
  const _MessageFilterBar({
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(labels.length, (i) {
              final active = controller.index == i;
              return GestureDetector(
                onTap: () => controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 8.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 9.0),
                  decoration: BoxDecoration(
                    color: active
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
