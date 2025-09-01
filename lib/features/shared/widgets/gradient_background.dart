import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final double logoOpacity;
  final EdgeInsets? padding;
  final Widget? floatingActionButton;

  const GradientBackground({
    super.key,
    required this.child,
    this.showLogo = true,
    this.logoOpacity = 0.1,
    this.padding,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: [
          if (showLogo)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: logoOpacity,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                      alignment: Alignment.topCenter,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          Container(padding: padding, child: child),
          if (floatingActionButton != null)
            Positioned(child: floatingActionButton!),
        ],
      ),
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool showLogo;
  final double logoOpacity;
  final EdgeInsets? padding;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.showLogo = true,
    this.logoOpacity = 0.1,
    this.padding,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryGreen.withValues(
                  alpha: 0.8 + 0.2 * _animation.value,
                ),
                AppColors.darkGreen.withValues(
                  alpha: 0.3 + 0.2 * _animation.value,
                ),
                Colors.transparent,
              ],
              stops: [0.0, 0.3 + 0.2 * _animation.value, 1.0],
            ),
          ),
          child: Stack(
            children: [
              if (widget.showLogo)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: widget.logoOpacity,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          alignment: Alignment.topCenter,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(padding: widget.padding, child: widget.child),
            ],
          ),
        );
      },
    );
  }
}

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showGradient;
  final bool animateGradient;
  final bool showLogo;
  final EdgeInsets? padding;
  final bool resizeToAvoidBottomInset;

  const CustomScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showGradient = true,
    this.animateGradient = false,
    this.showLogo = true,
    this.padding,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget scaffoldBody = body;

    if (showGradient) {
      if (animateGradient) {
        scaffoldBody = AnimatedGradientBackground(
          showLogo: showLogo,
          padding: padding,
          child: body,
        );
      } else {
        scaffoldBody = GradientBackground(
          showLogo: showLogo,
          padding: padding,
          child: body,
        );
      }
    } else if (padding != null) {
      scaffoldBody = Padding(padding: padding!, child: body);
    }

    return Scaffold(
      extendBodyBehindAppBar: appBar != null,
      appBar: appBar,
      body: scaffoldBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: showGradient ? Colors.transparent : AppColors.background,
    );
  }
}
