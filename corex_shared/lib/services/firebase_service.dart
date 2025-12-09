import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static CollectionReference get users => firestore.collection('users');
  static CollectionReference get agences => firestore.collection('agences');
  static CollectionReference get colis => firestore.collection('colis');
  static CollectionReference get livraisons => firestore.collection('livraisons');
  static CollectionReference get transactions => firestore.collection('transactions');
  static CollectionReference get zones => firestore.collection('zones');
  static CollectionReference get agencesTransport => firestore.collection('agencesTransport');
  static CollectionReference get clients => firestore.collection('clients');
  static CollectionReference get counters => firestore.collection('counters');

  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Activer la persistance hors ligne
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static Future<void> enableNetwork() async {
    await firestore.enableNetwork();
  }

  static Future<void> disableNetwork() async {
    await firestore.disableNetwork();
  }
}
