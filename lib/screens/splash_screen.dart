import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Cek status login user dan tentukan halaman berikutnya
  Future<Widget> _getNextScreen() async {
    final storageService = StorageService();
    final isLoggedIn = await storageService.isLoggedIn();
    
    return isLoggedIn ? const MainScreen() : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getNextScreen(),
      builder: (context, snapshot) {
        // Tampilkan loading indicator saat mengecek status login
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.darkBlue,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        
        // Tampilkan splash screen dengan animasi
        return AnimatedSplashScreen(
          splash: _buildSplashContent(),
          nextScreen: snapshot.data!,
          splashIconSize: 250,
          backgroundColor: AppColors.darkBlue,
          splashTransition: SplashTransition.fadeTransition,
          duration: 2000,
        );
      },
    );
  }

  // Konten yang ditampilkan di splash screen
  Widget _buildSplashContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo aplikasi dengan background lingkaran
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 60,
            color: AppColors.orange,
          ),
        ),
        const SizedBox(height: 24),
        // Judul aplikasi
        const Text(
          'Finance Tracker',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // Tagline aplikasi
        const Text(
          'Kelola Keuangan Anda',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}