import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Shared motion vocabulary for pushing screens.
Route<T> sharedAxisRoute<T>(
  Widget page, {
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        fillColor: Colors.transparent,
        child: child,
      );
    },
  );
}

Future<T?> pushScreen<T>(
  BuildContext context,
  Widget page, {
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) {
  return Navigator.of(context).push<T>(sharedAxisRoute<T>(page, type: type));
}
