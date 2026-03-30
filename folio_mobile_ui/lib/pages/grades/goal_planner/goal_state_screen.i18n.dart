import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations.byLocale("hu-HU") +
      {
        "en-US": {
          // base page
          "goal_planner_title": "Goal Planning",
          "almost_there": "Almost there! Keep going!",
          "started_with": "Started with:",
          "current": "Current:",
          "your_goal": "Your goal:",
          "change_it": "Change it",
          "look_at_graph": "Look at this graph!",
          "thats_progress":
              "Now that's what I call progress! Push a little more, you're almost there..",
          "you_need": "You need:",
          // done modal
          "congrats_title": "🎉 Congratulations!",
          "goal_reached": "You reached your goal after %s days!",
          "started_at": "You started at",
          "improved_by": "and improved your grade by %s",
          "detailed_stats": "See my detailed stats",
          "later": "Yay! I'll see my stats later.",
          // sure delete modal
          "delete": "Delete",
          "attention": "Attention!",
          "attention_body":
              "Your goal and progress will be lost forever and cannot be restored.",
        },
        "hu-HU": {
          // base page
          "goal_planner_title": "Cél követés",
          "almost_there": "Majdnem megvan! Így tovább!",
          "started_with": "Így kezdődött:",
          "current": "Jelenlegi:",
          "your_goal": "Célod:",
          "change_it": "Megváltoztatás",
          "look_at_graph": "Nézd meg ezt a grafikont!",
          "thats_progress":
              "Ezt nevezem haladásnak! Hajts még egy kicsit, már majdnem kész..",
          "you_need": "Szükséges:",
          // done modal
          "congrats_title": "🎉 Gratulálunk!",
          "goal_reached": "%s nap után érted el a célod!",
          "started_at": "Átlagod kezdéskor:",
          "improved_by": "%s-os javulást értél el!",
          "detailed_stats": "Részletes statisztikám",
          "later": "Hurrá! Megnézem máskor.",
          // sure delete modal
          "delete": "Törlés",
          "attention": "Figyelem!",
          "attention_body":
              "A kitűzött célod és haladásod örökre elveszik és nem lesz visszaállítható.",
        },
        "de-DE": {
          // base page
          "goal_planner_title": "Zielplanung",
          "almost_there": "Fast dort! Weitermachen!",
          "started_with": "Begann mit:",
          "current": "Aktuell:",
          "your_goal": "Dein Ziel:",
          "change_it": "Ändern Sie es",
          "look_at_graph": "Schauen Sie sich diese Grafik an!",
          "thats_progress":
              "Das nenne ich Fortschritt! Drücken Sie noch ein wenig, Sie haben es fast geschafft..",
          "you_need": "Du brauchst:",
          // done modal
          "congrats_title": "🎉 Glückwunsch!",
          "goal_reached": "Du hast dein Ziel nach %s Tagen erreicht!",
          "started_at": "Gesamtbewertung:",
          "improved_by": "Sie haben %s Verbesserung erreicht!",
          "detailed_stats": "Detaillierte Statistiken",
          "later": "Hurra! Ich schaue später nach.",
          // sure delete modal
          "delete": "Löschen",
          "attention": "Achtung!",
          "attention_body":
              "Ihr Ziel und Ihr Fortschritt gehen für immer verloren und können nicht wiederhergestellt werden.",
        },
      };

  String get i18n => localize(this, _t);
  String fill(List<Object> params) => localizeFill(this, params);
  String plural(int value) => localizePlural(value, this, _t);
  String version(Object modifier) => localizeVersion(modifier, this, _t);
}
