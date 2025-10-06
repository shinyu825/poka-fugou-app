import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';

void showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // ダイアログ外タップで閉じないようにする
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text(AppStrings.ok),
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
            },
          ),
        ],
      );
    },
  );
}
