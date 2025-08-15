import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme_provider.dart';

/// A collection of animation utilities to ensure consistent animations throughout the app
class AnimationUtils {
  /// Creates a staggered animation for a list of children
  /// Each child will be animated with the given effects, with a delay based on its index
  static List<Widget> staggeredList({
    required List<Widget> children,
    required int startIndex,
    required Duration staggerDuration,
    required List<Effect> effects,
    Duration? initialDelay,
  }) {
    return List.generate(
      children.length,
      (index) {
        final delay = (initialDelay ?? Duration.zero) + 
          (staggerDuration * (index + startIndex));
        
        return children[index]
          .animate()
          .effect(delay: delay)
          .animate(effects: effects);
      },
    );
  }

  /// Returns a standard set of entrance effects
  static List<Effect> get standardEntranceEffects => [
    const FadeEffect(
      duration: ThemeProvider.animationDurationMedium,
      curve: ThemeProvider.animationCurveDefault,
    ),
    const SlideEffect(
      begin: Offset(0, 0.1),
      end: Offset.zero,
      duration: ThemeProvider.animationDurationMedium,
      curve: ThemeProvider.animationCurveDefault,
    ),
  ];

  /// Returns a standard set of tap effects
  static List<Effect> get tapEffects => [
    ScaleEffect(
      duration: ThemeProvider.animationDurationShort,
      curve: ThemeProvider.animationCurveFast,
    ),
  ];

  /// Returns a standard set of success effects
  static List<Effect> get successEffects => [
    const ShimmerEffect(
      duration: ThemeProvider.animationDurationMedium,
      color: Color(0xFF8A4FFF),
      curve: ThemeProvider.animationCurveDefault,
    ),
  ];

  /// Returns a standard set of attention effects
  static List<Effect> get attentionEffects => [
    const ShakeEffect(
      duration: ThemeProvider.animationDurationMedium,
      curve: ThemeProvider.animationCurveSnappy,
    ),
  ];
  
  /// Creates a hero transition with a fade effect
  static Widget heroWithFade(Widget child, String tag) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return FadeTransition(
          opacity: animation,
          child: flightDirection == HeroFlightDirection.push
              ? toHeroContext.widget
              : fromHeroContext.widget,
        );
      },
      child: child,
    );
  }

  /// Creates a custom page route with professional transitions
  static Route<T> customPageRoute<T>({
    required Widget page,
    bool fullScreenDialog = false,
    Duration? customDuration,
    Curve? customCurve,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = customCurve ?? ThemeProvider.pageTransitionCurve;
        
        // Define secondary page transition (the page being navigated from)
        final secondaryCurvedAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: curve,
        );
        
        // Define primary page transition (the page being navigated to)
        final primaryCurvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );
        
        // Apply different transitions based on fullScreenDialog flag
        if (fullScreenDialog) {
          // Full screen dialog uses a slide up and fade in transition
          return Stack(
            children: [
              // Fade out the previous page
              FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.5).animate(secondaryCurvedAnimation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 0.95).animate(secondaryCurvedAnimation),
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Slide up the new page
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.15),
                  end: Offset.zero,
                ).animate(primaryCurvedAnimation),
                child: FadeTransition(
                  opacity: primaryCurvedAnimation,
                  child: child,
                ),
              ),
            ],
          );
        } else {
          // Regular page transition
          return FadeTransition(
            opacity: primaryCurvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0.0),
                end: Offset.zero,
              ).animate(primaryCurvedAnimation),
              child: child,
            ),
          );
        }
      },
      transitionDuration: customDuration ?? ThemeProvider.pageTransitionDuration,
      reverseTransitionDuration: customDuration ?? ThemeProvider.pageTransitionDuration,
      fullscreenDialog: fullScreenDialog,
    );
  }
}

/// Extension to add animations to any widget
extension AnimateWidgetExtension on Widget {
  /// Adds entrance animation to a widget
  Widget withEntranceAnimation({Duration? delay}) {
    return animate()
        .effect(delay: delay ?? Duration.zero)
        .animate(effects: AnimationUtils.standardEntranceEffects);
  }

  /// Adds staggered entrance animation for lists
  Widget withStaggeredAnimation(int index, {Duration? initialDelay}) {
    final delay = (initialDelay ?? Duration.zero) + 
      (ThemeProvider.staggerInterval * index);
    
    return animate()
        .effect(delay: delay)
        .animate(effects: AnimationUtils.standardEntranceEffects);
  }

  /// Adds tap animation to a widget
  Widget withTapAnimation() {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .animate(effects: AnimationUtils.tapEffects);
  }
}

/// A builder that wraps a widget with staggered animations
typedef StaggeredWidgetBuilder = Widget Function(BuildContext context, int index);

/// A widget that applies staggered animations to its children
class StaggeredAnimationList extends StatelessWidget {
  final int itemCount;
  final StaggeredWidgetBuilder itemBuilder;
  final Duration? initialDelay;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  const StaggeredAnimationList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.initialDelay,
    this.scrollController,
    this.shrinkWrap = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      controller: scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return itemBuilder(context, index)
            .withStaggeredAnimation(index, initialDelay: initialDelay);
      },
    );
  }
} 