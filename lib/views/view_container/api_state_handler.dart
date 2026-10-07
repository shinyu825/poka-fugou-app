import 'package:flutter/material.dart';
import 'package:poka_fugou_app/constants/strings.dart';
import 'package:poka_fugou_app/view_models/base_viewmodel.dart';
import 'package:poka_fugou_app/views/view_container/dialog/error_dialog.dart';

/// ViewModelの通信中・エラー状態を画面に反映する
///
/// 通信中はぐるぐるを重ねて操作をブロックし、エラーはダイアログで表示する
class ApiStateHandler extends StatefulWidget {
  final BaseViewModel viewModel;
  final Widget child;

  const ApiStateHandler({
    super.key,
    required this.viewModel,
    required this.child,
  });

  @override
  State<ApiStateHandler> createState() => _ApiStateHandlerState();
}

class _ApiStateHandlerState extends State<ApiStateHandler> {
  bool _isShowingError = false;

  void _showErrorIfNeeded() {
    final message = widget.viewModel.errorMessage;
    if (message == null || _isShowingError) return;
    _isShowingError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showErrorDialog(context, AppStrings.error, message);
      _isShowingError = false;
      widget.viewModel.clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        _showErrorIfNeeded();
        return Stack(
          children: [
            child!,
            if (widget.viewModel.isLoading)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: .25),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
