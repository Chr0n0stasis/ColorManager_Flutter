enum LayoutAnchorZone {
  materials,
  detail,
  composePreview,
}

class LayoutContract {
  const LayoutContract._();

  /// Desktop-like three-zone split starts from this width.
  static const double expandedBreakpoint = 1280;

  /// Tablet-like wide split starts from this width.
  static const double mediumBreakpoint = 900;

  /// Keep semantic order equivalent to desktop left-center-right.
  static const List<LayoutAnchorZone> semanticOrder = <LayoutAnchorZone>[
    LayoutAnchorZone.materials,
    LayoutAnchorZone.detail,
    LayoutAnchorZone.composePreview,
  ];

  /// Approximate width ratios for expanded mode.
  static const int expandedLeftFlex = 24;
  static const int expandedCenterFlex = 46;
  static const int expandedRightFlex = 30;

  /// Approximate width ratios for medium mode.
  static const int mediumLeftFlex = 28;
  static const int mediumCenterFlex = 42;
  static const int mediumRightFlex = 30;
}
