import 'package:flutter/material.dart';

/// Shows a loading dialog with a message that can be updated.
///
/// Use [dismissLoadingDialog] to close the dialog.
void showLoadingDialog({
  required BuildContext context,
  required LoadingDialogController controller,
  bool barrierDismissible = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => LoadingDialog(controller: controller),
  );
}

/// Dismisses the currently showing loading dialog.
void dismissLoadingDialog(BuildContext context) {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Controller for the loading dialog.
///
/// Use this to update the message displayed in the dialog.
class LoadingDialogController {
  String _message = '';
  Function(String)? _onMessageChanged;

  String get message => _message;

  /// Updates the message displayed in the loading dialog.
  void updateMessage(String newMessage) {
    _message = newMessage;
    if (_onMessageChanged != null) {
      _onMessageChanged!(newMessage);
    }
  }

  void registerCallback(Function(String) callback) {
    _onMessageChanged = callback;
  }
}

/// A dialog that displays a loading indicator and a message.
///
/// The message can be updated using the [LoadingDialogController].
class LoadingDialog extends StatefulWidget {
  final LoadingDialogController controller;

  const LoadingDialog({Key? key, required this.controller}) : super(key: key);

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  late String _message;

  @override
  void initState() {
    super.initState();
    _message = widget.controller.message;
    widget.controller.registerCallback((newMessage) {
      if (mounted) {
        setState(() {
          _message = newMessage;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button from closing dialog
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 