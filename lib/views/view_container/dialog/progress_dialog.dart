import 'package:flutter/material.dart';

/// 通信中のぐるぐる表示
void showProgressDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .25),
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

/// 通信中のぐるぐる非表示
void dismissProgressDialog(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
