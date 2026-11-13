import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'core/l10n/l10n.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/language_store.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageStore = LanguageStore();
  final results = await Future.wait<Object?>([
    SupabaseConfig.initialize(),
    languageStore.load(),
  ]);
  final language = results[1] as String? ?? AppLanguage.english;
  runApp(
    MaharatApp(
      appState: AppState(
        languageStore: languageStore,
        initialLanguage: language,
      ),
    ),
  );
}

class MaharatApp extends StatefulWidget {
  /// Tests inject a state backed by fake services.
  final AppState? appState;

  const MaharatApp({super.key, this.appState});

  @override
  State<MaharatApp> createState() => _MaharatAppState();
}

class _MaharatAppState extends State<MaharatApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppState _appState = widget.appState ?? AppState();

  @override
  void initState() {
    super.initState();
    // Covers logout and expired sessions, from any screen.
    _appState.onSessionEnded = () {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.language,
        (route) => false,
      );
    };
  }

  @override
  void dispose() {
    if (widget.appState == null) _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      // Changing the language swaps the locale (text, right-to-left layout)
      // and the font without leaving the current screen.
      child: Selector<AppState, String>(
        selector: (_, state) => state.currentUser.language,
        builder: (context, language, _) {
          final urdu = language == AppLanguage.urdu;
          AppLanguage.isUrdu = urdu;
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Maharat',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.forLanguage(urdu: urdu),
            locale: AppLanguage.localeFor(language),
            supportedLocales: const [Locale('en'), Locale('ur')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
