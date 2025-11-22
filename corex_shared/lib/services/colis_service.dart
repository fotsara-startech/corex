import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/colis_model.dart';
import 'firebase_service.dart';

class ColisService extends GetxService {
  Future<String> generateNumeroSuivi() async {
    final year = DateTime.now().year;
    final counterDoc = FirebaseService.counters.doc('colis_$year');

    return FirebaseService.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterDoc);

      int counter = 0;
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        counter = data?['count'] ?? 0;
      }

      counter++;
      transaction.set(counterDoc, {'count': counter});

      return 'COL-$year-${counter.toString().padLeft(6, '0')}';
    });
  }

  Future<void> createColis(ColisModel colis) async {
    await FirebaseService.colis.doc(colis.id).set(colis.toFirestore());
  }

  Future<void> updateColis(String colisId, Map<String, dynamic> data) async {
    await FirebaseService.colis.doc(colisId).update(data);
  }

  Future<ColisModel?> getColisById(String colisId) async {
    final doc = await FirebaseService.colis.doc(colisId).get();
    if (!doc.exists) return null;
    return ColisModel.fromFirestore(doc);
  }

  Future<List<ColisModel>> getAllColis() async {
    final snapshot = await FirebaseService.colis.get();
    return snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();
  }

  Future<List<ColisModel>> getColisByAgence(String agenceId) async {
    final snapshot = await FirebaseService.colis.where('agenceCorexId', isEqualTo: agenceId).get();
    return snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();
  }

  Future<List<ColisModel>> getColisByCommercial(String commercialId) async {
    final snapshot = await FirebaseService.colis.where('commercialId', isEqualTo: commercialId).get();
    return snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();
  }

  Future<List<ColisModel>> getColisByStatut(String statut) async {
    final snapshot = await FirebaseService.colis.where('statut', isEqualTo: statut).get();
    return snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();
  }

  Future<ColisModel?> searchColisByNumero(String numeroSuivi) async {
    final snapshot = await FirebaseService.colis.where('numeroSuivi', isEqualTo: numeroSuivi).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return ColisModel.fromFirestore(snapshot.docs.first);
  }

  Future<void> updateStatut(
    String colisId,
    String newStatut,
    String userId,
    String? commentaire,
  ) async {
    final colisDoc = await FirebaseService.colis.doc(colisId).get();
    if (!colisDoc.exists) {
      throw Exception('Colis non trouvé');
    }

    final colis = ColisModel.fromFirestore(colisDoc);

    // Ajouter à l'historique
    final historique = List<HistoriqueStatut>.from(colis.historique);
    historique.add(HistoriqueStatut(
      statut: newStatut,
      date: DateTime.now(),
      userId: userId,
      commentaire: commentaire,
    ));

    // Préparer les données à mettre à jour
    final updateData = {
      'statut': newStatut,
      'historique': historique.map((h) => h.toMap()).toList(),
    };

    // Ajouter les dates selon le statut
    if (newStatut == 'enregistre') {
      updateData['dateEnregistrement'] = Timestamp.now();
    } else if (newStatut == 'livre' || newStatut == 'retire') {
      updateData['dateLivraison'] = Timestamp.now();
    }

    await FirebaseService.colis.doc(colisId).update(updateData);
  }

  Stream<List<ColisModel>> watchColisByAgence(String agenceId) {
    return FirebaseService.colis.where('agenceCorexId', isEqualTo: agenceId).snapshots().map((snapshot) => snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList());
  }

  Stream<List<ColisModel>> watchColisByCommercial(String commercialId) {
    return FirebaseService.colis.where('commercialId', isEqualTo: commercialId).snapshots().map((snapshot) => snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList());
  }
}
