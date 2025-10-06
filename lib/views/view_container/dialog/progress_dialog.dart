import 'package:flutter/material.dart';

void showProgressDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .25),
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

void dismissProgressDialog(BuildContext context) {
  if (Navigator.canPop(context)) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
