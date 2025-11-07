import 'package:flutter/material.dart';
import 'app_localizations.dart';
import '../utils/accessibility_utils.dart';

class LocalizedText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LocalizedText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Get accessible text style with font size scaling applied
    final accessibleStyle = AccessibilityUtils.getTextStyle(
      context,
      baseStyle: style,
    );

    return Text(
      localizations.translate(textKey),
      style: accessibleStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
