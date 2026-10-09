import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'constants/colors.dart';
import 'widgets/buttons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Demo'),
        // WARNA 3: Accent di AppBar
        backgroundColor: AppColors.accent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WARNA 1: Primary di Judul
            const Text(
              'Universitas Esa Unggul',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 12),

            // WARNA 2: Secondary di Keterangan
            const Text(
              'Tekan tombol di bawah untuk melihat tautan.',
              style: TextStyle(
                color: AppColors.secondary,
              ),
            ),

            const SizedBox(height: 24),

            const AppButton(
              label: 'Buka GitHub',
              icon: Icons.code,
              url: 'https://github.com/Satria-IDN',
            ),

            const SizedBox(height: 16),

            AppButton(
              label: 'Tes Tombol',
              icon: Icons.touch_app,
              onPressed: () {
                debugPrint('Tombol berhasil ditekan!');
              },
            ),
          ],
        ),
      ),
    );
  }
}