import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../services/sound_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.appState, required this.onThemeChanged});

  final AppState appState;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? kDarkBackground : kBackground;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;
    final dividerColor = isDark ? kDarkDivider : kDivider;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kPrimaryLight],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Settings',
            style: const TextStyle(
              color: Colors.white,
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
          _SectionHeader(title: 'Account', icon: Icons.person_rounded, textColor: textColor),
          const SizedBox(height: 12),
          _SettingsCard(
            cardColor: cardColor,
            textColor: textColor,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.email_rounded,
                  iconColor: kPrimary,
                  title: 'Signed in as',
                  value: widget.appState.currentUserEmail ?? 'Not signed in',
                  textColor: textColor,
                ),
                Divider(color: dividerColor),
                _InfoTile(
                  icon: Icons.bookmark_rounded,
                  iconColor: kSecondary,
                  title: 'Saved recipes',
                  value: '${widget.appState.savedRecipes.length}',
                  textColor: textColor,
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
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kAccent,
                      side: BorderSide(color: kAccent.withAlpha(100)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Appearance Section
          _SectionHeader(title: 'Appearance', icon: Icons.palette_rounded, textColor: textColor),
          const SizedBox(height: 12),
          _SettingsCard(
            cardColor: cardColor,
            textColor: textColor,
            child: Column(
              children: [
                _ToggleTile(
                  icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  iconColor: kPrimary,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  value: isDark,
                  textColor: textColor,
                  onChanged: (value) {
                    HapticFeedback.mediumImpact();
                    widget.onThemeChanged(value);
                    _showThemeSnackBar(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Feedback Section
          _SectionHeader(title: 'Feedback', icon: Icons.touch_app_rounded, textColor: textColor),
          const SizedBox(height: 12),
          _SettingsCard(
            cardColor: cardColor,
            textColor: textColor,
            child: _ToggleTile(
              icon: Icons.vibration,
              iconColor: kSecondary,
              title: 'Haptic Feedback',
              subtitle: 'Vibrate on button presses',
              value: SoundService.isEnabled,
              textColor: textColor,
              onChanged: (value) async {
                if (value) HapticFeedback.mediumImpact();
                SoundService.setEnabled(value);
                await PreferencesService.setHapticFeedback(value);
                setState(() {});
                _showHapticSnackBar(value);
              },
            ),
          ),
          const SizedBox(height: 24),
          // About Section
          _SectionHeader(title: 'About', icon: Icons.info_rounded, textColor: textColor),
          const SizedBox(height: 12),
          _SettingsCard(
            cardColor: cardColor,
            textColor: textColor,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.restaurant_rounded,
                  iconColor: kPrimary,
                  title: 'App Version',
                  value: '1.0.0',
                  textColor: textColor,
                ),
                Divider(color: dividerColor),
                _InfoTile(
                  icon: Icons.code_rounded,
                  iconColor: kSecondary,
                  title: 'Built with',
                  value: 'Flutter & Dart',
                  textColor: textColor,
                ),
                Divider(color: dividerColor),
                _InfoTile(
                  icon: Icons.favorite_rounded,
                  iconColor: kAccent,
                  title: 'Made for',
                  value: 'Reducing Food Waste',
                  textColor: textColor,
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
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kAccent.withAlpha(100)),
                boxShadow: [
                  BoxShadow(
                    color: textColor.withAlpha(6),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restore_rounded, color: kAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Reset All Data',
                    style: TextStyle(
                      color: kAccent,
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
          isDark ? '🌙 Dark mode enabled' : '☀️ Light mode enabled',
        ),
        backgroundColor: isDark ? Colors.indigo : kSecondary,
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
        backgroundColor: enabled ? kSecondary : kText.withAlpha(180),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showResetDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkSurface : kSurface;
    final textColor = isDark ? kDarkText : kText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset All Data?',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will clear all your scanned scraps and saved recipes.',
          style: TextStyle(color: textColor.withAlpha(160)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data reset (Demo: data persists)'),
                  backgroundColor: kPrimary,
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
  const _SectionHeader({required this.title, required this.icon, required this.textColor});

  final String title;
  final IconData icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kPrimary),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor.withAlpha(120),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, required this.cardColor, required this.textColor});

  final Widget child;
  final Color cardColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withAlpha(6),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor.withAlpha(20), iconColor.withAlpha(10)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: kPrimary.withAlpha(50),
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? kPrimary : Colors.white),
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
    required this.textColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [iconColor.withAlpha(20), iconColor.withAlpha(10)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withAlpha(140),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
