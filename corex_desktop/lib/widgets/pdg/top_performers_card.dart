import 'package:flutter/material.dart';

class TopPerformersCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final String nameKey;
  final String valueKey;
  final String? subtitleKey;
  final IconData icon;
  final Color color;

  const TopPerformersCard({
    Key? key,
    required this.title,
    required this.data,
    required this.nameKey,
    required this.valueKey,
    this.subtitleKey,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F2E).withOpacity(0.8),
            const Color(0xFF2D3748).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (data.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${data.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Liste des performers
          if (data.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: data.take(10).map((item) => _buildPerformerItem(item)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerItem(Map<String, dynamic> item) {
    final name = item[nameKey]?.toString() ?? '';
    final value = item[valueKey];
    final subtitle = subtitleKey != null ? item[subtitleKey!] : null;

    // Calculer la position (index + 1)
    final position = data.indexOf(item) + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Position avec badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getPositionColors(position),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Informations du performer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.length > 25 ? '${name.substring(0, 25)}...' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatSubtitle(subtitle),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Valeur principale
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatValue(value),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null && subtitleKey == 'tauxReussite') ...[
                const SizedBox(height: 2),
                Text(
                  '${subtitle.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(width: 8),

          // Indicateur de performance
          _buildPerformanceIndicator(position),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(int position) {
    IconData iconData;
    Color iconColor;

    if (position <= 3) {
      iconData = Icons.trending_up;
      iconColor = const Color(0xFF00B894);
    } else if (position <= 7) {
      iconData = Icons.trending_flat;
      iconColor = const Color(0xFFFDAB3D);
    } else {
      iconData = Icons.trending_down;
      iconColor = const Color(0xFFE17055);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 16,
      ),
    );
  }

  List<Color> _getPositionColors(int position) {
    switch (position) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Or
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Argent
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
      default:
        return [color, color.withOpacity(0.7)];
    }
  }

  String _formatValue(dynamic value) {
    if (value is num) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return value.toStringAsFixed(0);
      }
    }
    return value.toString();
  }

  String _formatSubtitle(dynamic subtitle) {
    if (subtitleKey == 'tauxReussite') {
      return 'Taux de réussite';
    } else if (subtitleKey == 'volume') {
      return '$subtitle colis';
    } else if (subtitleKey == 'ca') {
      return 'CA: ${_formatValue(subtitle)} FCFA';
    }
    return subtitle.toString();
  }
}
