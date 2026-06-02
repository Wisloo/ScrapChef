import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../constants/ui_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.appState,
  });

  final AppState appState;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final bgColor = UIConstants.kBackground;
    final cardColor = UIConstants.kSurface;
    final textColor = UIConstants.kText;
    final dividerColor = UIConstants.kDivider;

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
              colors: [UIConstants.kPrimary, UIConstants.kPrimaryLight],
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
                  iconColor: UIConstants.kPrimary,
                  title: 'Signed in as',
                  value: widget.appState.currentUserEmail ?? 'Not signed in',
                  textColor: textColor,
                ),
                Divider(color: dividerColor),
                _InfoTile(
                  icon: Icons.bookmark_rounded,
                  iconColor: UIConstants.kSecondary,
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
                            await widget.appState.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UIConstants.kPrimary,
                      side: BorderSide(color: UIConstants.kPrimary.withAlpha(100)),
                    ),
                  ),
                ),
              ],
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
                  iconColor: UIConstants.kPrimary,
                  title: 'App Version',
                  value: '1.0.0',
                  textColor: textColor,
                ),
                Divider(color: dividerColor),
                _InfoTile(
                  icon: Icons.code_rounded,
                  iconColor: UIConstants.kSecondary,
                  title: 'Built with',
                  value: 'Flutter & Dart',
                  textColor: textColor,
                ),
                Divider(color: dividerColor),
                _InfoTile(
                  icon: Icons.favorite_rounded,
                  iconColor: UIConstants.kAccent,
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
              _showResetDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UIConstants.kAccent.withAlpha(100)),
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
                  Icon(Icons.restore_rounded, color: UIConstants.kAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Reset All Data',
                    style: TextStyle(
                      color: UIConstants.kAccent,
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

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text('This will clear all saved recipes and scraps.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await widget.appState.signOut();
              await widget.appState.clearLocalData();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _SectionHeader({required String title, required IconData icon, required Color textColor}) {
    return Row(
      children: [
        Icon(icon, color: textColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _SettingsCard({required Color cardColor, required Color textColor, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: textColor.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _InfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor.withAlpha(160),
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withAlpha(160),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: UIConstants.kPrimary,
          ),
        ],
      ),
    );
  }
}
