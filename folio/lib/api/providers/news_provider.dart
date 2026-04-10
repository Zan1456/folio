// ignore_for_file: use_build_context_synchronously
import 'package:folio/api/client.dart';
import 'package:folio/models/news.dart';
import 'package:folio/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewsProvider extends ChangeNotifier {
  late List<News> _news;
  bool show = false;
  late BuildContext _context;

  List<News> get news => _news;

  NewsProvider({
    List<News> initialNews = const [],
    required BuildContext context,
  }) {
    _news = List.from(initialNews);
    _context = context;
  }

  Future<void> restore() async {
    var seen_ = Provider.of<SettingsProvider>(_context, listen: false).seenNews;

    if (seen_.isEmpty) {
      var news_ = await FilcAPI.getNews();
      if (news_ != null) {
        _news = news_;
        show = true;
      }
    }
  }

  Future<void> fetch() async {
    var news_ = await FilcAPI.getNews();
    if (news_ == null) return;

    show = false;
    _news = news_;

    for (var news in news_) {
      if (news.expireDate.isAfter(DateTime.now()) &&
          Provider.of<SettingsProvider>(_context, listen: false)
                  .seenNews
                  .contains(news.id) ==
              false) {
        show = true;
        Provider.of<SettingsProvider>(_context, listen: false)
            .update(seenNewsId: news.id);
        notifyListeners();
      }
    }
  }

  void lock() => show = false;

  void release() {}
}
