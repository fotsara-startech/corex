class StatutsColis {
  static const String collecte = 'collecte';
  static const String enregistre = 'enregistre';
  static const String deposeAgence = 'deposeAgence';
  static const String enTransit = 'enTransit';
  static const String arriveDestination = 'arriveDestination';
  static const String enCoursLivraison = 'enCoursLivraison';
  static const String livre = 'livre';
  static const String retire = 'retire';
  static const String retourne = 'retourne';

  static const List<String> allStatuts = [
    collecte,
    enregistre,
    deposeAgence,
    enTransit,
    arriveDestination,
    enCoursLivraison,
    livre,
    retire,
    retourne,
  ];

  static String getLabel(String statut) {
    switch (statut) {
      case collecte:
        return 'Collecté';
      case enregistre:
        return 'Enregistré';
      case deposeAgence:
        return 'Déposé en agence';
      case enTransit:
        return 'En transit';
      case arriveDestination:
        return 'Arrivé à destination';
      case enCoursLivraison:
        return 'En cours de livraison';
      case livre:
        return 'Livré';
      case retire:
        return 'Retiré';
      case retourne:
        return 'Retourné';
      default:
        return statut;
    }
  }
}
