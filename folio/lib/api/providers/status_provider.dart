import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

enum Status { network, maintenance, syncing, apiError }

class StatusProvider extends ChangeNotifier {
  final List<Status> _stack = [];
  double _progress = 0.0;
  ConnectivityResult _networkType = ConnectivityResult.none;
  ConnectivityResult get networkType => _networkType;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  StatusProvider() {
    _handleNetworkChanges();
    // Initial check: verify actual internet connectivity on startup.
    Connectivity().checkConnectivity().then((results) {
      _networkType = results[0];
      if (results[0] == ConnectivityResult.none) {
        _setOffline();
      } else {
        _verifyInternet();
      }
    });
  }

  Status? getStatus() => _stack.isNotEmpty ? _stack[0] : null;
  double get progress => _progress;

  void _handleNetworkChanges() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((event) {
      _networkType = event[0];
      if (event[0] == ConnectivityResult.none) {
        _setOffline();
      } else {
        // Connected to a network – verify there is actual internet access.
        _verifyInternet();
      }
    });
  }

  /// Performs a lightweight DNS lookup to confirm real internet access.
  /// Called whenever connectivity_plus reports a non-none network.
  void _verifyInternet() {
    InternetAddress.lookup('google.com').then((result) {
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        // Real internet confirmed – clear the network error if present.
        if (_stack.contains(Status.network)) {
          _stack.remove(Status.network);
          notifyListeners();
        }
      } else {
        _setOffline();
      }
    }).catchError((_) => _setOffline());
  }

  void _setOffline() {
    if (!_stack.contains(Status.network)) {
      _stack.remove(Status.apiError);
      _stack.insert(0, Status.network);
      notifyListeners();
    }
  }

  void triggerRequest(http.Response res) {
    if (res.headers.containsKey("x-maintenance-mode") ||
        res.statusCode == 503) {
      if (!_stack.contains(Status.maintenance)) {
        _stack.insert(0, Status.maintenance);
        notifyListeners();
      }
    } else {
      if (_stack.contains(Status.maintenance)) {
        _stack.remove(Status.maintenance);
        notifyListeners();
      }
    }

    if (res.body == 'invalid_grant' ||
        res.body.replaceAll(' ', '') == '' ||
        res.statusCode == 400) {
      if (!_stack.contains(Status.apiError) &&
          !_stack.contains(Status.network)) {
        if (res.statusCode == 401) return;
        _stack.insert(0, Status.apiError);
        notifyListeners();
      }
    } else {
      if (_stack.contains(Status.apiError) &&
          res.request?.url.path != '/nonce') {
        _stack.remove(Status.apiError);
        notifyListeners();
      }
    }
  }

  void triggerSync({required int current, required int max}) {
    double prev = _progress;

    if (!_stack.contains(Status.syncing)) {
      _stack.add(Status.syncing);
      _progress = 0.0;
      notifyListeners();
    }

    if (max == 0) {
      _progress = 0.0;
    } else {
      _progress = current / max;
    }

    if (_progress == 1.0) {
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 250), () {
        _stack.remove(Status.syncing);
        notifyListeners();
      });
    } else if (progress != prev) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
