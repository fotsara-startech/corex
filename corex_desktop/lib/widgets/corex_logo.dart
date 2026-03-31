import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher le logo COREX
class CorexLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  final Color? textColor;

  const CorexLogo({
    super.key,
    this.width,
    this.height,
    this.showText = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = Image.asset(
      'assets/img/LOGO COREX.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback si l'image ne charge pas
        return Container(
          width: width ?? 40,
          height: height ?? 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular((width ?? 40) / 2),
          ),
          child: Center(
            child: Text(
              'C',
              style: TextStyle(
                color: Colors.white,
                fontSize: (width ?? 40) * 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );

    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoWidget,
          const SizedBox(width: 12),
          Text(
            'COREX',
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return logoWidget;
  }
}
