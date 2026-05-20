# ScrapChef Redesign Plan

## Current Issues
- App looks outdated and not modern
- Earthy colors not properly implemented
- Inconsistent spacing and typography
- Legacy color constants still present
- No visual cohesion between light/dark modes

## Todo List

### ✅ Phase 1: Foundation
- [ ] **Update Theme Colors** - Replace all legacy color constants with new palette from app_theme.dart, ensure all widgets use Theme.of(context).colorScheme
- [ ] **Apply New Typography** - Set GoogleFonts.lora for headlines, openSans for body, verify line height 1.6
- [ ] **Modernize AppBar** - Make transparent with no elevation, use primary color for icons, add subtle bottom border

### ✅ Phase 2: Layout & Components
- [x] **Revamp HomeScreen Layout** - Wrap hero header in AppCard, replace raw containers with AppCard, use AppButton for actions, update TabBar styling, add consistent padding
- [ ] **Refresh ScanScreen UI** - Update top bar background, use AppButton for actions, update overlay guide colors, ensure theme-based text styles
- [ ] **Update Reusable Widgets** - Add proper elevation to AppCard, borderRadius to AppButton, use colorScheme for StatBadge/TagChip

### ✅ Phase 3: Polish & Consistency
- [ ] **Standardize Spacing & Padding** - Define constants kHorizontalPadding=24.0, kVerticalGap=12.0, replace all hard-coded values
- [ ] **Dark-Mode Consistency Check** - Verify every color reference comes from Theme.of(context).colorScheme
- [ ] **Add Subtle Animations** - Fade-in cards on scroll, scale animation on AppButton press

### ✅ Phase 4: Quality Assurance
- [ ] **Accessibility Review** - Check contrast ratios, add semantic labels, verify screen-reader navigation
- [ ] **Testing & QA** - Write widget tests for new components

## Key Changes Needed

### 1. Color Palette Update
- Replace `kRecipeWarmBrown`, `kCookingTerracotta`, `kSketchCharcoal`, `kCaptionGray` with `Theme.of(context).colorScheme` references
- Remove legacy constants like `kPrimaryGreen`, `kDarkGreen`, `kAccentOrange`, `kLightBeige`, `kMintGreen`

### 2. Typography Implementation
- Verify all text widgets use `Theme.of(context).textTheme` instead of hardcoded styles
- Ensure Lora font for headlines, OpenSans for body text
- Confirm line height is 1.6 for body text

### 3. Layout Improvements
- Update TabBar styling to use theme colors
- Wrap hero header in AppCard with proper elevation
- Replace raw Container widgets with AppCard
- Use AppButton for all primary actions
- Apply consistent 24dp horizontal padding and 12dp vertical gaps

### 4. Component Enhancements
- AppCard: Add default elevation (2dp light / 4dp dark), subtle shadow
- AppButton: Add 12dp borderRadius, default gradient, ripple effect
- StatBadge & TagChip: Use colorScheme for backgrounds and text

### 5. Spacing Standardization
- Define `kHorizontalPadding = 24.0` and `kVerticalGap = 12.0` in ui_constants.dart
- Replace all hardcoded padding values with these constants
- Ensure touch targets are ≥ 48dp

### 6. Dark Mode Consistency
- Verify every color reference uses `Theme.of(context).colorScheme`
- Remove any hardcoded dark colors
- Test both light and dark modes thoroughly

### 7. Animations & Polish
- Add fade-in animations for cards on scroll
- Implement scale animations for button presses
- Ensure smooth transitions between states

### 8. Accessibility
- Check contrast ratios meet WCAG standards (≥ 4.5:1)
- Add semantic labels to interactive elements
- Verify screen reader navigation works properly

### 9. Testing
- Write widget tests for AppCard, AppButton, StatBadge, TagChip
- Test theme switching functionality
- Verify responsive behavior across different screen sizes

## Implementation Priority
1. **High Priority**: Color palette, typography, layout improvements
2. **Medium Priority**: Component enhancements, spacing standardization
3. **Low Priority**: Animations, accessibility, testing

## Success Metrics
- Visual consistency across all screens
- Proper dark/light mode support
- Improved user experience with modern design
- Accessible and responsive layout
- Maintainable codebase with reusable components