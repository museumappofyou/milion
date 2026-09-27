import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'theme/milion_theme.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'DM Sans',
    ], await rootBundle.loadString('assets/fonts/OFL-DMSans.txt'));
    yield LicenseEntryWithLineBreaks([
      'Cormorant Garamond',
    ], await rootBundle.loadString('assets/fonts/OFL-CormorantGaramond.txt'));
  });
  runApp(const MilionApp());
}

class MilionApp extends StatelessWidget {
  const MilionApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Milion · Istanbul from mile zero',
    debugShowCheckedModeBanner: false,
    theme: MilionTheme.light,
    home: const HomeScreen(),
  );
}
