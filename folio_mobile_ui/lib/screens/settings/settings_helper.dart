// ignore_for_file: prefer_function_declarations_over_variables, library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/helpers/quick_actions.dart';
import 'package:folio/models/settings.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/theme/observer.dart';
import 'package:folio_kreta_api/models/grade.dart';
import 'package:folio_kreta_api/models/subject.dart';
import 'package:folio_kreta_api/models/week.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/bottom_sheet_menu_item.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:folio_mobile_ui/common/filter_bar.dart';
import 'package:folio_mobile_ui/common/material_action_button.dart';
import 'package:folio/ui/widgets/grade/grade_tile.dart';
import 'package:folio_mobile_ui/common/panel/panel_button.dart';
import 'package:folio_mobile_ui/common/system_chrome.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:provider/provider.dart';
import 'package:folio_mobile_ui/common/screens.i18n.dart';
import 'package:folio_mobile_ui/screens/settings/settings_screen.i18n.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:folio/models/icon_pack.dart';
import 'package:folio/utils/format.dart';
import 'package:folio_mobile_ui/screens/settings/theme_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsHelper {
  static const Map<String, String> langMap = {
    "en": "🇬🇧  English",
    "hu": "🇭🇺  Magyar",
    "de": "🇩🇪  Deutsch"
  };

  static const List<String> fontList = [
    "Montserrat",
    "Merienda",
    "M PLUS Code Latin",
    "Figtree",
    "Fira Code",
    "Vollkorn",
  ];

  static const Map<Pages, String> pageTitle = {
    Pages.home: "home",
    Pages.grades: "grades",
    Pages.timetable: "timetable",
    // Pages.messages: "messages",
  };

  static Map<VibrationStrength, String> vibrationTitle = {
    VibrationStrength.off: "voff",
    VibrationStrength.light: "vlight",
    VibrationStrength.medium: "vmedium",
    VibrationStrength.strong: "vstrong",
  };

  static Map<Pages, String> localizedPageTitles() => pageTitle
      .map((key, value) => MapEntry(key, ScreensLocalization(value).i18n));
  static Map<VibrationStrength, String> localizedVibrationTitles() =>
      vibrationTitle
          .map((key, value) => MapEntry(key, SettingsLocalization(value).i18n));

  static void language(BuildContext context) {
    showBottomSheetMenu(
      context,
      items: List.generate(langMap.length, (index) {
        String lang = langMap.keys.toList()[index];
        return BottomSheetMenuItem(
          onPressed: () {
            Provider.of<SettingsProvider>(context, listen: false)
                .update(language: lang);
            I18n.of(context).locale = Locale(lang, lang.toUpperCase());
            Navigator.of(context).maybePop();
            if (Platform.isAndroid || Platform.isIOS) {
              setupQuickActions();
            }
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(langMap.values.toList()[index]),
              if (lang == I18n.of(context).locale.languageCode)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
        );
      }),
    );
  }

  // static void uwuMode(BuildContext context, value) {
  //   final settings = Provider.of<SettingsProvider>(context, listen: false);
  //   if (value) {
  //     I18n.of(context).locale = const Locale('uw', 'UW');
  //   } else {
  //     I18n.of(context).locale =
  //         Locale(settings.language, settings.language.toUpperCase());
  //   }
  //   if (Platform.isAndroid || Platform.isIOS) {
  //     setupQuickActions();
  //   }
  // }

  static void fontFamily(BuildContext context,
      {required Function() showDialog}) {
    SettingsProvider settings =
        Provider.of<SettingsProvider>(context, listen: false);

    showBottomSheetMenu(
      context,
      items: List.generate(fontList.length, (index) {
        // if (index == fontList.length) {
        //   return BottomSheetMenuItem(
        //     onPressed: showDialog,
        //     title: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         Text(
        //           SettingsLocalization('custom').i18n,
        //         ),
        //         if (fontList.contains(settings.fontFamily) == false &&
        //             settings.fontFamily != '')
        //           Icon(
        //             Icons.check_circle,
        //             color: Theme.of(context).colorScheme.secondary,
        //           ),
        //       ],
        //     ),
        //   );
        // }

        String font = fontList[index];
        return BottomSheetMenuItem(
          onPressed: () {
            settings.update(fontFamily: font == 'Montserrat' ? '' : font);
            Provider.of<ThemeModeObserver>(context, listen: false)
                .changeTheme(settings.theme, updateNavbarColor: false);

            Navigator.of(context).maybePop();
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                font,
                style: GoogleFonts.getFont(font),
              ),
              if (font == settings.fontFamily ||
                  font.replaceAll('Montserrat', '') == settings.fontFamily)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
        );
      }),
    );
  }

  static void iconPack(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    showBottomSheetMenu(
      context,
      items: List.generate(IconPack.values.length, (index) {
        IconPack current = IconPack.values[index];
        return BottomSheetMenuItem(
          onPressed: () {
            settings.update(iconPack: current);
            Navigator.of(context).maybePop();
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(current.name.capital()),
              if (current == settings.iconPack)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
        );
      }),
    );
  }

  static void startPage(BuildContext context) {
    const Map<Pages, IconData> pageIcons = {
      Pages.home: Icons.home_rounded,
      Pages.grades: Icons.bar_chart_rounded,
      Pages.timetable: Icons.calendar_today_rounded,
    };

    const allowedPages = [Pages.home, Pages.grades, Pages.timetable];

    showBottomSheetMenu(
      context,
      items: List.generate(allowedPages.length, (index) {
        final page = allowedPages[index];
        final isSelected =
            Provider.of<SettingsProvider>(context, listen: false).startPage ==
                page;
        return BottomSheetMenuItem(
          onPressed: () {
            Provider.of<SettingsProvider>(context, listen: false)
                .update(startPage: page);
            Navigator.of(context).maybePop();
          },
          icon: Icon(
            pageIcons[page] ?? Icons.circle_outlined,
            size: 22.0,
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : AppColors.of(context).text.withValues(alpha: .75),
          ),
          title: Row(
            children: [
              Text(localizedPageTitles()[page] ?? ""),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
        );
      }),
    );
  }

  static void rounding(BuildContext context) {
    showRoundedModalBottomSheet(
      context,
      child: const RoundingSetting(),
    );
  }

  // new v5 roundings
  static void newRoundings(BuildContext context, GradeSubject subject) {
    showRoundedModalBottomSheet(
      context,
      child: RoundingSetting(
        rounding: subject.customRounding,
        subjectId: subject.id,
      ),
    );
  }
  // end

  static void theme(BuildContext context) {
    var settings = Provider.of<SettingsProvider>(context, listen: false);
    void Function(ThemeMode) setTheme = (mode) {
      settings.update(theme: mode);
      Provider.of<ThemeModeObserver>(context, listen: false).changeTheme(mode);
      Navigator.of(context).maybePop();
    };

    showBottomSheetMenu(context, items: [
      BottomSheetMenuItem(
        onPressed: () => setTheme(ThemeMode.system),
        icon: Icon(Icons.smartphone_rounded,
            size: 22.0,
            color: settings.theme == ThemeMode.system
                ? Theme.of(context).colorScheme.secondary
                : AppColors.of(context).text.withValues(alpha: .75)),
        title: Row(
          children: [
            Text(SettingsLocalization("system").i18n),
            const Spacer(),
            if (settings.theme == ThemeMode.system)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ),
      BottomSheetMenuItem(
        onPressed: () => setTheme(ThemeMode.light),
        icon: Icon(Icons.wb_sunny_rounded,
            size: 22.0,
            color: settings.theme == ThemeMode.light
                ? Theme.of(context).colorScheme.secondary
                : AppColors.of(context).text.withValues(alpha: .75)),
        title: Row(
          children: [
            Text(SettingsLocalization("light").i18n),
            const Spacer(),
            if (settings.theme == ThemeMode.light)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ),
      BottomSheetMenuItem(
        onPressed: () => setTheme(ThemeMode.dark),
        icon: Icon(Icons.nightlight_round,
            size: 22.0,
            color: settings.theme == ThemeMode.dark
                ? Theme.of(context).colorScheme.secondary
                : AppColors.of(context).text.withValues(alpha: .75)),
        title: Row(
          children: [
            Text(SettingsLocalization("dark").i18n),
            const Spacer(),
            if (settings.theme == ThemeMode.dark)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary),
          ],
        ),
      ),
    ]);
  }

  static void accentColor(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, _, __) =>
            const PremiumCustomAccentColorSetting(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  static void gradeColors(BuildContext context) {
    showRoundedModalBottomSheet(
      context,
      child: const GradeColorsSetting(),
    );
  }

  static void liveActivityColor(BuildContext context) {
    showRoundedModalBottomSheet(
      context,
      child: const LiveActivityColorSetting(),
    );
  }

  static void vibrate(BuildContext context) {
    showBottomSheetMenu(
      context,
      items: List.generate(VibrationStrength.values.length, (index) {
        VibrationStrength value = VibrationStrength.values[index];

        return BottomSheetMenuItem(
          onPressed: () {
            Provider.of<SettingsProvider>(context, listen: false)
                .update(vibrate: value);
            Navigator.of(context).maybePop();
          },
          title: Row(
            children: [
              Container(
                width: 12.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(
                      alpha: (index + 1) / (vibrationTitle.length + 1)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16.0),
              Text(localizedVibrationTitles()[value] ?? "?"),
              const Spacer(),
              if (value ==
                  Provider.of<SettingsProvider>(context, listen: false).vibrate)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
        );
      }),
    );
  }

  static void bellDelay(BuildContext context) {
    showRoundedModalBottomSheet(
      context,
      child: const BellDelaySetting(),
    );
  }

  static void countdownBeforeMinutes(BuildContext context) {
    showRoundedModalBottomSheet(
      context,
      child: const CountdownBeforeMinutesSetting(),
    );
  }

  // v5 user changer
  static void changeCurrentUser(BuildContext context, List<Widget> accountTiles,
      int len, String addUsrLocTxt) {
    showBottomSheetMenu(
      context,
      items: List.generate(len, (index) {
        if (index == accountTiles.length) {
          return const SizedBox(
            height: 10.0,
          );
          // return Center(
          //   child: Container(
          //     margin: const EdgeInsets.only(top: 12.0, bottom: 4.0),
          //     height: 3.0,
          //     width: 175.0,
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(12.0),
          //       color: AppColors.of(context).text.withValues(alpha: .25),
          //     ),
          //   ),
          // );
        } else if (index == accountTiles.length + 1) {
          return PanelButton(
            onPressed: () {
              // if (!Provider.of<PlusProvider>(context, listen: false)
              //     .hasScope(PremiumScopes.maxTwoAccounts)) {
              //   PlusLockedFeaturePopup.show(
              //       context: context, feature: PremiumFeature.moreAccounts);
              //   return;
              // }

              // if ((accountTiles.length - 1 == 2) &&
              //     !Provider.of<PlusProvider>(context, listen: false)
              //         .hasScope(PremiumScopes.noAccountLimit)) {
              //   PlusLockedFeaturePopup.show(
              //       context: context, feature: PremiumFeature.moreAccounts);
              //   return;
              // }

              Navigator.of(context).pushNamed("login_back").then((value) {
                setSystemChrome(context);
              });
            },
            title: Text(addUsrLocTxt),
            leading: const Padding(
              padding: EdgeInsets.only(left: 8.22, right: 6.9),
              child: Icon(Icons.person_add_rounded),
            ),
          );
        } else {
          return accountTiles[index];
        }
      }),
    );
  }

  // v5 grade rarity texts
  static void surpriseGradeRarityText(
    BuildContext context, {
    required String title,
    required String cancel,
    required String done,
    required List<String> rarities,
  }) {
    showRoundedModalBottomSheet(
      context,
      child: GradeRarityTextSetting(
        title: title,
        cancel: cancel,
        done: done,
        defaultRarities: rarities,
      ),
    );
  }

  // v5 plus options
  static void plusOptions(BuildContext context) {
    showBottomSheetMenu(
      context,
      items: [
        BottomSheetMenuItem(
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: Provider.of<SettingsProvider>(context, listen: false)
                  .plusSessionId,
            ));

            Navigator.of(context).pop();
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(SettingsLocalization('copy_plus_id').i18n),
              Icon(
                Icons.content_copy_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
        BottomSheetMenuItem(
          onPressed: () {
            launchUrl(
              Uri.parse(
                  'https://billing.stripe.com/p/login/4gwbIRclL89D5PicMM'),
              mode: LaunchMode.inAppBrowserView,
            );

            Navigator.of(context).pop();
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(SettingsLocalization('manage_subs').i18n),
              Icon(
                Icons.monetization_on_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Rounding modal
class RoundingSetting extends StatefulWidget {
  const RoundingSetting({super.key, this.rounding, this.subjectId});

  final double? rounding;
  final String? subjectId;

  @override
  _RoundingSettingState createState() => _RoundingSettingState();
}

class _RoundingSettingState extends State<RoundingSetting> {
  late double rounding;

  @override
  void initState() {
    super.initState();

    rounding = (widget.rounding ??
            Provider.of<SettingsProvider>(context, listen: false).rounding) /
        10;
  }

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    DatabaseProvider databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);

    int roundingResult;

    if (4.5 >= 4.5.floor() + rounding) {
      roundingResult = 5;
    } else {
      roundingResult = 4;
    }

    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Slider(
              value: rounding,
              min: 0.1,
              max: 0.9,
              divisions: 8,
              label: rounding.toStringAsFixed(1),
              activeColor: Theme.of(context).colorScheme.secondary,
              thumbColor: Theme.of(context).colorScheme.secondary,
              onChanged: (v) => setState(() => rounding = v),
            ),
          ),
          Container(
            width: 50.0,
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(rounding.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.0,
                  )),
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("4.5",
              style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.w500)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.grey),
          ),
          GradeValueWidget(GradeValue(roundingResult, "", "", 100),
              fill: true, size: 32.0),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 6.0),
        child: MaterialActionButton(
          child: Text(SettingsLocalization("done").i18n),
          onPressed: () async {
            if (widget.rounding == null) {
              Provider.of<SettingsProvider>(context, listen: false)
                  .update(rounding: (rounding * 10).toInt());
            } else {
              Map<String, String> roundings = await databaseProvider.userQuery
                  .getRoundings(userId: userProvider.id!);

              roundings[widget.subjectId!] = (rounding * 10).toStringAsFixed(2);

              await databaseProvider.userStore
                  .storeRoundings(roundings, userId: userProvider.id!);

              await Provider.of<GradeProvider>(context, listen: false)
                  .convertBySettings();
              await Provider.of<TimetableProvider>(context, listen: false)
                  .convertBySettings();
              await Provider.of<AbsenceProvider>(context, listen: false)
                  .convertBySettings();
            }

            // ik i'm like a kreta dev, but setstate isn't working, so please don't kill me bye :3
            // actually it also looks good and it's kinda useful
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            // setState(() {});
          },
        ),
      ),
    ]);
  }
}

// Bell Delay Modal

class BellDelaySetting extends StatefulWidget {
  const BellDelaySetting({super.key});

  @override
  State<BellDelaySetting> createState() => _BellDelaySettingState();
}

class _BellDelaySettingState extends State<BellDelaySetting>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Duration currentDelay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex:
            Provider.of<SettingsProvider>(context, listen: false).bellDelay > 0
                ? 1
                : 0);
    currentDelay = Duration(
        seconds:
            Provider.of<SettingsProvider>(context, listen: false).bellDelay);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterBar(
          scrollable: true,
          tabAlignment: TabAlignment.center,
          items: [
            Tab(text: SettingsLocalization("delay").i18n),
            Tab(text: SettingsLocalization("hurry").i18n),
          ],
          controller: _tabController,
          onTap: (i) async {
            // swap current page with target page
            setState(() {
              currentDelay = i == 0 ? -currentDelay.abs() : currentDelay.abs();
            });
          },
        ),
        SizedBox(
          height: 200,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: Theme.of(context).brightness,
            ),
            child: CupertinoTimerPicker(
              key: UniqueKey(),
              mode: CupertinoTimerPickerMode.ms,
              initialTimerDuration: currentDelay.abs(),
              onTimerDurationChanged: (Duration d) {
                HapticFeedback.selectionClick();

                currentDelay = _tabController.index == 0 ? -d : d;
              },
            ),
          ),
        ),
        Text(SettingsLocalization("sync_help").i18n,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: AppColors.of(context).text.withValues(alpha: .75))),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 6.0),
          child: Column(
            children: [
              MaterialActionButton(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(SettingsLocalization("sync").i18n),
                onPressed: () {
                  final lessonProvider =
                      Provider.of<TimetableProvider>(context, listen: false);

                  Duration? closest;
                  DateTime now = DateTime.now();
                  for (var lesson
                      in lessonProvider.getWeek(Week.current()) ?? []) {
                    Duration sdiff = lesson.start.difference(now);
                    Duration ediff = lesson.end.difference(now);

                    if (closest == null || sdiff.abs() < closest.abs()) {
                      closest = sdiff;
                    }
                    if (ediff.abs() < closest.abs()) closest = ediff;
                  }
                  if (closest != null) {
                    if (closest.inHours.abs() >= 1) return;
                    currentDelay = closest;
                    Provider.of<SettingsProvider>(context, listen: false)
                        .update(bellDelay: currentDelay.inSeconds);
                    _tabController.index = currentDelay.inSeconds > 0 ? 1 : 0;
                    if (Platform.isIOS) {
                      LiveCardProvider.hasActivitySettingsChanged = true;
                    }
                    setState(() {});
                  }
                },
              ),
              MaterialActionButton(
                child: Text(SettingsLocalization("done").i18n),
                onPressed: () {
                  //Provider.of<SettingsProvider>(context, listen: false).update(context, rounding: (r * 10).toInt());
                  Provider.of<SettingsProvider>(context, listen: false)
                      .update(bellDelay: currentDelay.inSeconds);
                  if (Platform.isIOS) {
                    LiveCardProvider.hasActivitySettingsChanged = true;
                  }
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GradeColorsSetting extends StatefulWidget {
  const GradeColorsSetting({super.key});

  @override
  _GradeColorsSettingState createState() => _GradeColorsSettingState();
}

class _GradeColorsSettingState extends State<GradeColorsSetting> {
  Color currentColor = const Color(0x00000000);
  late SettingsProvider settings;

  @override
  void initState() {
    super.initState();
    settings = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            return ClipOval(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    currentColor = settings.gradeColors[index];
                    showRoundedModalBottomSheet(
                      context,
                      child: Column(children: [
                        MaterialColorPicker(
                          selectedColor: settings.gradeColors[index],
                          onColorChange: (v) {
                            setState(() {
                              currentColor = v;
                            });
                          },
                          allowShades: true,
                          elevation: 0,
                          physics: const NeverScrollableScrollPhysics(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              MaterialActionButton(
                                onPressed: () {
                                  List<Color> colors =
                                      List.castFrom(settings.gradeColors);
                                  var defaultColors =
                                      SettingsProvider.defaultSettings()
                                          .gradeColors;
                                  colors[index] = defaultColors[index];
                                  settings.update(gradeColors: colors);
                                  Navigator.of(context).maybePop();
                                },
                                child: Text(SettingsLocalization("reset").i18n),
                              ),
                              MaterialActionButton(
                                onPressed: () {
                                  List<Color> colors =
                                      List.castFrom(settings.gradeColors);
                                  colors[index] = currentColor.withAlpha(255);
                                  settings.update(
                                      gradeColors: settings.gradeColors);
                                  Navigator.of(context).maybePop();
                                },
                                child: Text(SettingsLocalization("done").i18n),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ).then((value) => setState(() {}));
                  },
                  child: GradeValueWidget(GradeValue(index + 1, "", "", 0),
                      fill: true, size: 36.0),
                ),
              ),
            );
          }),
        ),
      ),
    ]);
  }
}

class LiveActivityColorSetting extends StatefulWidget {
  const LiveActivityColorSetting({super.key});

  @override
  _LiveActivityColorSettingState createState() =>
      _LiveActivityColorSettingState();
}

class _LiveActivityColorSettingState extends State<LiveActivityColorSetting> {
  late SettingsProvider settings;
  Color currentColor = const Color(0x00000000);

  @override
  void initState() {
    super.initState();
    settings = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: [
            MaterialColorPicker(
              allowShades: false,
              colors: [...fullMaterialColors],
              selectedColor: settings.liveActivityColor,
              onMainColorChange: (k) {
                setState(() {
                  currentColor = k as Color;
                  settings.update(
                      liveActivityColor: currentColor.withAlpha(255));
                  LiveCardProvider.hasActivitySettingsChanged = true;
                  Navigator.of(context).maybePop();
                });
              },
              elevation: 0,
              physics: const NeverScrollableScrollPhysics(),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MaterialActionButton(
                    onPressed: () {
                      var defaultColors =
                          SettingsProvider.defaultSettings().liveActivityColor;
                      settings.update(liveActivityColor: defaultColors);
                      LiveCardProvider.hasActivitySettingsChanged = true;
                      Navigator.of(context).maybePop();
                    },
                    child: Text(SettingsLocalization("reset").i18n),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class CountdownBeforeMinutesSetting extends StatefulWidget {
  const CountdownBeforeMinutesSetting({super.key});

  @override
  State<CountdownBeforeMinutesSetting> createState() =>
      _CountdownBeforeMinutesSettingState();
}

class _CountdownBeforeMinutesSettingState
    extends State<CountdownBeforeMinutesSetting> {
  static const int _minMinutes = 1;
  static const int _maxMinutes = 90;
  late FixedExtentScrollController _scrollController;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = Provider.of<SettingsProvider>(context, listen: false)
        .liveCountdownBeforeMinutes
        .clamp(_minMinutes, _maxMinutes);
    _scrollController =
        FixedExtentScrollController(initialItem: _selected - _minMinutes);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: CupertinoTheme(
            data: CupertinoThemeData(brightness: Theme.of(context).brightness),
            child: CupertinoPicker(
              scrollController: _scrollController,
              itemExtent: 44.0,
              onSelectedItemChanged: (i) {
                HapticFeedback.selectionClick();
                setState(() => _selected = _minMinutes + i);
              },
              children: List.generate(
                _maxMinutes - _minMinutes + 1,
                (i) => Center(
                  child: Text(
                    SettingsLocalization('min_before')
                        .i18n
                        .replaceFirst('%s', '${_minMinutes + i}'),
                    style: TextStyle(
                      fontSize: 18.0,
                      color: AppColors.of(context).text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, top: 6.0),
          child: MaterialActionButton(
            child: Text(SettingsLocalization('done').i18n),
            onPressed: () {
              Provider.of<SettingsProvider>(context, listen: false)
                  .update(liveCountdownBeforeMinutes: _selected);
              Navigator.of(context).maybePop();
            },
          ),
        ),
      ],
    );
  }
}

class GradeRarityTextSetting extends StatefulWidget {
  const GradeRarityTextSetting({
    super.key,
    required this.title,
    required this.cancel,
    required this.done,
    required this.defaultRarities,
  });

  final String title;
  final String cancel;
  final String done;
  final List<String> defaultRarities;

  @override
  State<GradeRarityTextSetting> createState() => _GradeRarityTextSettingState();
}

class _GradeRarityTextSettingState extends State<GradeRarityTextSetting> {
  late List<TextEditingController> _controllers;
  final List<String> _keys = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.defaultRarities.length,
      (i) => TextEditingController(text: widget.defaultRarities[i]),
    );
    _loadFromDb();
  }

  void _loadFromDb() async {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);
    final stored = await db.userQuery.getGradeRarities(userId: user.id!);
    for (int i = 0; i < _keys.length && i < _controllers.length; i++) {
      if (stored.containsKey(_keys[i])) {
        _controllers[i].text = stored[_keys[i]]!;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12.0),
          ...List.generate(_controllers.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: TextField(
              controller: _controllers[i],
              decoration: InputDecoration(
                labelText: _keys[i],
                border: const OutlineInputBorder(),
              ),
            ),
          )),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(widget.cancel),
              ),
              const SizedBox(width: 8.0),
              FilledButton(
                onPressed: () async {
                  final db = Provider.of<DatabaseProvider>(context, listen: false);
                  final user = Provider.of<UserProvider>(context, listen: false);
                  final Map<String, String> rarities = {};
                  for (int i = 0; i < _keys.length && i < _controllers.length; i++) {
                    rarities[_keys[i]] = _controllers[i].text;
                  }
                  await db.userStore.storeGradeRarities(rarities, userId: user.id!);
                  Navigator.of(context).maybePop();
                },
                child: Text(widget.done),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
