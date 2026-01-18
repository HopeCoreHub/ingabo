import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

/// A base screen widget that automatically rebuilds when the language changes.
/// All screen widgets should extend this class instead of StatefulWidget or StatelessWidget.
abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});
}

abstract class BaseScreenState<T extends BaseScreen> extends State<T> {
  @override
  Widget build(BuildContext context) {
    // Listen to language changes and rebuild the screen
    Provider.of<LanguageProvider>(context);

    return buildScreen(context);
  }

  /// Override this method to build your screen UI
  Widget buildScreen(BuildContext context);
}

/// A base screen widget for StatelessWidget screens
abstract class BaseStatelessScreen extends StatelessWidget {
  const BaseStatelessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to language changes and rebuild the screen
    Provider.of<LanguageProvider>(context);

    return buildScreen(context);
  }

  /// Override this method to build your screen UI
  Widget buildScreen(BuildContext context);
}
