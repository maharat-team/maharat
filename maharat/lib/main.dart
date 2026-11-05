import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MaharatApp());
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
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Maharat - Local Service Provider',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
