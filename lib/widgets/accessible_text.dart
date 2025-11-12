import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../accessibility_provider.dart';
import '../theme_provider.dart';
import '../utils/accessibility_utils.dart';
import '../localization/app_localizations.dart';

class AccessibleText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableTextToSpeech;
  final bool selectable;

  const AccessibleText({
    super.key,
    required this.textKey,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableTextToSpeech = false,
    this.selectable = false,
  });

  // Static method to get translated text
  static String getTranslatedText(BuildContext context, String textKey) {
    final localizations = AppLocalizations.of(context);
    return localizations.translate(textKey);
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);

    // Get accessible text style
    final accessibleStyle = AccessibilityUtils.getTextStyle(
      context,
      baseStyle: style,
    );

    // Get translated text
    final translatedText = getTranslatedText(context, textKey);

    // Create the text widget
    Widget textWidget =
        selectable
            ? SelectableText(
              translatedText,
              style: accessibleStyle,
              textAlign: textAlign,
              maxLines: maxLines,
            )
            : Text(
              translatedText,
              style: accessibleStyle,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
            );

    // If text-to-speech is enabled and requested for this text
    if (accessibilityProvider.textToSpeech && enableTextToSpeech) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: textWidget),
          const SizedBox(width: 4),
          AccessibilityUtils.createTextToSpeechButton(
            context,
            textToSpeak: translatedText,
            size: 16,
          ),
        ],
      );
    }

    return textWidget;
  }
}

class AccessibleTextField extends StatefulWidget {
  final String hintTextKey;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enableVoiceToText;

  const AccessibleTextField({
    super.key,
    required this.hintTextKey,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.enableVoiceToText = false,
  });

  @override
  State<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends State<AccessibleTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Get accessible text style
    final accessibleStyle = AccessibilityUtils.getTextStyle(
      context,
      fontSize: 16,
    );

    // Get accessible hint text style
    final accessibleHintStyle = AccessibilityUtils.getTextStyle(
      context,
      fontSize: 16,
      color: isDarkMode ? Colors.white54 : Colors.black54,
    );

    // Get translated hint text
    final translatedHint = AccessibleText.getTranslatedText(
      context,
      widget.hintTextKey,
    );

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            style: accessibleStyle,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: translatedHint,
              hintStyle: accessibleHintStyle,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (accessibilityProvider.voiceToText && widget.enableVoiceToText)
          AccessibilityUtils.createVoiceToTextButton(
            context,
            onResult: (text) {
              final currentText = widget.controller.text;
              widget.controller.text =
                  currentText.isEmpty ? text : '$currentText $text';
              widget.controller.selection = TextSelection.fromPosition(
                TextPosition(offset: widget.controller.text.length),
              );
              if (widget.onChanged != null) {
                widget.onChanged!(widget.controller.text);
              }
            },
          ),
      ],
    );
  }
}
