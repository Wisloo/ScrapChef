# Home Screen Visual Redesign Specification

## Overview
This document outlines the redesign of the home screen with improved visual hierarchy, modern typography, responsive design, and dark mode compatibility.

## Current State Analysis

### Layout Structure
- **Hero Header**: Top section with app title, tagline, items logged count, and settings icon
- **Tab Bar**: Two tabs: "Scan" and "Bin"
- **Tab Bar View**: 
  - Scan tab: Contains scan instructions, metrics, latest scan card, impact ledger
  - Bin tab: Inventory list with batch selection and recipe finding actions
- **Action Panel**: Fixed bottom button for opening camera

### Typography
- Uses Google Fonts Lora for headings
- System font for body text
- Inconsistent font sizes and weights across components

### Color Scheme
- Gradient background in hero header
- Primary color used for accents and active states
- Secondary color for secondary actions
- Surface colors for cards

### Responsive Considerations
- Uses CustomScrollView with SliverList for vertical scrolling
- Fixed padding values (24dp) throughout
- No explicit breakpoints for different screen sizes

### Animations
- Hero animation on header opacity
- No other explicit animations or transitions

## Proposed Redesign

### 1. Visual Hierarchy & Layout

#### New Structure
```
[App Bar]
  - Logo (left)
  - Settings (right)

[Hero Banner]
  - Large headline: "ScrapChef"
  - Subheadline: "Turn scraps into suppers"
  - Stats card (items logged, savings)
  - Gradient background with subtle animation

[Main Content Area]
  - Tab navigation (Scan | Bin)
  - Scan tab content:
    * Quick action card (Open Camera)
    * Latest scan preview
    * How it works steps
    * Impact metrics
  - Bin tab content:
    * Inventory list with selection
    * Batch actions bar
```

#### Key Changes
- Move settings to app bar for better accessibility
- Replace bottom action panel with prominent "Open Camera" button in hero banner
- Restructure scan tab to prioritize quick actions
- Add visual separation between sections with consistent spacing

### 2. Typography System

#### Font Selection
- Primary: Inter (sans-serif) for UI elements and body text
- Secondary: Playfair Display (serif) for headlines and emphasis

#### Type Scale
| Element | Font Size (sp) | Weight | Line Height |
|---------|----------------|--------|-------------|
| Headline (H1) | 32 | Bold | 1.2 |
| Subheadline (H2) | 20 | SemiBold | 1.3 |
| Section Title | 18 | Bold | 1.3 |
| Body Large | 16 | Regular | 1.5 |
| Body Medium | 14 | Regular | 1.5 |
| Body Small | 12 | Regular | 1.5 |
| Caption | 11 | Regular | 1.4 |

#### Implementation
Update `ui_constants.dart` with new typography constants and integrate with `app_theme.dart`.

### 3. Color Scheme

#### Palette
- **Primary**: #4A90E2 (Blue)
- **Secondary**: #50C878 (Green)
- **Background**: #F5F7FA (Light Gray)
- **Surface**: #FFFFFF (White)
- **Text Primary**: #1A1A1A (Near Black)
- **Text Secondary**: #666666 (Dark Gray)
- **Text Muted**: #999999 (Light Gray)

#### Dark Mode
- **Primary**: #4A90E2 (same)
- **Secondary**: #50C878 (same)
- **Background**: #121212 (Near Black)
- **Surface**: #1E1E1E (Dark Gray)
- **Text Primary**: #FFFFFF (White)
- **Text Secondary**: #B0B0B0 (Light Gray)
- **Text Muted**: #666666 (Medium Gray)

#### Usage
- Primary for main actions, active states, and key highlights
- Secondary for secondary actions and positive indicators
- Text colors based on importance and context
- Surface for card backgrounds
- Background for page background

### 4. Responsive Design

#### Breakpoints
- Mobile (< 600px): Single column, full width
- Tablet (600px - 1024px): Two columns for some sections
- Desktop (> 1024px): Fixed max width (1200px) with centered layout

#### Implementation
- Use `LayoutBuilder` to adapt column counts
- Adjust padding and margins based on screen width
- Ensure touch targets are at least 48x48dp
- Use `MediaQuery` for dynamic font scaling

### 5. Animations & Transitions

#### Hero Header
- Fade-in animation on load (already exists)
- Subtle gradient shift animation on scroll
- Scale animation on stats numbers when updated

#### Tab Navigation
- Smooth fade transition between tabs
- Slide-in animation for new tab content
- Active tab indicator with smooth width transition

#### Micro-interactions
- Button press with ripple effect and scale down
- Card hover effect (desktop) with elevation increase
- Inventory item selection with checkmark animation
- Settings icon rotation on tap

#### Implementation
- Use Flutter's implicit animations (AnimatedOpacity, ScaleTransition)
- Custom Tween animations for more complex effects
- Consider using `flutter_animate` package for advanced animations

### 6. Dark Mode Compatibility

#### Theme Structure
Update `app_theme.dart` to define both light and dark themes with the new color scheme.

#### Key Considerations
- Ensure sufficient contrast ratios (> 4.5:1) for text
- Test all gradients and background combinations
- Verify that icons and images have appropriate contrast
- Ensure animations don't cause accessibility issues

#### Implementation
- Use `ThemeData` with `copyWith` for dark mode
- Define `ColorScheme` for consistent color mapping
- Use `useMaterial3` for improved theming capabilities

## Implementation Plan

### Phase 1: Foundation
1. Update `ui_constants.dart` with new spacing and typography constants
2. Create new color palette in `app_theme.dart`
3. Implement responsive layout utilities

### Phase 2: Component Updates
4. Update `AppCard`, `AppButton`, `TagChip` widgets with new styles
5. Revise `home_screen.dart` layout structure
6. Add animations and transitions

### Phase 3: Polish & Testing
7. Test on multiple screen sizes and devices
8. Verify dark mode compatibility
9. Optimize performance

## Deliverables
- Updated `lib/src/constants/ui_constants.dart`
- Updated `lib/src/theme/app_theme.dart`
- Updated `lib/src/widgets/app_card.dart`
- Updated `lib/src/widgets/app_button.dart`
- Updated `lib/src/screens/home_screen.dart`
- Updated `lib/src/widgets/tag_chip.dart` (if needed)
- Updated `lib/src/widgets/stat_badge.dart` (if needed)
- Design specification document

## Success Metrics
- Improved user engagement metrics
- Positive feedback on visual appeal
- Consistent UI across all screens
- Smooth animations without performance lag
- Full dark mode support with good contrast

## Risks & Mitigations
- **Risk**: Breaking existing user habits
  - **Mitigation**: Gradual rollout with A/B testing
- **Risk**: Performance impact from animations
  - **Mitigation**: Profile and optimize animation frames
- **Risk**: Inconsistent implementation across widgets
  - **Mitigation**: Create shared theme and component library

## Next Steps
1. Review and approve this specification
2. Begin implementation in code
3. Conduct user testing sessions
4. Iterate based on feedback