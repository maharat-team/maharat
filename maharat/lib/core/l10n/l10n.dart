import 'package:flutter/widgets.dart';

/// The app shows one language at a time: English or Urdu.
///
/// Widgets call `context.tr(english, urdu)`, which depends on the app's
/// [Locale], so every screen rebuilds when the language changes. Code that runs
/// outside a widget build (error messages, validators) calls the top-level
/// [tr], which reads [AppLanguage.isUrdu]; `MaharatApp` keeps that in step.
class AppLanguage {
  AppLanguage._();

  static const english = 'English';
  static const urdu = 'Urdu';

  static bool isUrdu = false;

  static Locale localeFor(String language) =>
      Locale(language == urdu ? 'ur' : 'en');
}

/// Text for the current language, for use outside a widget build.
String tr(String en, String ur) => AppLanguage.isUrdu ? ur : en;

extension L10nContext on BuildContext {
  bool get isUrdu => Localizations.maybeLocaleOf(this)?.languageCode == 'ur';

  /// Text for the language this screen is shown in.
  String tr(String en, String ur) => isUrdu ? ur : en;
}
