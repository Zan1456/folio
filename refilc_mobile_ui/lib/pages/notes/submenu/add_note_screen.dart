// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:google_fonts/google_fonts.dart';
import 'package:refilc/api/providers/database_provider.dart';
import 'package:refilc/api/providers/self_note_provider.dart';
import 'package:refilc/api/providers/user_provider.dart';
import 'package:refilc/models/self_note.dart';
import 'package:refilc/theme/colors/colors.dart';
import 'package:refilc_kreta_api/providers/homework_provider.dart';
import 'package:refilc_mobile_ui/pages/notes/submenu/notes_screen.i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key, this.initialNote});

  final SelfNote? initialNote;

  @override
  AddNoteScreenState createState() => AddNoteScreenState();
}

class AddNoteScreenState extends State<AddNoteScreen> {
  late UserProvider user;
  late HomeworkProvider homeworkProvider;
  late DatabaseProvider databaseProvider;
  late SelfNoteProvider selfNoteProvider;

  final _contentController = TextEditingController();
  final _titleController = TextEditingController();

  int _charCount = 0;

  @override
  void initState() {
    _contentController.text = widget.initialNote?.content ?? '';
    _titleController.text = widget.initialNote?.title ?? '';
    _charCount = _contentController.text.length;
    _contentController.addListener(() {
      setState(() => _charCount = _contentController.text.length);
    });
    super.initState();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    homeworkProvider = Provider.of<HomeworkProvider>(context);
    databaseProvider = Provider.of<DatabaseProvider>(context);
    selfNoteProvider = Provider.of<SelfNoteProvider>(context);

    final bool isEditing = widget.initialNote != null;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: 60.0,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: accentColor.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              _FormatButton(
                label: 'B',
                style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.0,
                  ),
                ),
                onTap: () => insertTextAtCur('**;c;**'),
                accentColor: accentColor,
              ),
              const SizedBox(width: 8.0),
              _FormatButton(
                label: 'I',
                style: GoogleFonts.robotoMono(
                  textStyle: const TextStyle(
                    height: 1.0,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    fontSize: 15.0,
                  ),
                ),
                onTap: () => insertTextAtCur('*;c;*'),
                accentColor: accentColor,
              ),
              const SizedBox(width: 8.0),
              _FormatButton(
                icon: Icons.code_rounded,
                onTap: () => insertTextAtCur('`;c;`'),
                accentColor: accentColor,
              ),
              const Spacer(),
              Text(
                '$_charCount',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        leading: BackButton(color: AppColors.of(context).text),
        title: Text(
          isEditing ? 'edit_note'.i18n : 'new_note'.i18n,
          style: TextStyle(
            color: AppColors.of(context).text,
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              if (_contentController.text.replaceAll(' ', '') == '') return;

              var notes = selfNoteProvider.notes;

              if (!isEditing) {
                notes.add(SelfNote.fromJson({
                  'id': const Uuid().v4(),
                  'title': _titleController.text.replaceAll(' ', '') == ''
                      ? null
                      : _titleController.text,
                  'content': _contentController.text,
                  'note_type': 'text',
                }));
              } else {
                var i = notes.indexWhere((e) => e.id == widget.initialNote!.id);
                notes[i] = SelfNote.fromJson({
                  'id': notes[i].id,
                  'title': _titleController.text.replaceAll(' ', '') == ''
                      ? null
                      : _titleController.text,
                  'content': _contentController.text,
                  'note_type': 'text',
                });
              }

              await selfNoteProvider.store(notes);

              Navigator.of(context).pop();
              if (isEditing) Navigator.of(context).pop();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                color: accentColor.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14.0, vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16.0,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'save'.i18n,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22.0, 4.0, 22.0, 0.0),
              child: TextField(
                controller: _titleController,
                expands: false,
                maxLines: 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: "hint_t".i18n,
                  hintStyle: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.35),
                  ),
                ),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).text,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22.0),
              child: Divider(
                height: 1.0,
                thickness: 1.0,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.08),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22.0, 0.0, 22.0, 0.0),
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: "hint".i18n,
                    hintStyle: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: AppColors.of(context).text,
                    height: 1.55,
                  ),
                ),
              ),
            ),
            if (MediaQuery.of(context).viewInsets.bottom != 0)
              const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void insertTextAtCur(String text) {
    var selStartPos = _contentController.selection.start;
    var selEndPost = _contentController.selection.end;
    var cursorPos = _contentController.selection.base.offset;

    String textToBefore = text.split(';c;')[0];
    String textToAfter = text.split(';c;')[1];

    if (selStartPos == selEndPost) {
      setState(() {
        _contentController.value = _contentController.value.copyWith(
          text: _contentController.text.replaceRange(
            max(cursorPos, 0),
            max(cursorPos, 0),
            textToBefore + textToAfter,
          ),
          selection: TextSelection.fromPosition(
            TextPosition(offset: max(cursorPos, 0) + textToBefore.length),
          ),
        );
      });
    } else {
      setState(() {
        _contentController.value = _contentController.value.copyWith(
          text: _contentController.text.replaceRange(
            max(selStartPos, 0),
            max(selEndPost, 0),
            textToBefore +
                _contentController.text.substring(
                  max(selStartPos, 0),
                  max(selEndPost, 0),
                ) +
                textToAfter,
          ),
          selection: TextSelection.fromPosition(
            TextPosition(
              offset: max(selEndPost, 0) + textToBefore.length,
            ),
          ),
        );
      });
    }
  }
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    this.label,
    this.style,
    this.icon,
    required this.onTap,
    required this.accentColor,
  });

  final String? label;
  final TextStyle? style;
  final IconData? icon;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36.0,
        height: 36.0,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .onPrimaryContainer
              .withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer
                .withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(
                icon,
                size: 17.0,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.75),
              )
            : Text(
                label!,
                textAlign: TextAlign.center,
                style: style?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.75),
                ),
              ),
      ),
    );
  }
}
