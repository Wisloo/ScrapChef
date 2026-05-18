import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';

// Warm earthy colors (Light)
const Color kCream = Color(0xFFF6F1E8);
const Color kTerracotta = Color(0xFFB86137);
const Color kSage = Color(0xFF58765C);
const Color kDeepBrown = Color(0xFF2D1F16);
const Color kCardBg = Colors.white;

// Dark theme colors
const Color kDarkBg = Color(0xFF1A1A1A);
const Color kDarkCard = Color(0xFF2D2D2D);
const Color kDarkText = Color(0xFFF5F5F5);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool hapticFeedback = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        backgroundColor: kCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kDeepBrown),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kDeepBrown.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Settings',
            style: TextStyle(
              color: kDeepBrown,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'Account', icon: Icons.person),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.email,
                  iconColor: kTerracotta,
                  title: 'Signed in as',
                  value: widget.appState.currentUserEmail ?? 'Not signed in',
                ),
                Divider(color: kDeepBrown.withAlpha(20)),
                _InfoTile(
                  icon: Icons.bookmark,
                  iconColor: kSage,
                  title: 'Saved recipes',
                  value: '${widget.appState.savedRecipes.length}',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.appState.isSignedIn
                        ? () async {
                            HapticFeedback.mediumImpact();
                            await widget.appState.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Appearance Section
          _SectionHeader(title: 'Appearance', icon: Icons.palette),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _ToggleTile(
                  icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  iconColor: isDarkMode ? Colors.indigo : kTerracotta,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  value: isDarkMode,
                  onChanged: (value) {
                    HapticFeedback.mediumImpact();
                    setState(() => isDarkMode = value);
                    _showThemeSnackBar(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Feedback Section
          _SectionHeader(title: 'Feedback', icon: Icons.touch_app),
          const SizedBox(height: 12),
          _SettingsCard(
            child: _ToggleTile(
              icon: Icons.vibration,
              iconColor: kTerracotta,
              title: 'Haptic Feedback',
              subtitle: 'Vibrate on button presses (Active)',
              value: hapticFeedback,
              onChanged: (value) {
                if (value) HapticFeedback.mediumImpact();
                setState(() => hapticFeedback = value);
                _showHapticSnackBar(value);
              },
            ),
          ),
          const SizedBox(height: 24),
          // About Section
          _SectionHeader(title: 'About', icon: Icons.info),
          const SizedBox(height: 12),
          _SettingsCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.restaurant,
                  iconColor: kTerracotta,
                  title: 'App Version',
                  value: '1.0.0 (Prototype)',
                ),
                Divider(color: kDeepBrown.withAlpha(20)),
                _InfoTile(
                  icon: Icons.code,
                  iconColor: kSage,
                  title: 'Built with',
                  value: 'Flutter & Dart',
                ),
                Divider(color: kDeepBrown.withAlpha(20)),
                _InfoTile(
                  icon: Icons.favorite,
                  iconColor: Colors.red,
                  title: 'Made for',
                  value: 'Reducing Food Waste',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Reset Button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showResetDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withAlpha(100)),
                boxShadow: [
                  BoxShadow(
                    color: kDeepBrown.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restore, color: Colors.red.withAlpha(200)),
                  const SizedBox(width: 10),
                  Text(
                    'Reset All Data',
                    style: TextStyle(
                      color: Colors.red.withAlpha(200),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showThemeSnackBar(bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isDark ? '🌙 Dark mode coming in v2.0!' : '☀️ Light mode active',
        ),
        backgroundColor: isDark ? Colors.indigo : kSage,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHapticSnackBar(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? '🔊 Haptic feedback enabled' : '🔇 Haptic feedback disabled',
        ),
        backgroundColor: enabled ? kSage : kDeepBrown.withAlpha(180),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reset All Data?',
          style: TextStyle(
            color: kDeepBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will clear all your scanned scraps and saved recipes.',
          style: TextStyle(color: kDeepBrown.withAlpha(160)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: kDeepBrown)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data reset (Demo: data persists)'),
                  backgroundColor: kTerracotta,
                ),
              );
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kDeepBrown.withAlpha(100)),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kDeepBrown.withAlpha(100),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kDeepBrown.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kDeepBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: kDeepBrown.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: kSage.withAlpha(50),
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? kSage : Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kDeepBrown,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: kDeepBrown.withAlpha(120),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
