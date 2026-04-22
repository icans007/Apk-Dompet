import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';

import '../../services/auth_service.dart';

/// Halaman splash screen dengan logo dan animasi DompetKu
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controller untuk animasi logo
  late AnimationController _logoController;
  late AnimationController _textController;

  // Animasi scale untuk logo
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Animasi fade untuk teks
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashSequence();
  }

  /// Setup semua animasi
  void _setupAnimations() {
    // Controller untuk logo (800ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Controller untuk teks (600ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Animasi scale logo: 0.5 → 1.0
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Animasi opacity logo: 0 → 1
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Animasi opacity teks: 0 → 1
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Animasi slide teks: dari bawah ke atas
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
  }

  /// Urutan animasi dan navigasi
  Future<void> _startSplashSequence() async {
    // Mulai animasi logo
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Mulai animasi teks setelah logo
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Tunggu total 2.5 detik, lalu navigasi
    await Future.delayed(const Duration(milliseconds: 1400));

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  /// Tentukan halaman tujuan berdasarkan status login
  void _navigateToNextScreen() {
    final authService = context.read<AuthService>();

    if (authService.isAuthenticated) {
      // Sudah login → langsung ke dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      // Belum login → ke halaman login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Latar gradasi biru-ungu
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF6366F1),
              Color(0xFF818CF8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animasi
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildLogo(),
                ),

                const SizedBox(height: 32),

                // Teks aplikasi animasi
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: _buildAppName(),
                  ),
                ),

                const SizedBox(height: 80),

                // Indikator loading
                FadeTransition(
                  opacity: _textOpacity,
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget logo DompetKu
  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '💰',
          style: TextStyle(fontSize: 52),
        ),
      ),
    );
  }

  /// Widget nama aplikasi
  Widget _buildAppName() {
    return Column(
      children: [
        Text(
          'DompetKu',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kelola keuangan dengan mudah',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }
}
