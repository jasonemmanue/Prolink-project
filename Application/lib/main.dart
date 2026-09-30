import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'api/session.dart';
import 'l10n.dart';
import 'theme.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding.dart';
import 'screens/pro_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLocale()),
        ChangeNotifierProvider.value(value: Session.instance),
      ],
      child: const ProLinkApp(),
    ),
  );
}

class ProLinkApp extends StatelessWidget {
  const ProLinkApp({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppLocale>();
    return MaterialApp(
      title: 'ProLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: loc.locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      // Requis pour les sélecteurs date/heure et les libellés Material en FR.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Restaure la session mémorisée (jeton valide → accès direct à l'app).
  Future<void> _start() async {
    final results = await Future.wait([
      Session.instance.restore().catchError((_) => false),
      Future.delayed(const Duration(milliseconds: 1400), () => true),
    ]);
    if (!mounted) return;
    final restored = results.first;
    final session = Session.instance;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => !restored
            ? const OnboardingScreen()
            : session.isPro
            ? const ProShell()
            : const HomeShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ProLink',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'La marketplace sociale des pros africains',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
