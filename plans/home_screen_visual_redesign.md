# Home Screen Visual Design & Styling Redesign

## Objective
Transform the ScrapChef home screen into a polished, professional-grade interface with modern design principles, consistent theming, and enhanced visual hierarchy.

## Current Issues
1. **Flat/dated aesthetic** - Header gradient is too subtle, cards lack depth
2. **Inconsistent styling** - Mix of custom containers and native Material widgets
3. **Poor typography** - Hardcoded font sizes instead of using GoogleFonts theme
4. **Hardcoded colors** - Some RGB values remain instead of Theme.of(context).colorScheme
5. **Cramped spacing** - Inconsistent margins and padding throughout
6. **Action panel lacks polish** - Button styling doesn't match modern design

## Implementation Plan

### 1. Hero Header - Professional Brand Section
**File:** lib/src/screens/home_screen.dart (`_HeroHeader`)

**Changes:**
- Replace raw Container with AppCard widget for consistent card styling
- Enhance gradient with primary → secondary color transition for visual impact
- Increase elevation shadow for depth with proper dark-mode shadow
- Use `Theme.of(context).textTheme` with GoogleFonts for brand name
- Update metrics display with StatBadge widgets for consistency
- Replace hardcoded ItemCount badge with cleaner StatBadge styling
- Add proper icon sizing and color from colorScheme

**Design:** 
```
┌──────────────────────────────────────┐
│ ScrapChef (Lora w800)          [N] ⚙️│
│ Turn scraps into suppers            │
│ ───────────────────────────────────  │
│ ✓ N scraps scanned                  │
│ ₱ Estimated X saved                 │
└──────────────────────────────────────┘
```

### 2. Action Panel - Modern CTA Button
**File:** lib/src/screens/home_screen.dart (`_ActionPanel`)

**Changes:**
- Replace animated.AnimatedButton with AppButton widget
- Use `fullWidth: true` for full-width primary action
- Leverage AppButton's built-in gradient and shadow
- Remove wrapping Container with redundant padding
- Add icon integration via AppButton's text-based detection
- Set proper minimum height (56dp) and border radius

**Design:**
```
┌──────────────────────────────────────┐
│      📷 Open camera                  │
└──────────────────────────────────────┘
```

### 3. TabBar - Enhanced Navigation
**File:** lib/src/screens/home_screen.dart (build method)

**Changes:**
- Wrap TabBar in AppCard for consistent container styling
- Update indicator to use primary color with rounder shape
- Add labelStyle using Theme textTheme for proper GoogleFonts
- Increase indicator weight for better visibility
- Add padding using UIConstants

**Design:**
```
┌──────────────────────────────────────┐
│  📷 Scan     │   🗑️ Bin             │
│  ────────────│                        │
└──────────────────────────────────────┘
```

### 4. Section Cards - Consistent Card Design
**File:** lib/src/screens/home_screen.dart (`_SectionCard`, `_MetricCard`, `_ImpactLedger`)

**Changes:**
- Replace Card with AppCard for consistent elevation and shape
- Section Card titles use Lora font from textTheme
- Metrics use OpenSans for readable values
- Impact ledger uses proper icon sizing from colorScheme
- All using UIConstants for padding/spacing

### 5. Scan Tab Content - Improved Readability
**File:** lib/src/screens/home_screen.dart (`_ScanTab`)

**Changes:**
- Replace `_SectionCard` with AppCard
- `_MetricCard` uses AppCard with proper padding
- `_LatestScanCard` uses AppCard
- `_ImpactLedger` uses AppCard
- All typography from Theme textTheme
- Consistent spacing via UIConstants

### 6. Inventory Tab - Cleaner Layout
**File:** lib/src/screens/home_screen.dart (`_InventoryTab`, `_InventoryTile`)

**Changes:**
- Replace raw containers with AppCard for inventory tiles
- Use colorScheme for all colors, remove hardcoded Colors.white
- Theme-friendly selection states
- Proper dark mode colors using colorScheme

### 7. Color Scheme Optimization
**File:** lib/src/screens/home_screen.dart (all private widgets)

**Changes:**
- Replace `Color.fromRGBO(0, 0, 0, 0.05)` with `colorScheme.onSurface.withAlpha(13)`
- Replace `Color.fromRGBO(212, 229, 208, 0.12)` with theme-based shadow
- Replace `Color.fromRGBO(255, 255, 255, 0.7)` with `colorScheme.surface.withOpacity(0.7)`
- Replace `Colors.white` with `colorScheme.onPrimary` or `colorScheme.surface`
- Replace `Colors.red` with `colorScheme.error`
- Ensure all hardcoded `kSecondary` references use `colorScheme.secondary`

### 8. Dark Mode Verification
**File:** lib/src/screens/home_screen.dart

**Changes:** None needed in most places since they use Theme.of(context), but verify:
- `_InventoryTile` uses `Colors.white` for default bg → change to `colorScheme.surface`
- `_RecipeTile` uses whitish backgrounds → change to `colorScheme.surface`
- All hardcoded shadow colors use theme-based values

### 9. Spacing Standardization
**File:** lib/src/screens/home_screen.dart

**Changes:**
- Apply `UIConstants.kHorizontalPadding` (24) for horizontal padding
- Use `UIConstants.kVerticalGap` (12) for vertical spacing
- Use `UIConstants.kMediumGap` (16) for medium spacing
- Use `UIConstants.kCardPadding` (24) for card inner padding

### 10. Animations Polish
**File:** lib/src/screens/home_screen.dart (`_HomeScreenState`)

**Changes:**
- Hero header already has FadeTransition - keep as is
- Add subtle scale animation to AppButton on press (already in AppButton)
- Add staggered animation for section cards appearing (optional)

## Success Criteria
- Professional, modern appearance comparable to production apps
- Consistent use of GoogleFonts (Lora for headings, OpenSans for body)
- All colors from Theme.of(context).colorScheme
- Proper dark mode rendering without hardcoded light colors
- Smooth visual hierarchy with appropriate spacing
- Accessible touch targets (≥48dp)

## Files to Modify
1. `lib/src/screens/home_screen.dart` - Main redesign target
2. Potentially `lib/src/widgets/app_card.dart` if adjustments needed
3. Potentially `lib/src/theme/app_theme.dart` if color adjustments needed