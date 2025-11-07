import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ingabo/accessibility_provider.dart';
import 'package:ingabo/theme_provider.dart';

void main() {
  testWidgets('High contrast mode changes UI appearance appropriately', (
    WidgetTester tester,
  ) async {
    // Create a test widget that contains the accessibility provider and app
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              // Get the providers
              final accessibilityProvider = Provider.of<AccessibilityProvider>(
                context,
              );
              final themeProvider = Provider.of<ThemeProvider>(context);

              return Column(
                children: [
                  // Button to toggle high contrast mode
                  ElevatedButton(
                    onPressed: () {
                      accessibilityProvider.toggleHighContrastMode(
                        !accessibilityProvider.highContrastMode,
                      );
                    },
                    child: const Text('Toggle High Contrast'),
                  ),

                  // Button to toggle dark mode
                  ElevatedButton(
                    onPressed: () {
                      themeProvider.toggleDarkMode(!themeProvider.isDarkMode);
                    },
                    child: const Text('Toggle Dark Mode'),
                  ),

                  // Test container that should respond to high contrast mode
                  Container(
                    width: 200,
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          accessibilityProvider.highContrastMode
                              ? (themeProvider.isDarkMode
                                  ? Colors.black
                                  : Colors.white)
                              : Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          accessibilityProvider.highContrastMode
                              ? Border.all(
                                color:
                                    themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                width: 2.0,
                              )
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        'High Contrast: ${accessibilityProvider.highContrastMode}\n'
                        'Dark Mode: ${themeProvider.isDarkMode}',
                        style: TextStyle(
                          color:
                              accessibilityProvider.highContrastMode
                                  ? (themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black)
                                  : Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Initial state should not have high contrast mode enabled
    expect(find.text('High Contrast: false'), findsOneWidget);

    // Tap the button to enable high contrast mode
    await tester.tap(find.text('Toggle High Contrast'));
    await tester.pump();

    // Now high contrast mode should be enabled
    expect(find.text('High Contrast: true'), findsOneWidget);

    // Toggle dark mode
    await tester.tap(find.text('Toggle Dark Mode'));
    await tester.pump();

    // Dark mode should be enabled
    expect(find.text('High Contrast: true\nDark Mode: true'), findsOneWidget);
  });
}
