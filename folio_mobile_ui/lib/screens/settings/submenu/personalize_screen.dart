// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/helpers/subject.dart';
import 'package:folio/models/icon_pack.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/observer.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';
import 'package:folio_mobile_ui/common/splitted_panel/splitted_panel.dart';
import 'package:folio_mobile_ui/common/widgets/custom_segmented_control.dart';
import 'package:folio_mobile_ui/screens/settings/settings_helper.dart';
import 'package:folio_mobile_ui/screens/settings/submenu/edit_subject.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:folio_mobile_ui/screens/settings/settings_screen.i18n.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuPersonalizeSettings extends StatelessWidget {
  const MenuPersonalizeSettings({
    super.key,
    this.borderRadius = const BorderRadius.vertical(
        top: Radius.circular(4.0), bottom: Radius.circular(4.0)),
  });

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return PanelButton(
      onPressed: () => Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
            builder: (context) => const PersonalizeSettingsScreen()),
      ),
      title: Text("personalization".i18n),
      leading: Icon(
        Icons.palette_outlined,
        size: 22.0,
        color: AppColors.of(context).text.withValues(alpha: 0.95),
      ),
      trailing: Icon(
        Icons.keyboard_arrow_right_rounded,
        size: 22.0,
        color: AppColors.of(context).text.withValues(alpha: 0.95),
      ),
      borderRadius: borderRadius,
    );
  }
}

class PersonalizeSettingsScreen extends StatefulWidget {
  const PersonalizeSettingsScreen({super.key});

  @override
  PersonalizeSettingsScreenState createState() =>
      PersonalizeSettingsScreenState();
}

class PersonalizeSettingsScreenState extends State<PersonalizeSettingsScreen>
    with SingleTickerProviderStateMixin {
  late SettingsProvider settingsProvider;
  late UserProvider user;

  late AnimationController _hideContainersController;

  final TextEditingController _customFontFamily = TextEditingController();

  late List<Grade> editedShit;
  late List<Grade> otherShit;

  late List<Widget> tiles;
  // late List<Widget> fontTiles;

  @override
  void initState() {
    super.initState();

    // editedShit = Provider.of<GradeProvider>(context, listen: false)
    //     .grades
    //     .where((e) => e.teacher.isRenamed || e.subject.isRenamed)
    //     // .map((e) => e.subject)
    //     .toSet()
    //     .toList()
    //   ..sort((a, b) => a.subject.name.compareTo(b.subject.name));

    List<Grade> other = Provider.of<GradeProvider>(context, listen: false)
        .grades
        .where((e) => !e.teacher.isRenamed && !e.subject.isRenamed)
        .toSet()
        .toList()
      ..sort((a, b) => a.subject.name.compareTo(b.subject.name));

    otherShit = [];
    var addedOthers = [];

    for (var e in other) {
      if (addedOthers.contains(e.subject.id)) continue;
      addedOthers.add(e.subject.id);

      otherShit.add(e);
    }

    otherShit = otherShit
      ..sort((a, b) =>
          a.subject.name.compareTo(b.subject.name)); // just cuz why not

    // editedTeachers = Provider.of<GradeProvider>(context, listen: false)
    //     .grades
    //     .where((e) => e.teacher.isRenamed || e.subject.isRenamed)
    //     .map((e) => e.teacher)
    //     .toSet()
    //     .toList();
    // // ..sort((a, b) => a.name.compareTo(b.name));
    // otherTeachers = Provider.of<GradeProvider>(context, listen: false)
    //     .grades
    //     .where((e) => !e.teacher.isRenamed && !e.subject.isRenamed)
    //     .map((e) => e.teacher)
    //     .toSet()
    //     .toList();
    // ..sort((a, b) => a.name.compareTo(b.name));

    _hideContainersController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  void buildSubjectTiles() {
    List<Widget> subjectTiles = [];

    var added = [];
    var i = 0;

    List<Grade> need = [];
    for (var s in editedShit) {
      if (added.contains(s.subject.id)) continue;
      need.add(s);
      added.add(s.subject.id);
    }

    for (var s in need) {
      Widget widget = PanelButton(
        onPressed: () async {
          Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(
              builder: (context) => EditSubjectScreen(
                subject: s.subject,
                teacher: s.teacher, // not sure why, but it works tho
              ),
            ),
          );

          setState(() {});
        },
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (s.subject.isRenamed && settingsProvider.renamedSubjectsEnabled
                      ? s.subject.renamedTo
                      : s.subject.name.capital()) ??
                  '',
              style: TextStyle(
                color: AppColors.of(context).text.withValues(alpha: .95),
                fontStyle: settingsProvider.renamedSubjectsItalics
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
            Text(
              (s.teacher.isRenamed && settingsProvider.renamedTeachersEnabled
                      ? s.teacher.renamedTo
                      : s.teacher.name.capital()) ??
                  '',
              style: TextStyle(
                color: AppColors.of(context).text.withValues(alpha: .85),
                fontWeight: FontWeight.w400,
                fontSize: 15.0,
                height: 1.2,
              ),
            ),
          ],
        ),
        leading: Icon(
          SubjectIcon.resolveVariant(context: context, subject: s.subject),
          size: 22.0,
          color: AppColors.of(context).text.withValues(alpha: .95),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_right_rounded,
          size: 22.0,
          color: AppColors.of(context).text.withValues(alpha: 0.95),
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(i == 0 ? 12.0 : 4.0),
          bottom: Radius.circular(i + 1 == need.length ? 12.0 : 4.0),
        ),
      );

      i += 1;
      subjectTiles.add(widget);
    }

    tiles = subjectTiles;
  }

  // void buildFontTiles() {
  //   List<String> fonts = [
  //     "Merienda",
  //     "M PLUS Code Latin",
  //     "Figtree",
  //     "Fira Code",
  //     "Vollkorn",
  //   ];

  //   List<Widget> fTiles = [];
  //   var added = [];

  //   for (var f in fonts) {
  //     if (added.contains(f)) continue;

  //     Widget widget = PanelButton(
  //       onPressed: () async {
  //         settingsProvider.update(fontFamily: f);
  //         setState(() {});
  //       },
  //       title: Text(
  //         f,
  //         style: GoogleFonts.getFont(
  //           f,
  //           color: AppColors.of(context).text.withValues(alpha: .95),
  //           fontStyle: settingsProvider.renamedSubjectsItalics
  //               ? FontStyle.italic
  //               : FontStyle.normal,
  //         ),
  //       ),
  //       trailing: settingsProvider.fontFamily == f
  //           ? Icon(
  //               Icons.keyboard_arrow_right_rounded,
  //               size: 22.0,
  //               color: AppColors.of(context).text.withValues(alpha: 0.95),
  //             )
  //           : null,
  //       borderRadius: BorderRadius.circular(12.0),
  //     );

  //     fTiles.add(widget);
  //     added.add(f);
  //   }

  //   fontTiles = fTiles;
  // }

  @override
  Widget build(BuildContext context) {
    settingsProvider = Provider.of<SettingsProvider>(context);
    user = Provider.of<UserProvider>(context);

    // get edited shit
    editedShit = Provider.of<GradeProvider>(context, listen: false)
        .grades
        .where((e) => e.teacher.isRenamed || e.subject.isRenamed)
        // .map((e) => e.subject)
        .toSet()
        .toList()
      ..sort((a, b) => a.subject.name.compareTo(b.subject.name));

    String themeModeText = {
          ThemeMode.light: "light".i18n,
          ThemeMode.dark: "dark".i18n,
          ThemeMode.system: "system".i18n
        }[settingsProvider.theme] ??
        "?";

    // build da tilés
    buildSubjectTiles();
    // buildFontTiles();

    return AnimatedBuilder(
      animation: _hideContainersController,
      builder: (context, child) => Opacity(
        opacity: 1 - _hideContainersController.value,
        child: Scaffold(
          appBar: AppBar(
            surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
            leading: BackButton(color: AppColors.of(context).text),
            title: Text(
              "personalization".i18n,
              style: TextStyle(color: AppColors.of(context).text),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              child: Column(
                children: [
                  // app theme
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 8.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: true,
                    children: [
                      PanelButton(
                        onPressed: () {
                          SettingsHelper.theme(context);
                          setState(() {});
                        },
                        title: Text("theme".i18n),
                        leading: Icon(
                          Icons.wb_sunny_rounded,
                          size: 22.0,
                          color: AppColors.of(context)
                              .text
                              .withValues(alpha: 0.95),
                        ),
                        trailing: Text(
                          themeModeText,
                          style: const TextStyle(fontSize: 14.0),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // material you seed color picker
                  Padding(
                    padding: const EdgeInsets.only(top: 9.0),
                    child: _PersonalizeThemeColorPicker(
                      selectedColor: settingsProvider.adaptiveSeedColor,
                      onColorSelected: (color) {
                        settingsProvider.update(
                            adaptiveSeedColor: color?.value ?? 0);
                        Provider.of<ThemeModeObserver>(context, listen: false)
                            .changeTheme(settingsProvider.theme,
                                updateNavbarColor: false);
                        setState(() {});
                      },
                    ),
                  ),
                  // shadow toggle
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: true,
                    children: [
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                        onPressed: () async {
                          settingsProvider.update(
                              shadowEffect: !settingsProvider.shadowEffect);

                          setState(() {});
                        },
                        title: Text(
                          "shadow_effect".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withValues(
                                alpha:
                                    settingsProvider.shadowEffect ? .95 : .25),
                          ),
                        ),
                        leading: Icon(
                          Icons.nightlight_round,
                          size: 22.0,
                          color: AppColors.of(context).text.withValues(
                              alpha: settingsProvider.shadowEffect ? .95 : .25),
                        ),
                        trailing: Switch(
                          onChanged: (v) async {
                            settingsProvider.update(shadowEffect: v);

                            setState(() {});
                          },
                          value: settingsProvider.shadowEffect,
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // change subject icons
                  // SplittedPanel(
                  //   padding: const EdgeInsets.only(top: 9.0),
                  //   cardPadding: const EdgeInsets.all(4.0),
                  //   isSeparated: true,
                  //   children: [
                  //     PanelButton(
                  //       onPressed: () {
                  //         SettingsHelper.iconPack(context);
                  //       },
                  //       title: Text(
                  //         "icon_pack".i18n,
                  //         style: TextStyle(
                  //           color: AppColors.of(context).text.withValues(alpha: .95),
                  //         ),
                  //       ),
                  //       leading: Icon(
                  //         Icons.grid_view_rounded,
                  //         size: 22.0,
                  //         color: AppColors.of(context).text.withValues(alpha: .95),
                  //       ),
                  //       trailing: Text(
                  //         settingsProvider.iconPack.name.capital(),
                  //         style: const TextStyle(fontSize: 14.0),
                  //       ),
                  //       borderRadius: const BorderRadius.vertical(
                  //         top: Radius.circular(12.0),
                  //         bottom: Radius.circular(12.0),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // rename things
                  SplittedPanel(
                    padding: const EdgeInsets.only(top: 9.0),
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: false,
                    children: [
                      // rename subjects
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                        onPressed: () async {
                          settingsProvider.update(
                              renamedSubjectsEnabled:
                                  !settingsProvider.renamedSubjectsEnabled);
                          await Provider.of<GradeProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<TimetableProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<AbsenceProvider>(context,
                                  listen: false)
                              .convertBySettings();

                          setState(() {});
                        },
                        title: Text(
                          "rename_subjects".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withValues(
                                alpha: settingsProvider.renamedSubjectsEnabled
                                    ? .95
                                    : .25),
                          ),
                        ),
                        leading: Icon(
                          Icons.school_outlined,
                          size: 22.0,
                          color: AppColors.of(context).text.withValues(
                              alpha: settingsProvider.renamedSubjectsEnabled
                                  ? .95
                                  : .25),
                        ),
                        trailing: Switch(
                          onChanged: (v) async {
                            settingsProvider.update(renamedSubjectsEnabled: v);
                            await Provider.of<GradeProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<TimetableProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<AbsenceProvider>(context,
                                    listen: false)
                                .convertBySettings();

                            setState(() {});
                          },
                          value: settingsProvider.renamedSubjectsEnabled,
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(4.0),
                        ),
                      ),
                      // rename teachers
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                        onPressed: () async {
                          settingsProvider.update(
                              renamedTeachersEnabled:
                                  !settingsProvider.renamedTeachersEnabled);
                          await Provider.of<GradeProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<TimetableProvider>(context,
                                  listen: false)
                              .convertBySettings();
                          await Provider.of<AbsenceProvider>(context,
                                  listen: false)
                              .convertBySettings();

                          setState(() {});
                        },
                        title: Text(
                          "rename_teachers".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withValues(
                                alpha: settingsProvider.renamedTeachersEnabled
                                    ? .95
                                    : .25),
                          ),
                        ),
                        leading: Icon(
                          Icons.person_rounded,
                          size: 22.0,
                          color: AppColors.of(context).text.withValues(
                              alpha: settingsProvider.renamedTeachersEnabled
                                  ? .95
                                  : .25),
                        ),
                        trailing: Switch(
                          onChanged: (v) async {
                            settingsProvider.update(renamedTeachersEnabled: v);
                            await Provider.of<GradeProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<TimetableProvider>(context,
                                    listen: false)
                                .convertBySettings();
                            await Provider.of<AbsenceProvider>(context,
                                    listen: false)
                                .convertBySettings();

                            setState(() {});
                          },
                          value: settingsProvider.renamedTeachersEnabled,
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // live activity color
                  if (Platform.isIOS)
                    SplittedPanel(
                      padding: const EdgeInsets.only(top: 9.0),
                      cardPadding: const EdgeInsets.all(4.0),
                      isSeparated: true,
                      children: [
                        PanelButton(
                          onPressed: () {
                            SettingsHelper.liveActivityColor(context);
                            setState(() {});
                          },
                          title: Text(
                            "live_activity_color".i18n,
                            style: TextStyle(
                              color: AppColors.of(context)
                                  .text
                                  .withValues(alpha: .95),
                            ),
                          ),
                          leading: Icon(
                            Icons.show_chart_rounded,
                            size: 22.0,
                            color: AppColors.of(context)
                                .text
                                .withValues(alpha: .95),
                          ),
                          trailing: Container(
                            margin: const EdgeInsets.only(left: 2.0),
                            width: 12.0,
                            height: 12.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: settingsProvider.liveActivityColor,
                            ),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12.0),
                            bottom: Radius.circular(12.0),
                          ),
                        ),
                      ],
                    ),

                  // SplittedPanel(
                  //   padding: const EdgeInsets.only(top: 9.0),
                  //   cardPadding: const EdgeInsets.all(4.0),
                  //   isSeparated: true,
                  //   children: [],
                  // ),
                  if (settingsProvider.renamedSubjectsEnabled ||
                      settingsProvider.renamedTeachersEnabled)
                    Column(
                      children: [
                        const SizedBox(
                          height: 18.0,
                        ),
                        SplittedPanel(
                          title: Text('subjects'.i18n),
                          padding: EdgeInsets.zero,
                          cardPadding: const EdgeInsets.all(4.0),
                          children: tiles,
                        ),
                        const SizedBox(
                          height: 9.0,
                        ),
                        SplittedPanel(
                          padding: EdgeInsets.zero,
                          cardPadding: const EdgeInsets.all(3.0),
                          hasBorder: true,
                          isTransparent: true,
                          children: [
                            DropdownButton2(
                              items: otherShit
                                  .map((item) => DropdownItem<String>(
                                        value: item.subject.id,
                                        child: Text(
                                          item.subject.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.of(context).text,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (String? v) async {
                                Navigator.of(context, rootNavigator: true).push(
                                  CupertinoPageRoute(
                                    builder: (context) => EditSubjectScreen(
                                      subject: otherShit
                                          .firstWhere((e) => e.subject.id == v)
                                          .subject,
                                      teacher: otherShit
                                          .firstWhere((e) => e.subject.id == v)
                                          .teacher,
                                    ),
                                  ),
                                );

                                setState(() {});
                                // _subjectName.text = "";
                              },
                              iconStyleData: IconStyleData(
                                iconSize: 14,
                                iconEnabledColor: AppColors.of(context).text,
                                iconDisabledColor: AppColors.of(context).text,
                              ),
                              underline: const SizedBox(),
                              menuItemStyleData: const MenuItemStyleData(
                                padding: EdgeInsets.only(left: 14, right: 14),
                              ),
                              buttonStyleData: ButtonStyleData(
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              dropdownStyleData: DropdownStyleData(
                                width: 300,
                                padding: null,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 8,
                                offset: const Offset(-10, -10),
                                scrollbarTheme: ScrollbarThemeData(
                                  radius: const Radius.circular(40),
                                  thickness:
                                      WidgetStateProperty.all<double>(6.0),
                                  trackVisibility:
                                      WidgetStateProperty.all<bool>(true),
                                  thumbVisibility:
                                      WidgetStateProperty.all<bool>(true),
                                ),
                              ),
                              customButton: PanelButton(
                                title: Text(
                                  "select_subject".i18n,
                                  style: TextStyle(
                                    color: AppColors.of(context)
                                        .text
                                        .withValues(alpha: .95),
                                  ),
                                ),
                                leading: Icon(
                                  Icons.add_rounded,
                                  size: 22.0,
                                  color: AppColors.of(context)
                                      .text
                                      .withValues(alpha: .95),
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12.0),
                                  bottom: Radius.circular(12.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  // subject icon shceme
                  const SizedBox(
                    height: 18.0,
                  ),
                  SplittedPanel(
                    title: Text('icon_pack'.i18n),
                    padding: EdgeInsets.zero,
                    cardPadding: EdgeInsets.zero,
                    isTransparent: true,
                    children: [
                      CustomSegmentedControl(
                        onChanged: (v) {
                          settingsProvider.update(
                            iconPack:
                                v == 0 ? IconPack.material : IconPack.cupertino,
                          );

                          setState(() {});
                        },
                        value: settingsProvider.iconPack == IconPack.material
                            ? 0
                            : 1,
                        height: 38,
                        children: const [
                          Text(
                            'Material',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Cupertino',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // custom fonts
                  const SizedBox(
                    height: 18.0,
                  ),
                  SplittedPanel(
                    title: Text('fonts'.i18n),
                    padding: EdgeInsets.zero,
                    cardPadding: const EdgeInsets.all(4.0),
                    isSeparated: false,
                    children: [
                      PanelButton(
                        onPressed: () {
                          // if (!Provider.of<PlusProvider>(context, listen: false)
                          //     .hasScope(PremiumScopes.customFont)) {
                          //   PlusLockedFeaturePopup.show(
                          //       context: context,
                          //       feature: PremiumFeature.fontChange);
                          //   return;
                          // }

                          SettingsHelper.fontFamily(
                            context,
                            showDialog: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(14.0))),
                                contentPadding:
                                    const EdgeInsets.only(top: 10.0),
                                title: Text("custom".i18n),
                                content: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 10.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: _customFontFamily,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.grey, width: 1.5),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                                color: Colors.grey, width: 1.5),
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12.0),
                                          hintText: "ff_name".i18n,
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _customFontFamily.text = "";
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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).maybePop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      "next".i18n,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    onPressed: () async {
                                      settingsProvider.update(
                                          fontFamily: _customFontFamily.text);

                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        title: Text(
                          "font_family".i18n,
                          style: TextStyle(
                            color: AppColors.of(context)
                                .text
                                .withValues(alpha: .95),
                          ),
                        ),
                        leading: Icon(
                          Icons.text_fields_rounded,
                          size: 22.0,
                          color:
                              AppColors.of(context).text.withValues(alpha: .95),
                        ),
                        trailing: Text(
                          settingsProvider.fontFamily != ''
                              ? settingsProvider.fontFamily
                              : 'Montserrat',
                          style: GoogleFonts.getFont(
                              settingsProvider.fontFamily != ''
                                  ? settingsProvider.fontFamily
                                  : 'Montserrat',
                              fontSize: 14.0),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12.0),
                          bottom: Radius.circular(6.0),
                        ),
                      ),
                      PanelButton(
                        padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                        onPressed: () async {
                          settingsProvider.update(
                              titleOnlyFont: !settingsProvider.titleOnlyFont);
                          Provider.of<ThemeModeObserver>(context, listen: false)
                              .changeTheme(settingsProvider.theme,
                                  updateNavbarColor: false);
                          setState(() {});
                        },
                        title: Text(
                          "only_ch_title_font".i18n,
                          style: TextStyle(
                            color: AppColors.of(context).text.withValues(
                                alpha:
                                    settingsProvider.titleOnlyFont ? .95 : .25),
                          ),
                        ),
                        leading: Icon(
                          Icons.text_increase_rounded,
                          size: 22.0,
                          color: AppColors.of(context).text.withValues(
                              alpha:
                                  settingsProvider.titleOnlyFont ? .95 : .25),
                        ),
                        trailing: Switch(
                          onChanged: (v) async {
                            settingsProvider.update(titleOnlyFont: v);
                            Provider.of<ThemeModeObserver>(context,
                                    listen: false)
                                .changeTheme(settingsProvider.theme,
                                    updateNavbarColor: false);
                            setState(() {});
                          },
                          value: settingsProvider.titleOnlyFont,
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4.0),
                          bottom: Radius.circular(12.0),
                        ),
                      ),
                    ],
                  ),
                  // bottom padding
                  const SizedBox(
                    height: 20.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Inline theme color picker for personalize screen ─────────────────────

class _PersonalizeThemeColorPicker extends StatefulWidget {
  final Color? selectedColor;
  final void Function(Color?) onColorSelected;

  const _PersonalizeThemeColorPicker({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<_PersonalizeThemeColorPicker> createState() =>
      _PersonalizeThemeColorPickerState();
}

class _PersonalizeThemeColorPickerState
    extends State<_PersonalizeThemeColorPicker> {
  bool _open = false;

  static const List<Color> _colors = [
    Color(0xFFEF5350),
    Color(0xFFFF7043),
    Color(0xFFFFA726),
    Color(0xFFFFCA28),
    Color(0xFFD4E157),
    Color(0xFF66BB6A),
    Color(0xFF26A69A),
    Color(0xFF29B6F6),
    Color(0xFF42A5F5),
    Color(0xFF5C6BC0),
    Color(0xFF7E57C2),
    Color(0xFFAB47BC),
    Color(0xFFEC407A),
    Color(0xFF8D6E63),
    Color(0xFF78909C),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.of(context).text;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final isSystem = widget.selectedColor == null;

    return SplittedPanel(
      cardPadding: const EdgeInsets.all(4.0),
      isSeparated: false,
      children: [
        PanelButton(
          onPressed: () => setState(() => _open = !_open),
          title: Text(
            'material_you_color'.i18n,
            style: TextStyle(color: textColor.withValues(alpha: .95)),
          ),
          leading: Icon(Icons.color_lens_outlined,
              size: 22.0, color: textColor.withValues(alpha: .95)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.0,
                height: 12.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6.0),
              AnimatedRotation(
                turns: _open ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20.0, color: textColor.withValues(alpha: .6)),
              ),
            ],
          ),
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(12.0),
            bottom: Radius.circular(_open ? 4.0 : 12.0),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _open
              ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12.0)),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      children: [
                        _ColorDot(
                          color: Theme.of(context).colorScheme.primary,
                          isSelected: isSystem,
                          isSystem: true,
                          onTap: () => widget.onColorSelected(null),
                          accentColor: accentColor,
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          width: 1.5,
                          height: 32.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: textColor.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(1.0),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        for (final c in _colors) ...[
                          _ColorDot(
                            color: c,
                            isSelected: !isSystem &&
                                widget.selectedColor != null &&
                                widget.selectedColor!.value == c.value,
                            isSystem: false,
                            onTap: () => widget.onColorSelected(c),
                            accentColor: accentColor,
                          ),
                          const SizedBox(width: 8.0),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final bool isSystem;
  final VoidCallback onTap;
  final Color accentColor;

  const _ColorDot({
    required this.color,
    required this.isSelected,
    required this.isSystem,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36.0,
        height: 36.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border:
              isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
        ),
        child: isSystem
            ? Icon(Icons.smartphone_rounded,
                size: 18.0,
                color: color.computeLuminance() > 0.4
                    ? Colors.black54
                    : Colors.white70)
            : isSelected
                ? const Icon(Icons.check_rounded,
                    size: 18.0, color: Colors.white)
                : null,
      ),
    );
  }
}
