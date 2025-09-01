import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/download (2).png'),
            ElevatedButton(
              onPressed: () => context.go('/compress'),
              child: const Text('Compress Video/Audio'),
            ),
          ],
        ),
      ),
    );
  }
}
