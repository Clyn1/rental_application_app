import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  DocumentReference<Map<String, dynamic>> doc(String collectionPath, String docId) {
    return _db.collection(collectionPath).doc(docId);
  }

  CollectionReference<Map<String, dynamic>> subcollection(
    String parentCollection,
    String parentDocId,
    String subcollectionName,
  ) {
    return _db.collection(parentCollection).doc(parentDocId).collection(subcollectionName);
  }

  WriteBatch batch() => _db.batch();

  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) action) {
    return _db.runTransaction(action);
  }
}
