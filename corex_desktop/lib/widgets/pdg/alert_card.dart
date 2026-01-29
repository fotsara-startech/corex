import 'package:flutter/material.dart';

class AlertCard extends StatelessWidget {
  final String type;
  final String titre;
  final String message;
  final String action;

  const AlertCard({
    Key? key,
    required this.type,
    required this.titre,
    required this.message,
    required this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alertConfig = _getAlertConfig(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertConfig.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertConfig.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône d'alerte
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: alertConfig.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              alertConfig.icon,
              color: alertConfig.color,
              size: 20,
            ),
          ),

          const SizedBox(width: 16),

          // Contenu de l'alerte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    color: alertConfig.color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Action recommandée: $action',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Bouton d'action
          TextButton(
            onPressed: () {
              _handleAlertAction(context, type);
            },
            style: TextButton.styleFrom(
              backgroundColor: alertConfig.color.withOpacity(0.2),
              foregroundColor: alertConfig.color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Voir',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  AlertConfig _getAlertConfig(String type) {
    switch (type) {
      case 'error':
        return AlertConfig(
          color: const Color(0xFFE17055),
          icon: Icons.error_outline,
        );
      case 'warning':
        return AlertConfig(
          color: const Color(0xFFFDAB3D),
          icon: Icons.warning_amber_outlined,
        );
      case 'info':
        return AlertConfig(
          color: const Color(0xFF74B9FF),
          icon: Icons.info_outline,
        );
      default:
        return AlertConfig(
          color: const Color(0xFF6C5CE7),
          icon: Icons.notifications_outlined,
        );
    }
  }

  void _handleAlertAction(BuildContext context, String type) {
    // Ici on peut implémenter la navigation vers les écrans appropriés
    switch (type) {
      case 'error':
        // Navigation vers l'écran de gestion des créances
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation vers la gestion des créances'),
            backgroundColor: Color(0xFFE17055),
          ),
        );
        break;
      case 'warning':
        // Navigation vers l'analyse des performances
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation vers l\'analyse des performances'),
            backgroundColor: Color(0xFFFDAB3D),
          ),
        );
        break;
      case 'info':
        // Navigation vers la gestion des utilisateurs
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation vers la gestion des utilisateurs'),
            backgroundColor: Color(0xFF74B9FF),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action en cours de développement'),
          ),
        );
    }
  }
}

class AlertConfig {
  final Color color;
  final IconData icon;

  AlertConfig({
    required this.color,
    required this.icon,
  });
}
