import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Image(image: AssetImage('assets/splash/logo.png'), width: 100, height: 100),
            SizedBox(height: 100),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
