import 'package:flutter/material.dart';

PageRoute<T> buildScrollRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return page;
    },
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      final Animation<Offset> position = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      return SlideTransition(
        position: position,
        child: child,
      );
    },
  );
}
