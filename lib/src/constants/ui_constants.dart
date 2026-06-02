import 'dart:ui';

/// UI constants for consistent spacing, sizing, and color palette across the app
class UIConstants {
  // Padding constants
  static const double kHorizontalPadding = 24.0;
  static const double kVerticalGap = 12.0;
  static const double kSmallGap = 8.0;
  static const double kMediumGap = 16.0;
  static const double kLargeGap = 24.0;

  // Button constants
  static const double kButtonHorizontalPadding = 24.0;
  static const double kButtonVerticalPadding = 20.0;
  static const double kButtonBorderRadius = 16.0;
  static const double kButtonMinHeight = 56.0;

  // Card constants
  static const double kCardBorderRadius = 20.0;
  static const double kCardPadding = 24.0;
  static const double kCardElevation = 2.0;
  static const double kCardDarkElevation = 4.0;

  // Typography constants
  static const double kHeadlineLineHeight = 1.2;
  static const double kSubheadlineLineHeight = 1.3;
  static const double kBodyLineHeight = 1.5;
  static const double kSmallLineHeight = 1.4;
  static const double kCaptionLineHeight = 1.4;

  // Icon sizes
  static const double kIconSmall = 16.0;
  static const double kIconMedium = 20.0;
  static const double kIconLarge = 24.0;
  static const double kIconXLarge = 32.0;

  // Border widths
  static const double kBorderThin = 1.0;
  static const double kBorderMedium = 1.5;
  static const double kBorderThick = 2.0;

  // Shadow constants
  static const double kShadowBlurSmall = 4.0;
  static const double kShadowBlurMedium = 8.0;
  static const double kShadowBlurLarge = 16.0;
  static const double kShadowOffset = 2.0;

  // Font families
  static const String kPrimaryFont = 'Inter';
  static const String kSecondaryFont = 'PlayfairDisplay';

  // Color palette - Light mode
  static const Color kPrimary = Color(0xFF4A90E2);          // Modern blue
  static const Color kPrimaryLight = Color(0xFF6BA5E8);     // Lighter blue
  static const Color kSecondary = Color(0xFF50C878);        // Modern green
  static const Color kAccent = Color(0xFF5A3D31);           // Dark charcoal (from original theme)
  static const Color kBackground = Color(0xFFFBF7FA);       // Light page background
  static const Color kSurface = Color(0xFFFFFFFF);          // Card surface
  static const Color kText = Color(0xFF1A1A1A);             // Near black
  static const Color kTextLight = Color(0xFF666666);        // Dark gray
  static const Color kTextMuted = Color(0xFF999999);        // Light gray
  static const Color kDivider = Color(0xFFE2D7C5);          // Light divider
  static const Color kError = Color(0xFFE57373);            // Soft red
  static const Color kSuccess = Color(0xFFA8D5BA);          // Light green
  static const Color kMuted = Color(0xFF9A8B7E);            // Muted (from original theme)

  // Additional colors for improved UI
  static const Color kPrimaryDark = Color(0xFF5D4037);       // Modern Warm Brown (original)
  static const Color kSecondaryDark = Color(0xFFD9643E);     // Modern Terracotta Orange (original)
}