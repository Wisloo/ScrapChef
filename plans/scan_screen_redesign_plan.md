# Scan Screen UI Revamp Plan

## Objective
Transform the scan screen into a modern, professional, and user-friendly interface that matches the home screen's aesthetic. Focus on consistent theming, subtle animations, and improved visual hierarchy.

## Current Issues
1. **Hardcoded colors** - Uses kPrimary, kSecondary, kBackground constants instead of Theme.of(context).colorScheme
2. **Inconsistent gradients** - Multiple custom gradients that don't match the home screen's style
3. **Outdated button styles** - Uses GestureDetector with custom containers instead of modern FilledButton
4. **Missing animations** - No subtle entrance or interaction animations
5. **Typography inconsistencies** - Mixed font sizes and weights, not using GoogleFonts
6. **Poor spacing** - Elements are cramped, especially in _CameraOptions

## Design Principles
- **Consistent color scheme** - Use Theme.of(context).colorScheme for all colors
- **Modern components** - Replace GestureDetector with FilledButton/AnimatedButton
- **Subtle animations** - Add FadeTransition for entrance, scale feedback for buttons
- **Improved typography** - Use GoogleFonts (Lora for headings, OpenSans for body)
- **Better spacing** - Increase padding and margins for breathing room
- **Unified gradients** - Use the same gradient style as home screen

## Implementation Steps

### 1. Update _CameraOptions Widget
**Current:**
- Container with gradient background
- Camera icon in a circular container with gradient and shadow
- Two buttons using GestureDetector with custom gradients

**Proposed:**
- Wrap in a Card with elevation and rounded corners
- Use AnimatedButton for primary actions
- Apply consistent gradient from home screen (primary to primaryLight)
- Add subtle entrance animation
- Improve typography with GoogleFonts

**Code Changes:**
```dart
// Replace GestureDetector with AnimatedButton
child: Column(
  children: [
    // Camera icon with animation
    FadeTransition(
      opacity: _iconOpacity,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary.withAlpha(20), kPrimaryLight.withAlpha(10)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: kPrimary.withAlpha(30), width: 3),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withAlpha(40),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt_rounded, size: 60, color: kPrimary),
      ),
    ),
    // Buttons using AnimatedButton
    const SizedBox(height: 24),
    AnimatedButton(
      onPressed: onCamera,
      color: Theme.of(context).colorScheme.primary,
      borderRadius: 16,
      height: 56,
      shadow: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_alt_rounded, size: 24, color: Colors.white),
          SizedBox(width: 12),
          Text(
            'Take Photo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    ),
    SizedBox(height: 16),
    AnimatedButton(
      onPressed: onGallery,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: 16,
      height: 56,
      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_rounded, size: 22, color: Theme.of(context).colorScheme.onSurface.withAlpha(180)),
          SizedBox(width: 10),
          Text(
            'Choose from Gallery',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  ],
)
```

### 2. Update _ImagePreview Widget
**Current:**
- Custom controls with gradients and borders
- Corner brackets and guide overlay
- Bottom controls with Retake and Use Photo buttons

**Proposed:**
- Use FilledButton for controls
- Apply consistent theme colors
- Add subtle animations for button presses
- Improve typography hierarchy
- Better spacing and layout

**Code Changes:**
```dart
// Replace GestureDetector with FilledButton
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor.withAlpha(240),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: kPrimary),
          SizedBox(width: 8),
          Text(
            'Confirm the scrap type',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
    SizedBox(height: 20),
    Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onRetake,
            style: FilledButton.styleFrom(
              backgroundColor: cardColor.withAlpha(230),
              foregroundColor: textColor.withAlpha(200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 20),
                SizedBox(width: 8),
                Text('Retake', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 20),
                SizedBox(width: 8),
                Text('Use Photo', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    ),
  ],
)
```

### 3. Update _ManualLabelSheet Widget
**Current:**
- Uses kAccent and kSecondary in gradients
- Card with custom border and shadow
- Grid of labels with selection states

**Proposed:**
- Use Theme.of(context).colorScheme for all colors
- Replace custom gradients with theme-based ones
- Use FilledButton style for labels
- Add selection animation
- Improve typography with GoogleFonts

**Code Changes:**
```dart
// Replace custom gradients with theme colors
GridView.builder(
  shrinkWrap: true,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 2.5,
  ),
  itemCount: widget.labels.length,
  itemBuilder: (context, index) {
    final label = widget.labels[index];
    final isSelected = selectedLabel == label;

    return FadeTransition(
      opacity: _labelOpacity,
      child: GestureDetector(
        onTap: () {
          setState(() => selectedLabel = label);
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurface.withAlpha(30),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  },
)
```

### 4. Add Animations
- **Entrance animation** - Fade in the entire _CameraOptions widget
- **Button press animation** - Scale down effect on tap
- **Icon animation** - Fade in the camera icon
- **Label selection** - Fade in/out when selecting

**Implementation:**
```dart
class _CameraOptions extends StatelessWidget {
  // Add animation controllers
  final AnimationController _entranceController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: const ScanScreen(),
  );
  
  final Animation<double> _entranceAnimation;
  
  @override
  void initState() {
    super.initState();
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entranceAnimation,
      child: Container(...),
    );
  }
}
```

### 5. Typography Improvements
- **Headings** - Use GoogleFonts.Lora with fontWeight: FontWeight.w800
- **Body text** - Use GoogleFonts.OpenSans with appropriate weights
- **Consistent sizing** - Follow home screen's typography hierarchy

**Example:**
```dart
Text(
  'Capture Scrap',
  style: GoogleFonts.lora(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textColor,
  ),
),
```

### 6. Dark Mode Support
- Use kDarkBackground, kDarkSurface, kDarkText for dark theme
- Ensure gradients have appropriate opacity
- Test all colors in both light and dark modes

## Testing Plan
1. **Visual inspection** - Compare with home screen for consistency
2. **Device testing** - Run on OPPO CPH2057 to verify performance
3. **Theme testing** - Switch between light and dark modes
4. **Animation testing** - Verify all animations are smooth and not jarring
5. **Accessibility** - Check contrast ratios and touch target sizes

## Expected Outcome
- Professional, modern scan screen that matches home screen quality
- Consistent theming across the entire app
- Smooth animations and transitions
- Improved user experience with better visual hierarchy
- Full dark/light mode support

## Dependencies
- Requires `animated_button.dart` widget (already available)
- GoogleFonts package (already included)
- No new dependencies needed

## Risks
- **Animation complexity** - May require additional state management
- **Color consistency** - Need to carefully map hardcoded colors to theme
- **Performance** - Animations should be lightweight to avoid jank

## Mitigation
- Start with simple FadeTransition before adding complex animations
- Use Theme.of(context).colorScheme.primary consistently
- Test on actual device to ensure smooth performance