import 'package:flutter/material.dart';

class MyTextfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscuretext;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;
  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscuretext,
    this.style,
    this.decoration,
    this.maxLines,
  });

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  late bool _isPasswordVisible;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = !widget.obscuretext;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscuretext && !_isPasswordVisible,
      style: widget.style,
      maxLines: widget.obscuretext ? 1 : widget.maxLines,
      decoration: (widget.decoration ?? InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
        ),
        fillColor: Theme.of(context).colorScheme.secondary,
        filled: true,
      )).copyWith(
        suffixIcon: widget.obscuretext
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }
}
