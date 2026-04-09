class NavigationRoute {
  late String _name;
  late int _index;

  List<String> _internalPageMap;

  NavigationRoute({List<String>? pageMap})
      : _internalPageMap = pageMap ?? ["home", "grades", "timetable"] {
    _index = 0;
    _name = _internalPageMap[0];
  }

  String get name => _name;
  int get index => _index;

  set name(String n) {
    _name = n;
    final i = _internalPageMap.indexOf(n);
    _index = i >= 0 ? i : 0;
  }

  set index(int i) {
    _index = i.clamp(0, _internalPageMap.length - 1);
    _name = _internalPageMap[_index];
  }

  /// Updates the page map and preserves the current page if still present.
  void updatePageMap(List<String> pageMap) {
    if (pageMap.isEmpty) return;
    final currentName = _name;
    _internalPageMap = pageMap;
    final newIndex = _internalPageMap.indexOf(currentName);
    if (newIndex >= 0) {
      _index = newIndex;
    } else {
      _index = 0;
      _name = _internalPageMap[0];
    }
  }
}
