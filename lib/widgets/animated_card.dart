import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/animation_utils.dart';
import '../theme_provider.dart';

/// An animated card widget that provides consistent animations
/// for card interactions throughout the app
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool animate;
  final bool showBounceOnHover;
  final int animationDelayIndex;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.elevation = 0,
    this.animate = true,
    this.showBounceOnHover = true,
    this.animationDelayIndex = 0,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: ThemeProvider.animationDurationShort,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: ThemeProvider.animationCurveSnappy,
      ),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovering) {
    if (!widget.showBounceOnHover || widget.onTap == null) return;

    setState(() {
      _isHovering = isHovering;
    });

    if (isHovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final cardContent = Material(
      color: Colors.transparent,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    final decoratedCard = AnimatedContainer(
      duration: ThemeProvider.animationDurationMedium,
      decoration: BoxDecoration(
        color:
            widget.backgroundColor ??
            (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: ((_isHovering ? 0.1 : 0.05) * 255).round(),
            ),
            blurRadius:
                _isHovering ? widget.elevation * 3 : widget.elevation * 2,
            spreadRadius: _isHovering ? widget.elevation : widget.elevation / 2,
            offset: Offset(
              0,
              _isHovering ? widget.elevation * 0.5 : widget.elevation,
            ),
          ),
        ],
      ),
      child: cardContent,
    );

    Widget result =
        widget.onTap != null
            ? MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: GestureDetector(
                onTap: widget.onTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedScale(
                  scale: _isHovering ? 1.02 : 1.0,
                  duration: ThemeProvider.animationDurationShort,
                  curve: ThemeProvider.animationCurveSnappy,
                  child: decoratedCard,
                ),
              ),
            )
            : decoratedCard;

    if (widget.animate) {
      result = result.withStaggeredAnimation(widget.animationDelayIndex);
    }

    return result;
  }
}
