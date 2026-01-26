import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTextStyle { hero, headline, title, body, bodySmall, action, quote }

class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AppText(
    this.text, {
    super.key,
    this.style = AppTextStyle.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  });

  // Factory constructors for convenience
  const AppText.hero(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  }) : style = AppTextStyle.hero;
  const AppText.headline(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  }) : style = AppTextStyle.headline;
  const AppText.title(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  }) : style = AppTextStyle.title;
  const AppText.body(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  }) : style = AppTextStyle.body;
  const AppText.bodySmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  }) : style = AppTextStyle.bodySmall;
  const AppText.action(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  }) : style = AppTextStyle.action;
  const AppText.quote(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
  }) : style = AppTextStyle.quote;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: _getStyle(
        context,
      ).copyWith(color: color, fontSize: fontSize, fontWeight: fontWeight),
    );
  }

  TextStyle _getStyle(BuildContext context) {
    // Unified Font: Inter
    // Hierarchy is established via Weight and Size, not Font Family.
    switch (style) {
      case AppTextStyle.hero:
        return GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold, // Strongest
          letterSpacing: -1.0, // Tight for display
          color: Colors.black87,
        );
      case AppTextStyle.headline:
        return GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        );
      case AppTextStyle.title:
        return GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600, // SemiBold
          color: Colors.black87,
        );
      case AppTextStyle.body:
        return GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
          color: Colors.black87,
        );
      case AppTextStyle.bodySmall:
        return GoogleFonts.inter(
          fontSize: 13, // Slightly readable
          fontWeight: FontWeight.normal,
          color: Colors.grey[600],
        );
      case AppTextStyle.action:
        return GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.0,
        );
      case AppTextStyle.quote:
        return GoogleFonts.inter(
          fontSize: 18,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          height: 1.6,
          color: Colors.white,
        );
    }
  }
}
