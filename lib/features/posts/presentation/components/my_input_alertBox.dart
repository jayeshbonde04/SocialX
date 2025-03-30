import 'package:flutter/material.dart';

// Define the MyInputAlertBox widget
class MyInputAlertBox extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final VoidCallback onPressed;
  final String onPressedText;

  const MyInputAlertBox({
    super.key,
    required this.textController,
    required this.hintText,
    required this.onPressed,
    required this.onPressedText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Post"),
      content: TextField(
        controller: textController,
        decoration: InputDecoration(hintText: hintText),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(onPressedText),
        ),
      ],
    );
  }
}