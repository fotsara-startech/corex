import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/transaction_model.dart';
import 'firebase_service.dart';

class CourseService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Crée une nouvelle course
  Future<void> createCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').add(course.toFirestore());
      print('✅ [COURSE_SERVICE] Course créée: ${course.id}');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur création course: $e');
      rethrow;
    }
  }

  /// Récupère une course par ID
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur récupération course: $e');
      return null;
    }
  }

  /// Récupère toutes les courses d'une agence
  Future<List<CourseModel>> getCoursesByAgence(String agenceId) async {
    try {
      final snapshot = await _firestore.collection('courses').where('agenceId', isEqualTo: agenceId).orderBy('dateCreation', descending: true).get();

      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur récupération courses agence: $e');
      return [];
    }
  }

  /// Récupère les courses d'un coursier
  Future<List<CourseModel>> getCoursesByCoursier(String coursierId) async {
    try {
      final snapshot = await _firestore.collection('courses').where('coursierId', isEqualTo: coursierId).orderBy('dateCreation', descending: true).get();

      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur récupération courses coursier: $e');
      return [];
    }
  }

  /// Récupère les courses par statut
  Future<List<CourseModel>> getCoursesByStatut(String agenceId, String statut) async {
    try {
      final snapshot = await _firestore.collection('courses').where('agenceId', isEqualTo: agenceId).where('statut', isEqualTo: statut).orderBy('dateCreation', descending: true).get();

      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur récupération courses par statut: $e');
      return [];
    }
  }

  /// Met à jour une course
  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('courses').doc(courseId).update(data);
      print('✅ [COURSE_SERVICE] Course mise à jour: $courseId');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur mise à jour course: $e');
      rethrow;
    }
  }

  /// Attribue une course à un coursier
  Future<void> attribuerCourse(String courseId, String coursierId, String coursierNom) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'coursierId': coursierId,
        'coursierNom': coursierNom,
        'statut': 'enCours',
        'dateAttribution': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ [COURSE_SERVICE] Course attribuée au coursier: $coursierId');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur attribution course: $e');
      rethrow;
    }
  }

  /// Démarre une course
  Future<void> demarrerCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'dateDebut': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ [COURSE_SERVICE] Course démarrée: $courseId');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur démarrage course: $e');
      rethrow;
    }
  }

  /// Termine une course
  Future<void> terminerCourse(String courseId, double montantReel, List<String> justificatifs) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'statut': 'terminee',
        'dateFin': Timestamp.fromDate(DateTime.now()),
        'montantReel': montantReel,
        'justificatifs': justificatifs,
      });
      print('✅ [COURSE_SERVICE] Course terminée: $courseId');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur fin course: $e');
      rethrow;
    }
  }

  /// Annule une course
  Future<void> annulerCourse(String courseId, String commentaire) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'statut': 'annulee',
        'commentaire': commentaire,
        'modifiedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ [COURSE_SERVICE] Course annulée: $courseId');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur annulation course: $e');
      rethrow;
    }
  }

  /// Crée une transaction pour le paiement d'une course
  Future<void> createTransactionForCourse(CourseModel course, String userId) async {
    try {
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'recette',
        categorieRecette: 'courses',
        montant: course.montantReel ?? course.montantEstime,
        description: 'Paiement course - ${course.tache}',
        reference: 'COURSE-${course.id}',
        agenceId: course.agenceId,
        userId: userId,
        date: DateTime.now(),
      );

      await _firestore.collection('transactions').add(transaction.toFirestore());
      print('✅ [COURSE_SERVICE] Transaction créée pour course: ${course.id}');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur création transaction: $e');
      rethrow;
    }
  }

  /// Supprime une course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).delete();
      print('✅ [COURSE_SERVICE] Course supprimée: $courseId');
    } catch (e) {
      print('❌ [COURSE_SERVICE] Erreur suppression course: $e');
      rethrow;
    }
  }
}
