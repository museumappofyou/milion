import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/settings.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../theme/milion_theme.dart';
import 'registry_screen.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, settings = SettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.about)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GestureDetector(
            onLongPress: kDebugMode
                ? () => Navigator.of(context).pushNamed('/design')
                : null,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: MilionWordmark(),
            ),
          ),
          const SizedBox(height: 24),
          Text(s.aboutStory),
          const SizedBox(height: 16),
          Text(s.aboutRecognition),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          if (settings != null) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: settings.locale?.languageCode ?? 'system',
              decoration: InputDecoration(labelText: s.language),
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(s.systemLanguage),
                ),
                DropdownMenuItem(value: 'en', child: Text(s.english)),
                DropdownMenuItem(value: 'tr', child: Text(s.turkish)),
              ],
              onChanged: (v) => settings.setLanguage(v == 'system' ? null : v),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<ThemeMode>(
              isExpanded: true,
              initialValue: settings.themeMode,
              decoration: InputDecoration(labelText: s.appearance),
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text(s.marble)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(s.lamp)),
              ],
              onChanged: (v) {
                if (v != null) settings.setScheme(v);
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],
          Text(
            s.recognitionLimits,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(s.recognitionLimitsBody),
          const SizedBox(height: 24),
          Text(s.credits, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(s.creditsBody),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () =>
                showLicensePage(context: context, applicationName: s.brandName),
            child: Text(s.licenses),
          ),
          Center(
            child: GestureDetector(
              key: const Key('about-version'),
              onLongPress: kDebugMode
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegistryScreen(),
                      ),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(s.version),
              ),
            ),
          ),
          Text(
            s.previewFooter,
            style: TextStyle(
              color: MeasureColors.of(context).secondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
