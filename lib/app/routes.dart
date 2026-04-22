import 'package:flutter/material.dart';

import '../features/auth/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/transaction/add_transaction_screen.dart';
import '../features/transaction/transaction_list_screen.dart';
import '../features/transaction/transaction_detail_screen.dart';
import '../features/savings/savings_screen.dart';
import '../features/savings/add_savings_screen.dart';
import '../features/savings/savings_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../models/transaction_model.dart';
import '../models/savings_model.dart';

/// Kelas untuk mendefinisikan semua nama rute aplikasi
class AppRoutes {
  // Rute autentikasi
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Rute utama aplikasi
  static const String home = '/home';

  // Rute transaksi
  static const String addTransaction = '/add-transaction';
  static const String transactionList = '/transaction-list';
  static const String transactionDetail = '/transaction-detail';

  // Rute tabungan
  static const String savings = '/savings';
  static const String addSavings = '/add-savings';
  static const String savingsDetail = '/savings-detail';

  // Rute profil
  static const String profile = '/profile';

  /// Generate rute berdasarkan nama dan argumen
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // === RUTE AUTENTIKASI ===
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case register:
        return _buildRoute(const RegisterScreen(), settings);

      // === RUTE UTAMA ===
      case home:
        return _buildRoute(const HomeScreen(), settings);

      // === RUTE TRANSAKSI ===
      case addTransaction:
        // Bisa menerima transaksi yang sudah ada untuk mode edit
        final transaction = settings.arguments as TransactionModel?;
        return _buildRoute(
          AddTransactionScreen(existingTransaction: transaction),
          settings,
        );

      case transactionList:
        return _buildRoute(const TransactionListScreen(), settings);

      case transactionDetail:
        final transaction = settings.arguments as TransactionModel;
        return _buildRoute(
          TransactionDetailScreen(transaction: transaction),
          settings,
        );

      // === RUTE TABUNGAN ===
      case savings:
        return _buildRoute(const SavingsScreen(), settings);

      case addSavings:
        final savings = settings.arguments as SavingsModel?;
        return _buildRoute(
          AddSavingsScreen(existingSavings: savings),
          settings,
        );

      case savingsDetail:
        final savingsModel = settings.arguments as SavingsModel;
        return _buildRoute(
          SavingsDetailScreen(savings: savingsModel),
          settings,
        );

      // === RUTE PROFIL ===
      case profile:
        return _buildRoute(const ProfileScreen(), settings);

      // Rute tidak ditemukan
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Halaman "${settings.name}" tidak ditemukan'),
            ),
          ),
          settings,
        );
    }
  }

  /// Helper untuk membuat rute dengan animasi transisi halus
  static PageRoute _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Animasi fade + slide dari bawah
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
