import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_en.dart';
export 'app_localizations.dart';

extension MilionStrings on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEn();
  String get language =>
      Localizations.maybeLocaleOf(this)?.languageCode ?? 'en';
}
