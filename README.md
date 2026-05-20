# ScrapChef

A modern food waste reduction app built with Flutter.

## Features
- Scan food scraps using camera to identify them
- Get recipe suggestions based on available scraps
- Track savings and environmental impact
- Modern, earthy-themed UI with vibrant colors

## Recent Improvements
- **Redesigned Home Screen Buttons**: Increased touch target size to 48dp minimum, updated padding to 24dp horizontal and 20dp vertical, added proper border radius (16dp) and elevation
- **Updated UI Constants**: Created `ui_constants.dart` with standardized spacing, sizing, and typography values
- **Enhanced AppButton Widget**: Added animation, ripple effect, and proper gradient handling
- **Consistent Spacing**: Applied standardized padding and gaps throughout the UI
- **Modern Color Scheme**: Leveraged Theme.of(context).colorScheme for better dark/light mode support

## Usage
Run `flutter run` on a connected device or emulator.

## Testing
The app has been tested on both light and dark themes across multiple screen sizes. Further visual QA is recommended before production release.
