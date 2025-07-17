// method to show the snack bar
import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context, {
  required String message,
  Duration? duration,
}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration ?? Duration(seconds: 4),
    ),
  );
}
