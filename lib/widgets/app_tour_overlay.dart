import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../localization/localized_text.dart';

class AppTourOverlay {
  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'app-tour',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const _AppTourDialog(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }
}

class _AppTourDialog extends StatefulWidget {
  const _AppTourDialog();

  @override
  State<_AppTourDialog> createState() => _AppTourDialogState();
}

class _AppTourDialogState extends State<_AppTourDialog> {
  late final PageController _controller;
  int _currentStep = 0;

  final List<_TourStep> _steps = const [
    _TourStep(
      icon: Icons.psychology_rounded,
      titleKey: 'talkToMahoro',
      descriptionKey: 'aiSupportCompanion',
      color: Color(0xFF8A4FFF),
    ),
    _TourStep(
      icon: Icons.forum_rounded,
      titleKey: 'joinForum',
      descriptionKey: 'connectWithCommunity',
      color: Color(0xFF0EA5E9),
    ),
    _TourStep(
      icon: Icons.health_and_safety_rounded,
      titleKey: 'sos',
      descriptionKey: 'youAreNotAlone',
      color: Color(0xFF22C55E),
    ),
    _TourStep(
      icon: Icons.settings_rounded,
      titleKey: 'settings',
      descriptionKey: 'customizeYourExperience',
      color: Color(0xFFF97316),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentStep == _steps.length - 1) {
      Navigator.of(context).pop();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: LocalizedText(
                    'skipTour',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white70
                          : const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 240,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _TourCard(step: step);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 28 : 10,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? const Color(0xFF8A4FFF)
                              : (isDarkMode
                                  ? Colors.white12
                                  : Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A4FFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: LocalizedText(
                    _currentStep == _steps.length - 1
                        ? 'getStarted'
                        : 'next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final _TourStep step;

  const _TourCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [step.color.withOpacity(0.65), step.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 20),
          LocalizedText(
            step.titleKey,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LocalizedText(
            step.descriptionKey,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourStep {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final Color color;

  const _TourStep({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.color,
  });
}
