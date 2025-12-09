import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/client_model.dart';
import 'firebase_service.dart';

class ClientService extends GetxService {
  Future<String> createClient(ClientModel client) async {
    print('📝 [CLIENT_SERVICE] Création client: ${client.nom}');
    // Utiliser add() pour générer automatiquement l'ID
    final docRef = await FirebaseService.clients.add(client.toFirestore());
    print('✅ [CLIENT_SERVICE] Client créé avec ID: ${docRef.id}');
    return docRef.id;
  }

  Future<void> updateClient(String clientId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await FirebaseService.clients.doc(clientId).update(data);
  }

  Future<ClientModel?> getClientById(String clientId) async {
    print('🔍 [CLIENT_SERVICE] Recherche client: $clientId');
    final doc = await FirebaseService.clients.doc(clientId).get();
    if (!doc.exists) {
      print('❌ [CLIENT_SERVICE] Client $clientId n\'existe pas');
      return null;
    }
    final client = ClientModel.fromFirestore(doc);
    print('✅ [CLIENT_SERVICE] Client trouvé: ${client.nom}');
    return client;
  }

  Future<List<ClientModel>> getClientsByAgence(String agenceId) async {
    try {
      // Essayer avec orderBy
      final snapshot = await FirebaseService.clients.where('agenceId', isEqualTo: agenceId).orderBy('updatedAt', descending: true).get();
      return snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('⚠️ [CLIENT_SERVICE] Erreur avec orderBy, essai sans tri: $e');
      // Si l'index n'existe pas, récupérer sans tri
      final snapshot = await FirebaseService.clients.where('agenceId', isEqualTo: agenceId).get();
      final clients = snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
      // Trier côté client
      clients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return clients;
    }
  }

  Future<ClientModel?> searchClientByPhone(String telephone, String agenceId) async {
    print('🔍 [CLIENT_SERVICE] Recherche client par téléphone: $telephone');
    final snapshot = await FirebaseService.clients.where('agenceId', isEqualTo: agenceId).where('telephone', isEqualTo: telephone).limit(1).get();

    if (snapshot.docs.isEmpty) {
      print('❌ [CLIENT_SERVICE] Aucun client trouvé');
      return null;
    }

    final data = snapshot.docs.first.data() as Map<String, dynamic>?;
    print('✅ [CLIENT_SERVICE] Client trouvé: ${data?['nom'] ?? 'Inconnu'}');
    return ClientModel.fromFirestore(snapshot.docs.first);
  }

  Future<List<ClientModel>> searchClientsByName(String query, String agenceId) async {
    final snapshot = await FirebaseService.clients.where('agenceId', isEqualTo: agenceId).get();

    // Filtrage et tri côté client car Firestore ne supporte pas les recherches partielles
    final results = snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).where((client) => client.nom.toLowerCase().contains(query.toLowerCase())).toList();

    // Trier par nom
    results.sort((a, b) => a.nom.compareTo(b.nom));

    return results;
  }

  Future<void> deleteClient(String clientId) async {
    await FirebaseService.clients.doc(clientId).delete();
  }

  Stream<List<ClientModel>> watchClientsByAgence(String agenceId) {
    return FirebaseService.clients.where('agenceId', isEqualTo: agenceId).snapshots().map((snapshot) {
      final clients = snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
      // Trier côté client
      clients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return clients;
    });
  }
}
