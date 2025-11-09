import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MatchVideoService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> streamVideosForMatch(String matchId) {
    return _db
        .collection('matches')
        .doc(matchId)
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> addYouTubeVideo({
    required String matchId,
    required String title,
    required String url,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final doc = _db.collection('matches').doc(matchId).collection('videos').doc();
    await doc.set({
      'id': doc.id,
      'matchId': matchId,
      'title': title,
      'source': 'youtube',
      'youtubeUrl': url,
      'createdAt': Timestamp.now(),
      'createdBy': uid,
    });
  }

  static Future<void> uploadVideoBytes({
    required String matchId,
    required String title,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = _db.collection('matches').doc(matchId).collection('videos').doc().id;
    final path = 'matches/$matchId/videos/${id}_$filename';
    final ref = _storage.ref(path);
    final meta = SettableMetadata(contentType: contentType ?? 'video/mp4');
    await ref.putData(bytes, meta);
    final downloadUrl = await ref.getDownloadURL();

    await _db
        .collection('matches')
        .doc(matchId)
        .collection('videos')
        .doc(id)
        .set({
      'id': id,
      'matchId': matchId,
      'title': title,
      'source': 'storage',
      'storagePath': path,
      'downloadUrl': downloadUrl,
      'createdAt': Timestamp.now(),
      'createdBy': uid,
    });
  }
}