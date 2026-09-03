import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  late final double _width;
  late final double _height;
  late final double _shortestSide;

  Responsive(this.context) {
    final size = MediaQuery.of(context).size;
    _width = size.width;
    _height = size.height;
    _shortestSide = size.shortestSide;
  }

  bool get isMobile => _shortestSide < 600;
  bool get isTablet => _shortestSide >= 600 && _shortestSide < 900;
  bool get isDesktop => _shortestSide >= 900;

  double get cardWidth {
    if (isDesktop) return 480;
    if (isTablet) return _width * 0.6;
    return double.infinity;
  }

  double get screenPadding {
    if (isDesktop) return _width * 0.25;
    if (isTablet) return _width * 0.15;
    return 24.0;
  }

  double get verticalPadding {
    if (isDesktop) return _height * 0.06;
    if (isTablet) return 40.0;
    return 32.0;
  }

  double get logoSize {
    if (isDesktop) return 70;
    if (isTablet) return 62;
    return 56;
  }

  double get formTitleSize {
    if (isDesktop) return 24;
    if (isTablet) return 22;
    return 20;
  }

  double get appNameSize {
    if (isDesktop) return 30;
    if (isTablet) return 27;
    return 24;
  }

  double get cardPadding {
    if (isDesktop) return 36;
    if (isTablet) return 30;
    return 24;
  }

  double get fieldGap {
    if (isTablet || isDesktop) return 18;
    return 16;
  }

  double get buttonHeight {
    if (isTablet || isDesktop) return 54;
    return 50;
  }

  double get width => _width;
  double get height => _height;
}
