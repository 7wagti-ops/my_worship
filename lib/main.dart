import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'models.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => Material(
        color: Colors.red[50],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'خطأ: ${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );

  try {
    await SupabaseService.init();
  } catch (e) {
    debugPrint('SB init: $e');
  }
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notif init: $e');
  }

  // ═══ تحميل الإعدادات قبل بناء الواجهة ═══
  final settings = SettingsProvider();
  await settings.load();

  runApp(App(settings: settings));
}

class App extends StatelessWidget {
  final SettingsProvider settings;
  const App({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ProxyProvider<SyncProvider, SyncService>(
          update: (_, sync, __) => SyncService(sync),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, s, __) => MaterialApp(
          title: s.lang == 'ar' ? 'وقتي' : 'My Time',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: s.darkMode ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(s.lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const SplashGate(),
        ),
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  UserData? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final email = await Storage.loadSession();
      if (email == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final local = await Storage.loadUser(email);
      if (local != null) {
        if (mounted) {
          setState(() {
            _user = local;
            _loading = false;
          });
        }
        _refreshFromCloud(email);
        return;
      }

      try {
        final cloud = await SupabaseService.loadUser(email);
        if (cloud != null) {
          await Storage.saveUser(cloud);
          if (mounted) {
            setState(() {
              _user = cloud;
              _loading = false;
            });
          }
          return;
        }
      } catch (_) {}

      await Storage.clearSession();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('auto-login failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshFromCloud(String email) async {
    try {
      final cloud = await SupabaseService.loadUser(email);
      if (cloud != null && mounted) {
        await Storage.saveUser(cloud);
        setState(() => _user = cloud);
      }
    } catch (_) {}
  }

  Future<String?> _onSubmit(String email) async {
    try {
      final u = await SupabaseService.loadUser(email);
      if (u != null) {
        await _setUser(u, email);
        return null;
      }
    } catch (e) {
      final local = await Storage.loadUser(email);
      if (local != null) {
        await _setUser(local, email);
        return null;
      }
      return 'تعذّر الاتصال: $e';
    }

    final local = await Storage.loadUser(email);
    if (local != null) {
      await _setUser(local, email);
      return null;
    }

    try {
      final newUser =
          UserData(identifier: email, name: email.split('@').first);
      final (ok, err, saved) = await SupabaseService.saveUserWithResult(newUser);
      if (!ok) return 'فشل الإنشاء: $err';
      await _setUser(saved!, email);
      return null;
    } catch (e) {
      return 'فشل الإنشاء: $e';
    }
  }

  Future<void> _setUser(UserData u, String email) async {
    await Storage.saveUser(u);
    await Storage.saveSession(email);
    if (mounted) setState(() => _user = u);
  }

  Future<void> _logout() async {
    await Storage.clearSession();
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (_user == null) return LoginScreen(onSubmit: _onSubmit);

    return MainShell(user: _user!, onLogout: _logout);
  }
}
