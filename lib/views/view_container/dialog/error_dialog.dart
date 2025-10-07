import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';

Future<void> showErrorDialog(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text(AppStrings.ok),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
