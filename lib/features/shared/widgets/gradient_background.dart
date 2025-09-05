import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final double logoOpacity;
  final EdgeInsets? padding;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GradientBackground({
    super.key,
    required this.child,
    this.showLogo = true,
    this.logoOpacity = 0.1,
    this.padding,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
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

          if (padding != null)
            Padding(
              padding: padding!,
              child: child,
            )
          else
            child,
          if (floatingActionButton != null)
            Positioned(
              bottom: 100, // Account for bottom navigation
              right: 16,
              child: floatingActionButton!,
            ),
        ],
      ),
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
    Widget scaffoldBody = GradientBackground(
      showLogo: showLogo,
      padding: padding,
      child: body,
    );

    return Scaffold(
      extendBodyBehindAppBar: appBar != null,
      appBar: appBar,
      body: scaffoldBody,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: showGradient ? Colors.transparent : AppColors.background,
    );
  }
}
