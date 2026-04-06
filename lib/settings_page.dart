import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(title: Text('Theme')),
RadioListTile<ThemeMode>(
  title: Text('System Default'),
  value: ThemeMode.system,
  groupValue: themeProvider.themeMode,
  onChanged: (mode) {
    if (mode != null) themeProvider.setThemeMode(mode);
  },
),

            RadioListTile<ThemeMode>(
              title: Text('Light Mode'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
  onChanged: (mode) {
    if (mode != null) themeProvider.setThemeMode(mode);
  },
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dark Mode'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
  onChanged: (mode) {
    if (mode != null) themeProvider.setThemeMode(mode);
  },
            ),
            ListTile(
  title: Text('About'),
  leading: Icon(Icons.info_outline),
  onTap: () {
    showAboutDialog(
      context: context,
      applicationName: 'FastNote',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Your Name or Company',
    );
  },
),

          ],
        ),
      ),
    );
  }
}
