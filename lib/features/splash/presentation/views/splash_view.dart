import 'package:courtly_owner/features/auth/presentation/views/auth_view.dart';
import 'package:courtly_owner/features/home/presentation/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:courtly_owner/core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check if user is already authenticated
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, go directly to home
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeView()));
    } else {
      // User is not logged in, go to auth screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthView()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: const Text(
            'Courtly Owner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
