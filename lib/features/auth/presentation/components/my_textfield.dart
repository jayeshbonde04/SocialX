import 'package:flutter/material.dart';
import 'package:socialx/themes/app_colors.dart';

class MyTextfield extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscuretext;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;
  final Color? cursorColor;
  final Color? fillColors;
  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscuretext,
    this.style,
    this.decoration,
    this.maxLines,
    this.cursorColor,
    this.fillColors,
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
    final defaultDecoration = InputDecoration(
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
      hintStyle: const TextStyle(
        color: Color(0xFFB3B3B3),
        fontSize: 14,
      ),
      fillColor: AppColors.third,
      filled: true,
    );

    final mergedDecoration = widget.decoration != null
        ? defaultDecoration.copyWith(
            prefixIcon: widget.decoration!.prefixIcon,
            suffixIcon: widget.obscuretext
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFFB3B3B3),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : widget.decoration!.suffixIcon,
            border: widget.decoration!.border,
            contentPadding: widget.decoration!.contentPadding,
          )
        : defaultDecoration.copyWith(
            suffixIcon: widget.obscuretext
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFFB3B3B3),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
          );

    return TextField(
      controller: widget.controller,
      obscureText: widget.obscuretext && !_isPasswordVisible,
      style: widget.style,
      maxLines: widget.obscuretext ? 1 : widget.maxLines,
      cursorColor: widget.cursorColor ?? Theme.of(context).colorScheme.primary,
      decoration: mergedDecoration,
    );
  }
}
