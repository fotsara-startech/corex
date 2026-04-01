/// Types de livraison disponibles dans le système COREX
class TypesLivraison {
  /// Livraison finale au destinataire
  /// Utilisé quand le colis est livré directement au client final
  /// Exemple: Expéditeur et destinataire dans la même ville
  static const String livraisonFinale = 'livraison_finale';

  /// Expédition vers une agence de transport
  /// Utilisé quand le colis doit être transféré vers une autre ville
  /// Le coursier transporte le colis du bureau vers l'agence de transport
  static const String expedition = 'expedition';

  /// Récupération depuis une agence de transport
  /// Utilisé quand le colis arrive d'une autre ville
  /// Le coursier récupère le colis à l'agence de transport pour le ramener au bureau
  static const String recuperation = 'recuperation';

  /// Liste de tous les types disponibles
  static const List<String> all = [
    livraisonFinale,
    expedition,
    recuperation,
  ];

  /// Obtenir le libellé d'un type de livraison
  static String getLibelle(String type) {
    switch (type) {
      case livraisonFinale:
        return 'Livraison finale au destinataire';
      case expedition:
        return 'Expédition vers agence de transport';
      case recuperation:
        return 'Récupération depuis agence de transport';
      default:
        return 'Type inconnu';
    }
  }

  /// Obtenir la description d'un type de livraison
  static String getDescription(String type) {
    switch (type) {
      case livraisonFinale:
        return 'Le coursier livre directement le colis au destinataire final';
      case expedition:
        return 'Le coursier transporte le colis du bureau vers l\'agence de transport';
      case recuperation:
        return 'Le coursier récupère le colis à l\'agence de transport pour le ramener au bureau';
      default:
        return '';
    }
  }

  /// Obtenir l'icône associée à un type de livraison
  static String getIcon(String type) {
    switch (type) {
      case livraisonFinale:
        return '📦'; // Livraison directe
      case expedition:
        return '🚚'; // Transport vers agence
      case recuperation:
        return '📥'; // Récupération
      default:
        return '❓';
    }
  }
}
