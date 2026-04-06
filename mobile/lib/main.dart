import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/order_success_screen.dart';

void main() {
  runApp(const BlinkitApp());
}

class BlinkitApp extends StatelessWidget {
  const BlinkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadFromPrefs()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Blinkit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0C831F),
            secondary: Color(0xFFEFF9EF),
            surface: Color(0xFFF7F7F7),
            onPrimary: Colors.white,
            onSurface: Color(0xFF121212),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F7F7),
          textTheme: GoogleFonts.manropeTextTheme(),
          useMaterial3: true,
        ),
        initialRoute: '/home',
        routes: {
          '/': (ctx) => const HomeScreen(),
          '/login': (ctx) => const LoginScreen(),
          '/home': (ctx) => const HomeScreen(),
          '/cart': (ctx) => const CartScreen(),
          '/order-success': (ctx) => const OrderSuccessScreen(),
        },
      ),
    );
  }
}
