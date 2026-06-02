import 'package:flutter/material.dart';

final debugNavigatorObserver = _DebugNavigatorObserver();

void debugLog(String message) {
  assert(() {
    debugPrint('[PriceMateDebug] ${DateTime.now().toIso8601String()} $message');
    return true;
  }());
}

String routeLabel(Route<dynamic>? route) {
  if (route == null) return 'null';
  return '${route.settings.name ?? route.runtimeType}';
}

class _DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugLog(
      'Navigator didPush ${routeLabel(route)} from ${routeLabel(previousRoute)}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugLog(
      'Navigator didPop ${routeLabel(route)} to ${routeLabel(previousRoute)}',
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugLog(
      'Navigator didRemove ${routeLabel(route)} previous ${routeLabel(previousRoute)}',
    );
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    debugLog(
      'Navigator didReplace ${routeLabel(oldRoute)} with ${routeLabel(newRoute)}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
