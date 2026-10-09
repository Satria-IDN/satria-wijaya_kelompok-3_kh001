import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? url;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.url,
    this.color,
  });

  Future<void> _handlePressed() async {

    if (onPressed == null) {
      final Uri uri = Uri.parse(url ?? "");
      final bool success = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!success) {
        debugPrint("Gagal mmbuka link");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(

        onPressed: _handlePressed,
        style: ElevatedButton.styleFrom(

          backgroundColor: color ?? AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}