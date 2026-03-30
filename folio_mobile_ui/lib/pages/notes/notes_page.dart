/*
    Folio, the unofficial client for e-Kréta
    Copyright (C) 2025  Folio team

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/api/providers/self_note_provider.dart';
import 'package:folio/api/providers/update_provider.dart';
import 'package:folio/models/self_note.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/absence.dart';
import 'package:folio_kreta_api/models/homework.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/panel/panel.dart';
import 'package:folio_mobile_ui/common/soon_alert/soon_alert.dart';
import 'package:folio_mobile_ui/common/widgets/tick_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:folio_mobile_ui/pages/notes/submenu/add_note_screen.dart';
import 'package:folio_mobile_ui/pages/notes/submenu/create_image_note.dart';
import 'package:folio_mobile_ui/pages/notes/submenu/note_view_screen.dart';
import 'package:folio_mobile_ui/pages/notes/submenu/self_note_tile.dart';
import 'package:uuid/uuid.dart';
import 'notes_page.i18n.dart';

enum AbsenceFilter { absences, delays, misses }

class SubjectAbsence {
  GradeSubject subject;
  List<Absence> absences;
  double percentage;

  SubjectAbsence(
      {required this.subject, this.absences = const [], this.percentage = 0.0});
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  NotesPageState createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> with TickerProviderStateMixin {
  late UserProvider user;
  late UpdateProvider updateProvider;
  late DatabaseProvider databaseProvider;
  late SelfNoteProvider selfNoteProvider;

  late String firstName;

  Map<String, bool> doneItems = {};
  List<Widget> noteTiles = [];
  List<TodoItem> todoItems = [];

  final TextEditingController _taskName = TextEditingController();
  final TextEditingController _taskContent = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateTiles();
    });
  }

Future<void> deleteTodoItem(TodoItem item) async {
  todoItems.removeWhere((element) => element.id == item.id);
  await databaseProvider.userStore.storeSelfTodoItems(todoItems, userId: user.id!);

  Provider.of<SelfNoteProvider>(context, listen: false).restore();
  Provider.of<SelfNoteProvider>(context, listen: false).restoreTodo();

  setState(() {});
}

  Future<void> generateTiles() async {
    if (!mounted) return;

    user = Provider.of<UserProvider>(context, listen: false);
    databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    selfNoteProvider = Provider.of<SelfNoteProvider>(context, listen: false);

    doneItems = await databaseProvider.userQuery.toDoItems(userId: user.id!);
    todoItems = await databaseProvider.userQuery.getTodoItems(userId: user.id!);

    List<Widget> tiles = [];

    List<Homework> hw = Provider.of<HomeworkProvider>(context, listen: false)
        .homework
        .where((e) => e.deadline.isAfter(DateTime.now()))
        .toList();

    List<Widget> toDoTiles = [];

    if (hw.isNotEmpty) {
      toDoTiles.addAll(hw.map((e) => TickTile(
            padding: EdgeInsets.zero,
            title: 'homework'.i18n,
            description:
                '${(e.subject.isRenamed ? e.subject.renamedTo : e.subject.name) ?? ''}, ${e.content.escapeHtml()}',
            isTicked: doneItems[e.id] ?? false,
            onTap: (p0) async {
              doneItems[e.id] = p0;
              await databaseProvider.userStore
                  .storeToDoItem(doneItems, userId: user.id!);
              setState(() {});
            },
          )));
    }

if (selfNoteProvider.todos.isNotEmpty) {
  toDoTiles.addAll(selfNoteProvider.todos.map((e) => GestureDetector(
        onLongPress: () async {
          final todoItem = todoItems.firstWhere((item) => item.id == e.id);
          await deleteTodoItem(todoItem);
        },
        child: TickTile(
          padding: EdgeInsets.zero,
          title: e.title,
          description: e.content,
          isTicked: e.done,
          onTap: (p0) async {
            final todoItemIndex = todoItems.indexWhere((element) => element.id == e.id);
            if (todoItemIndex != -1) {
              TodoItem todoItem = todoItems[todoItemIndex];
              Map<String, dynamic> todoItemJson = todoItem.toJson;
              todoItemJson['done'] = p0;
              todoItem = TodoItem.fromJson(todoItemJson);
              todoItems[todoItemIndex] = todoItem;
              await databaseProvider.userStore.storeSelfTodoItems(todoItems, userId: user.id!);
            }
          },
        ),
      )));
}

    if (toDoTiles.isNotEmpty) {
      tiles.add(const SizedBox(
        height: 10.0,
      ));

      tiles.add(Panel(
        title: Text('todo'.i18n),
        child: Column(
          children: toDoTiles,
        ),
      ));
    }

    // self notes
    List<Widget> selfNoteTiles = [];

    if (selfNoteProvider.notes.isNotEmpty) {
      selfNoteTiles.addAll(selfNoteProvider.notes.reversed.map(
        (e) => e.noteType == NoteType.text
            ? SelfNoteTile(
                title: e.title ?? e.content.split(' ')[0],
                content: e.content,
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                        builder: (context) => NoteViewScreen(note: e))),
              )
            : GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                        builder: (context) => NoteViewScreen(note: e))),
                child: Container(
                  height: MediaQuery.of(context).size.width / 2.42,
                  width: MediaQuery.of(context).size.width / 2.42,
                  decoration: BoxDecoration(
                    boxShadow: [
                      if (Provider.of<SettingsProvider>(context, listen: false)
                          .shadowEffect)
                        BoxShadow(
                          offset: const Offset(0, 21),
                          blurRadius: 23.0,
                          color: Theme.of(context).shadowColor,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.memory(
                      const Base64Decoder().convert(e.content),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
      ));
    }

    if (selfNoteTiles.isNotEmpty) {
      // padding
      tiles.add(const SizedBox(
        height: 28.0,
      ));

      // actual thing
      tiles.add(Panel(
        title: Text('your_notes'.i18n),
        padding: EdgeInsets.zero,
        isTransparent: true,
        child: selfNoteTiles.length > 1
            ? Center(
                child: Wrap(
                  spacing: 18.0,
                  runSpacing: 18.0,
                  children: selfNoteTiles,
                ),
              )
            : Wrap(
                spacing: 18.0,
                runSpacing: 18.0,
                children: selfNoteTiles,
              ),
      ));
    }

    // insert empty tile
    if (tiles.isEmpty) {
      tiles.insert(
        0,
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Empty(subtitle: "empty".i18n),
        ),
      );
    }

    // padding
    tiles.add(const SizedBox(height: 32.0));

    noteTiles = List.castFrom(tiles);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    databaseProvider = Provider.of<DatabaseProvider>(context);
    updateProvider = Provider.of<UpdateProvider>(context);
    selfNoteProvider = Provider.of<SelfNoteProvider>(context);

    final colorScheme = Theme.of(context).colorScheme;
    final settings = Provider.of<SettingsProvider>(context);

    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];

    generateTiles();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28.0)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 12.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18.0,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            "notes".i18n,
                            style: settings.fontFamily != '' && settings.titleOnlyFont
                                ? GoogleFonts.getFont(
                                    settings.fontFamily,
                                    textStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontSize: 28.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontSize: 28.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => SoonAlert.show(context: context),
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              size: 20.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                var state = Provider.of<HomeworkProvider>(context, listen: false)
                    .fetch(from: DateTime.now().subtract(const Duration(days: 30)));
                Provider.of<SelfNoteProvider>(context, listen: false).restore();
                Provider.of<SelfNoteProvider>(context, listen: false).restoreTodo();
                generateTiles();
                return state;
              },
              color: colorScheme.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // Quick-create chips
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                child: Row(
                  children: [
                    _QuickChip(
                      icon: Icons.sticky_note_2_rounded,
                      label: "new_note".i18n,
                      color: colorScheme.secondaryContainer,
                      iconColor: colorScheme.onSecondaryContainer,
                      onTap: () => Navigator.of(context, rootNavigator: true)
                          .push(CupertinoPageRoute(
                              builder: (context) => const AddNoteScreen())),
                    ),
                    const SizedBox(width: 8.0),
                    _QuickChip(
                      icon: Icons.task_rounded,
                      label: "new_task".i18n,
                      color: colorScheme.tertiaryContainer,
                      iconColor: colorScheme.onTertiaryContainer,
                      onTap: () => showTaskCreation(context),
                    ),
                    const SizedBox(width: 8.0),
                    _QuickChip(
                      icon: Icons.photo_library_rounded,
                      label: "new_image".i18n,
                      color: colorScheme.primaryContainer,
                      iconColor: colorScheme.onPrimaryContainer,
                      onTap: () => showDialog(
                          context: context,
                          builder: (context) => ImageNoteEditor(user.user!)),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

            // Content tiles
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (noteTiles.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: noteTiles[index],
                    );
                  }
                  return Container();
                },
                childCount: max(noteTiles.length, 1),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16.0),
            ),
          ],
        ),
      ),
      ),
    ],
  ),
);
  }

  void showCreationModal(BuildContext context) {
    // _sheetController = _scaffoldKey.currentState?.showBottomSheet(
    //   (context) => RoundedBottomSheet(
    //       borderRadius: 14.0,
    //       child: BottomSheetMenu(items: [
    //         SwitchListTile(
    //             title: Text('show_lesson_num'.i18n),
    //             value:
    //                 Provider.of<SettingsProvider>(context).qTimetableLessonNum,
    //             onChanged: (v) {
    //               Provider.of<SettingsProvider>(context, listen: false)
    //                   .update(qTimetableLessonNum: v);
    //             })
    //       ])),
    //   backgroundColor: const Color(0x00000000),
    //   elevation: 12.0,
    // );

    // _sheetController!.closed.then((value) {
    //   // Show fab and grades
    //   if (mounted) {}
    // });
    showRoundedModalBottomSheet(
      context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: BottomSheetMenu(items: [
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface),
          child: ListTile(
            title: Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined),
                const SizedBox(
                  width: 10.0,
                ),
                Text('new_note'.i18n),
              ],
            ),
            onTap: () => Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(
                    builder: (context) => const AddNoteScreen())),
          ),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface),
          child: ListTile(
            title: Row(
              children: [
                const Icon(Icons.photo_library_outlined),
                const SizedBox(
                  width: 10.0,
                ),
                Text('new_image'.i18n),
              ],
            ),
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => ImageNoteEditor(user.user!));
            },
          ),
        ),
        const SizedBox(
          height: 10.0,
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              color: Theme.of(context).colorScheme.surface),
          child: ListTile(
            title: Row(
              children: [
                const Icon(Icons.task_outlined),
                const SizedBox(
                  width: 10.0,
                ),
                Text('new_task'.i18n),
              ],
            ),
            onTap: () {
              // if (!Provider.of<PlusProvider>(context, listen: false)
              //     .hasScope(PremiumScopes.unlimitedSelfNotes)) {
              //   PlusLockedFeaturePopup.show(
              //       context: context, feature: PremiumFeature.selfNotes);

              //   return;
              // }

              showTaskCreation(context);
            },
          ),
        ),
      ]),
    );
  }

  void showTaskCreation(context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14.0))),
        contentPadding: const EdgeInsets.only(top: 10.0),
        title: Text("new_task".i18n),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskName,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                  hintText: "task_name".i18n,
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _taskName.text = "";
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              TextField(
                controller: _taskContent,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Colors.grey, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                  hintText: "task_content".i18n,
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _taskContent.text = "";
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "cancel".i18n,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
          TextButton(
            child: Text(
              "next".i18n,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            onPressed: () async {
              todoItems.add(TodoItem.fromJson({
                'id': const Uuid().v4(),
                'title': _taskName.text.replaceAll(' ', '') != ""
                    ? _taskName.text
                    : 'no_title'.i18n,
                'content': _taskContent.text,
                'done': false,
              }));

              await databaseProvider.userStore
                  .storeSelfTodoItems(todoItems, userId: user.id!);

              setState(() {
                _taskName.text = "";
                _taskContent.text = "";
              });

              Provider.of<SelfNoteProvider>(context, listen: false).restore();
              Provider.of<SelfNoteProvider>(context, listen: false)
                  .restoreTodo();

              generateTiles();

              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24.0, color: iconColor),
              const SizedBox(height: 6.0),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

