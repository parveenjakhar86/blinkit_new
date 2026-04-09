import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rider_auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_shell.dart';

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0B7A34);
    const surface = Color(0xFFF4F6F1);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blinkit Rider',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          surface: surface,
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: ChangeNotifierProvider(
        create: (_) => RiderAuthProvider()..loadFromPrefs(),
        child: const _AppBootstrap(),
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeShell(),
      },
    );
  }
}

class _AppBootstrap extends StatelessWidget {
  const _AppBootstrap();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();

    if (!auth.isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0E8A39)),
        ),
      );
    }

    if (auth.isLoggedIn) {
      return const HomeShell();
    }

    return const LoginScreen();
  }
}