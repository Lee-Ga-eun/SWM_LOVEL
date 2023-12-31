import 'package:flutter/material.dart';
import 'package:yoggo/constants.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final int? maxLines;

  CustomText(
    this.text, {
    this.style,
    this.strutStyle,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style != null) ? customTextStyle.merge(style) : customTextStyle,
      textAlign: textAlign,
      strutStyle: strutStyle,
      maxLines: maxLines,
    );
  }
}

const TextStyle customTextStyle = TextStyle(
  fontFamily: 'Suit',
  fontWeight: FontWeight.w500,
);
