import 'package:flutter/material.dart';

class LightPopupHandler {
  static void showPopup(BuildContext context, double intensity) {
    if (intensity >= 4700.0) {
      _showAlert(context, 'Warning!', 'Too much brightness can be harmful to your eyes.');
    } else if (intensity <= 10.0) {
      _showAlert(context, 'Warning!', 'Too little light can be harmful to your eyes.');
    }
  }

  static void _showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
