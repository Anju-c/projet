import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is logged in
    await userProvider.loadUser();

    if (!mounted) return;

    if (userProvider.isLoggedIn) {
      // Navigate to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      // Navigate to landing page
      Navigator.of(context).pushReplacementNamed('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PROJET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'More Than Succeed',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
