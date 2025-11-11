import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../localization/localized_text.dart';
import '../localization/app_localizations.dart';
import '../services/app_launch_service.dart';

class OnboardingSplash extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingSplash({super.key, required this.onFinished});

  @override
  State<OnboardingSplash> createState() => _OnboardingSplashState();
}

class _OnboardingSplashState extends State<OnboardingSplash> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<_OnboardingSlideData> _slides = const [
    _OnboardingSlideData(
      icon: Icons.psychology_alt_rounded,
      titleKey: 'talkToMahoro',
      descriptionKey: 'aiSupportCompanion',
      gradientColors: [Color(0xFF8A4FFF), Color(0xFFB388FF)],
    ),
    _OnboardingSlideData(
      icon: Icons.forum_rounded,
      titleKey: 'joinForum',
      descriptionKey: 'connectWithCommunity',
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    ),
    _OnboardingSlideData(
      icon: Icons.health_and_safety_rounded,
      titleKey: 'sos',
      descriptionKey: 'youAreNotAlone',
      gradientColors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await AppLaunchService.markOnboardingComplete();
    if (!mounted) return;
    widget.onFinished();
  }

  void _handleNext() {
    if (_currentPage == _slides.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    AppLocalizations.of(context).translate('skipTour'),
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white70
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() {
                    _currentPage = index;
                  }),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double scale = 1.0;
                        double opacity = 1.0;
                        if (_pageController.hasClients &&
                            _pageController.position.hasContentDimensions) {
                          final page = _pageController.page ?? 0.0;
                          final distance = (page - index).abs();
                          scale = (1 - (distance * 0.1)).clamp(0.9, 1.0);
                          opacity = (1 - (distance * 0.3)).clamp(0.3, 1.0);
                        }
                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: child,
                          ),
                        );
                      },
                      child: _OnboardingSlide(data: slide),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildPageIndicator(isDarkMode),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A4FFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: LocalizedText(
                    _currentPage == _slides.length - 1 ? 'getStarted' : 'next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).translate('hopeCoreHub'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 12,
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color(0xFF8A4FFF)
                    : (isDarkMode ? Colors.white12 : Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingSlideData data;

  const _OnboardingSlide({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: data.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                LocalizedText(
                  data.titleKey,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LocalizedText(
                    data.descriptionKey,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final List<Color> gradientColors;

  const _OnboardingSlideData({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.gradientColors,
  });
}

