import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadPropertyImage({
    required String propertyId,
    required File file,
    required String fileName,
  }) async {
    final ref = _storage.ref().child('properties/$propertyId/$fileName');
    final uploadTask = await ref.putFile(file);
    return uploadTask.ref.getDownloadURL();
  }

  Future<List<String>> uploadPropertyImages({
    required String propertyId,
    required List<File> files,
  }) async {
    final uploadFutures = files.asMap().entries.map((entry) {
      final index = entry.key;
      final file = entry.value;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
      return uploadPropertyImage(propertyId: propertyId, file: file, fileName: fileName);
    });
    return Future.wait(uploadFutures);
  }

  Future<String> uploadProfilePhoto({required String userId, required File file}) async {
    final ref = _storage.ref().child('profile_photos/$userId.jpg');
    final uploadTask = await ref.putFile(file);
    return uploadTask.ref.getDownloadURL();
  }
}
