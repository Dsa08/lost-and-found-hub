import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return ScreenSize.desktop;
    if (width >= 600) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) => of(context) == ScreenSize.mobile;
  static bool isTablet(BuildContext context) => of(context) == ScreenSize.tablet;
  static bool isDesktop(BuildContext context) => of(context) == ScreenSize.desktop;
}

/// Widget yang otomatis pilih layout berdasarkan ukuran layar
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final size = Responsive.of(context);
    switch (size) {
      case ScreenSize.desktop:
        return desktop;
      case ScreenSize.tablet:
        return tablet ?? desktop;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}