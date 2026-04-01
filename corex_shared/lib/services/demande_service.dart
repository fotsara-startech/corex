import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/demande_course_model.dart';
import '../models/demande_colis_model.dart';
import '../models/course_model.dart';
import '../models/colis_model.dart';
import '../models/client_model.dart';
import 'email_service.dart';

class DemandeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmailService _emailService = EmailService();

  // Collections Firestore
  static const String _demandesCoursesCollection = 'demandes_courses';
  static const String _demandesColisCollection = 'demandes_colis';
  static const String _coursesCollection = 'courses';
  static const String _colisCollection = 'colis';
  static const String _clientsCollection = 'clients';

  /// Crée une demande de course par un client
  Future<String> creerDemandeCourse(DemandeCoursModel demande) async {
    try {
      print('📝 [DEMANDE_SERVICE] Création demande course pour ${demande.clientNom}');

      final docRef = await _firestore.collection(_demandesCoursesCollection).add(demande.toFirestore());

      print('✅ [DEMANDE_SERVICE] Demande course créée avec ID: ${docRef.id}');

      // Envoyer notification email au client
      await _envoyerEmailConfirmationCourse(demande.copyWith(id: docRef.id));

      return docRef.id;
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur création demande course: $e');
      rethrow;
    }
  }

  /// Crée une demande de colis par un client
  Future<String> creerDemandeColis(DemandeColisModel demande) async {
    try {
      print('📝 [DEMANDE_SERVICE] Création demande colis pour ${demande.clientNom}');

      final docRef = await _firestore.collection(_demandesColisCollection).add(demande.toFirestore());

      print('✅ [DEMANDE_SERVICE] Demande colis créée avec ID: ${docRef.id}');

      // Envoyer notification email au client
      await _envoyerEmailConfirmationColis(demande.copyWith(id: docRef.id));

      return docRef.id;
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur création demande colis: $e');
      rethrow;
    }
  }

  /// Récupère toutes les demandes de courses en attente de validation
  Future<List<DemandeCoursModel>> getDemandesCoursesEnAttente() async {
    try {
      final querySnapshot = await _firestore.collection(_demandesCoursesCollection).where('statut', isEqualTo: 'enAttenteValidation').orderBy('dateCreation', descending: true).get();

      return querySnapshot.docs.map((doc) => DemandeCoursModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur récupération demandes courses: $e');
      return [];
    }
  }

  /// Récupère toutes les demandes de colis en attente de validation
  Future<List<DemandeColisModel>> getDemandesColisEnAttente() async {
    try {
      final querySnapshot = await _firestore.collection(_demandesColisCollection).where('statut', isEqualTo: 'enAttenteValidation').orderBy('dateCreation', descending: true).get();

      return querySnapshot.docs.map((doc) => DemandeColisModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur récupération demandes colis: $e');
      return [];
    }
  }

  /// Valide une demande de course et crée la course correspondante
  Future<void> validerDemandeCourse({
    required String demandeId,
    required double tarifValide,
    required String validateurId,
    required String validateurNom,
    required String agenceId,
    String? commentaire,
  }) async {
    try {
      print('✅ [DEMANDE_SERVICE] Validation demande course: $demandeId');

      // Récupérer la demande
      final demandeDoc = await _firestore.collection(_demandesCoursesCollection).doc(demandeId).get();

      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demande = DemandeCoursModel.fromFirestore(demandeDoc);

      // Créer la course correspondante
      final course = CourseModel(
        clientId: demande.clientId,
        clientNom: demande.clientNom,
        clientTelephone: demande.clientTelephone,
        instructions: demande.instructions,
        lieu: demande.lieu,
        tache: demande.tache,
        montantEstime: tarifValide,
        commissionPourcentage: 10.0,
        commissionMontant: tarifValide * 0.1,
        agenceId: agenceId,
        createdBy: validateurId,
      );

      // Sauvegarder la course
      final courseDoc = await _firestore.collection(_coursesCollection).add(course.toFirestore());

      // Mettre à jour la demande
      await _firestore.collection(_demandesCoursesCollection).doc(demandeId).update({
        'statut': 'validee',
        'validateurId': validateurId,
        'validateurNom': validateurNom,
        'dateValidation': Timestamp.now(),
        'tarifValide': tarifValide,
        'commentaireValidation': commentaire,
        'courseId': courseDoc.id,
      });

      // Envoyer email de validation au client
      await _envoyerEmailValidationCourse(demande, tarifValide, true, commentaire);

      print('✅ [DEMANDE_SERVICE] Demande course validée et course créée: ${courseDoc.id}');
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur validation demande course: $e');
      rethrow;
    }
  }

  /// Rejette une demande de course
  Future<void> rejeterDemandeCourse({
    required String demandeId,
    required String validateurId,
    required String validateurNom,
    required String motifRejet,
  }) async {
    try {
      print('❌ [DEMANDE_SERVICE] Rejet demande course: $demandeId');

      // Récupérer la demande pour l'email
      final demandeDoc = await _firestore.collection(_demandesCoursesCollection).doc(demandeId).get();

      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demande = DemandeCoursModel.fromFirestore(demandeDoc);

      // Mettre à jour la demande
      await _firestore.collection(_demandesCoursesCollection).doc(demandeId).update({
        'statut': 'rejetee',
        'validateurId': validateurId,
        'validateurNom': validateurNom,
        'dateValidation': Timestamp.now(),
        'commentaireRejet': motifRejet,
      });

      // Envoyer email de rejet au client
      await _envoyerEmailValidationCourse(demande, null, false, motifRejet);

      print('✅ [DEMANDE_SERVICE] Demande course rejetée');
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur rejet demande course: $e');
      rethrow;
    }
  }

  /// Valide une demande de colis et crée le colis correspondant
  Future<void> validerDemandeColis({
    required String demandeId,
    required double tarifValide,
    required String validateurId,
    required String validateurNom,
    required String agenceId,
    String? commentaire,
  }) async {
    try {
      print('✅ [DEMANDE_SERVICE] Validation demande colis: $demandeId');

      // Récupérer la demande
      final demandeDoc = await _firestore.collection(_demandesColisCollection).doc(demandeId).get();

      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demande = DemandeColisModel.fromFirestore(demandeDoc);

      // Créer ou récupérer les clients expéditeur et destinataire
      await _creerOuRecupererClient(
        nom: demande.expediteurNom,
        telephone: demande.expediteurTelephone,
        email: demande.clientEmail,
        adresse: demande.expediteurAdresse,
        ville: demande.expediteurVille,
        quartier: demande.expediteurQuartier,
        agenceId: agenceId,
      );

      await _creerOuRecupererClient(
        nom: demande.destinataireNom,
        telephone: demande.destinataireTelephone,
        email: null,
        adresse: demande.destinataireAdresse,
        ville: demande.destinataireVille,
        quartier: demande.destinataireQuartier,
        agenceId: agenceId,
      );

      // Créer le colis correspondant
      final numeroSuivi = 'COL${DateTime.now().millisecondsSinceEpoch}';
      final colis = ColisModel(
        id: '',
        numeroSuivi: numeroSuivi,
        expediteurNom: demande.expediteurNom,
        expediteurTelephone: demande.expediteurTelephone,
        expediteurEmail: demande.clientEmail,
        expediteurAdresse: demande.expediteurAdresse,
        destinataireNom: demande.destinataireNom,
        destinataireTelephone: demande.destinataireTelephone,
        destinataireAdresse: demande.destinataireAdresse,
        destinataireVille: demande.destinataireVille,
        destinataireQuartier: demande.destinataireQuartier,
        contenu: demande.description,
        poids: demande.poids ?? 0,
        dimensions: demande.dimensions,
        montantTarif: tarifValide,
        isPaye: false,
        modeLivraison: 'standard',
        statut: 'nouveau',
        agenceCorexId: agenceId,
        commercialId: validateurId,
        dateCollecte: DateTime.now(),
        historique: [],
        isRetour: false,
      );

      // Sauvegarder le colis
      final colisDoc = await _firestore.collection(_colisCollection).add(colis.toFirestore());

      // Mettre à jour la demande
      await _firestore.collection(_demandesColisCollection).doc(demandeId).update({
        'statut': 'validee',
        'validateurId': validateurId,
        'validateurNom': validateurNom,
        'dateValidation': Timestamp.now(),
        'tarifValide': tarifValide,
        'commentaireValidation': commentaire,
        'colisId': colisDoc.id,
      });

      // Envoyer email de validation au client
      await _envoyerEmailValidationColis(demande, tarifValide, true, commentaire);

      print('✅ [DEMANDE_SERVICE] Demande colis validée et colis créé: ${colisDoc.id}');
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur validation demande colis: $e');
      rethrow;
    }
  }

  /// Rejette une demande de colis
  Future<void> rejeterDemandeColis({
    required String demandeId,
    required String validateurId,
    required String validateurNom,
    required String motifRejet,
  }) async {
    try {
      print('❌ [DEMANDE_SERVICE] Rejet demande colis: $demandeId');

      // Récupérer la demande pour l'email
      final demandeDoc = await _firestore.collection(_demandesColisCollection).doc(demandeId).get();

      if (!demandeDoc.exists) {
        throw Exception('Demande introuvable');
      }

      final demande = DemandeColisModel.fromFirestore(demandeDoc);

      // Mettre à jour la demande
      await _firestore.collection(_demandesColisCollection).doc(demandeId).update({
        'statut': 'rejetee',
        'validateurId': validateurId,
        'validateurNom': validateurNom,
        'dateValidation': Timestamp.now(),
        'commentaireRejet': motifRejet,
      });

      // Envoyer email de rejet au client
      await _envoyerEmailValidationColis(demande, null, false, motifRejet);

      print('✅ [DEMANDE_SERVICE] Demande colis rejetée');
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur rejet demande colis: $e');
      rethrow;
    }
  }

  /// Crée ou récupère un client existant
  Future<String> _creerOuRecupererClient({
    required String nom,
    required String telephone,
    String? email,
    required String adresse,
    required String ville,
    String? quartier,
    required String agenceId,
  }) async {
    try {
      // Chercher un client existant avec le même téléphone
      final existingQuery = await _firestore.collection(_clientsCollection).where('telephone', isEqualTo: telephone).limit(1).get();

      if (existingQuery.docs.isNotEmpty) {
        return existingQuery.docs.first.id;
      }

      // Créer un nouveau client
      final client = ClientModel(
        id: '',
        nom: nom,
        telephone: telephone,
        email: email,
        adresse: adresse,
        ville: ville,
        quartier: quartier,
        type: 'les_deux',
        agenceId: agenceId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_clientsCollection).add(client.toFirestore());

      return docRef.id;
    } catch (e) {
      print('❌ [DEMANDE_SERVICE] Erreur création client: $e');
      rethrow;
    }
  }

  /// Envoie un email de confirmation de demande de course
  Future<void> _envoyerEmailConfirmationCourse(DemandeCoursModel demande) async {
    try {
      final sujet = 'COREX - Demande de course reçue';
      final contenu = '''
Bonjour ${demande.clientNom},

Nous avons bien reçu votre demande de course avec les détails suivants :

📍 Lieu : ${demande.lieu}
📋 Tâche : ${demande.tache}
💰 Budget maximum : ${demande.budgetMax?.toStringAsFixed(0) ?? 'Non spécifié'} FCFA
📝 Instructions : ${demande.instructions}

Votre demande est actuellement en cours d'analyse par notre équipe. Vous recevrez une confirmation avec le tarif définitif sous peu.

Numéro de demande : ${demande.id}
Date de demande : ${demande.dateCreation.day}/${demande.dateCreation.month}/${demande.dateCreation.year}

Merci de votre confiance,
L'équipe COREX
      ''';

      await _emailService.sendCustomEmail(
        to: demande.clientEmail,
        toName: demande.clientNom,
        subject: sujet,
        body: contenu,
      );
    } catch (e) {
      print('⚠️ [DEMANDE_SERVICE] Erreur envoi email confirmation course: $e');
    }
  }

  /// Envoie un email de confirmation de demande de colis
  Future<void> _envoyerEmailConfirmationColis(DemandeColisModel demande) async {
    try {
      final sujet = 'COREX - Demande d\'expédition reçue';
      final contenu = '''
Bonjour ${demande.clientNom},

Nous avons bien reçu votre demande d'expédition avec les détails suivants :

📦 Description : ${demande.description}
📏 Poids : ${demande.poids?.toStringAsFixed(1) ?? 'Non spécifié'} kg
📐 Dimensions : ${demande.dimensions ?? 'Non spécifiées'}

📤 Expéditeur : ${demande.expediteurNom} - ${demande.expediteurVille}
📥 Destinataire : ${demande.destinataireNom} - ${demande.destinataireVille}

Votre demande est actuellement en cours d'analyse par notre équipe. Vous recevrez une confirmation avec le tarif définitif sous peu.

Numéro de demande : ${demande.id}
Date de demande : ${demande.dateCreation.day}/${demande.dateCreation.month}/${demande.dateCreation.year}

Merci de votre confiance,
L'équipe COREX
      ''';

      await _emailService.sendCustomEmail(
        to: demande.clientEmail,
        toName: demande.clientNom,
        subject: sujet,
        body: contenu,
      );
    } catch (e) {
      print('⚠️ [DEMANDE_SERVICE] Erreur envoi email confirmation colis: $e');
    }
  }

  /// Envoie un email de validation/rejet de course
  Future<void> _envoyerEmailValidationCourse(
    DemandeCoursModel demande,
    double? tarif,
    bool validee,
    String? commentaire,
  ) async {
    try {
      final sujet = validee ? 'COREX - Votre demande de course est validée ✅' : 'COREX - Votre demande de course ne peut être traitée ❌';

      final contenu = validee
          ? '''
Bonjour ${demande.clientNom},

Excellente nouvelle ! Votre demande de course a été validée.

📍 Lieu : ${demande.lieu}
📋 Tâche : ${demande.tache}
💰 Tarif confirmé : ${tarif?.toStringAsFixed(0)} FCFA

${commentaire != null ? '📝 Commentaire : $commentaire' : ''}

Un coursier sera bientôt assigné à votre demande. Vous recevrez une notification dès qu'il sera en route.

Numéro de demande : ${demande.id}

Merci de votre confiance,
L'équipe COREX
          '''
          : '''
Bonjour ${demande.clientNom},

Nous regrettons de vous informer que votre demande de course ne peut être traitée pour le motif suivant :

❌ Motif : $commentaire

📍 Lieu demandé : ${demande.lieu}
📋 Tâche demandée : ${demande.tache}

N'hésitez pas à nous contacter pour plus d'informations ou pour soumettre une nouvelle demande.

Numéro de demande : ${demande.id}

Cordialement,
L'équipe COREX
          ''';

      await _emailService.sendCustomEmail(
        to: demande.clientEmail,
        toName: demande.clientNom,
        subject: sujet,
        body: contenu,
      );
    } catch (e) {
      print('⚠️ [DEMANDE_SERVICE] Erreur envoi email validation course: $e');
    }
  }

  /// Envoie un email de validation/rejet de colis
  Future<void> _envoyerEmailValidationColis(
    DemandeColisModel demande,
    double? tarif,
    bool validee,
    String? commentaire,
  ) async {
    try {
      final sujet = validee ? 'COREX - Votre demande d\'expédition est validée ✅' : 'COREX - Votre demande d\'expédition ne peut être traitée ❌';

      final contenu = validee
          ? '''
Bonjour ${demande.clientNom},

Excellente nouvelle ! Votre demande d'expédition a été validée.

📦 Description : ${demande.description}
📤 De : ${demande.expediteurVille}
📥 Vers : ${demande.destinataireVille}
💰 Tarif confirmé : ${tarif?.toStringAsFixed(0)} FCFA

${commentaire != null ? '📝 Commentaire : $commentaire' : ''}

Votre colis est maintenant enregistré dans notre système. Un agent vous contactera bientôt pour organiser la collecte.

Numéro de demande : ${demande.id}

Merci de votre confiance,
L'équipe COREX
          '''
          : '''
Bonjour ${demande.clientNom},

Nous regrettons de vous informer que votre demande d'expédition ne peut être traitée pour le motif suivant :

❌ Motif : $commentaire

📦 Description : ${demande.description}
📤 De : ${demande.expediteurVille}
📥 Vers : ${demande.destinataireVille}

N'hésitez pas à nous contacter pour plus d'informations ou pour soumettre une nouvelle demande.

Numéro de demande : ${demande.id}

Cordialement,
L'équipe COREX
          ''';

      await _emailService.sendCustomEmail(
        to: demande.clientEmail,
        toName: demande.clientNom,
        subject: sujet,
        body: contenu,
      );
    } catch (e) {
      print('⚠️ [DEMANDE_SERVICE] Erreur envoi email validation colis: $e');
    }
  }
}
