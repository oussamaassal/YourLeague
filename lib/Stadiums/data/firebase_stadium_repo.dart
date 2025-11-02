import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/entities/stadium.dart';
import '../domain/repos/stadium_repo.dart';

class FirebaseStadiumRepo implements StadiumRepo {
  final fs.FirebaseFirestore _firestore = fs.FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<void> createStadium(Stadium stadium) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      final stadiumData = stadium.toFirestore();
      
      // Add userId if available
      if (currentUser != null && stadiumData['userId'] == null) {
        stadiumData['userId'] = currentUser.uid;
      }

      await _firestore.collection('stadiums').doc(stadium.id).set(stadiumData);
    } catch (e) {
      throw Exception('Failed to create stadium: $e');
    }
  }

  @override
  Future<Stadium?> getStadium(String stadiumId) async {
    try {
      final doc = await _firestore.collection('stadiums').doc(stadiumId).get();
      if (doc.exists) {
        return Stadium.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get stadium: $e');
    }
  }

  @override
  Future<List<Stadium>> getAllStadiums() async {
    try {
      final snapshot = await _firestore
          .collection('stadiums')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Stadium.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stadiums: $e');
    }
  }

  @override
  Future<List<Stadium>> getStadiumsByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('stadiums')
          .where('userId', isEqualTo: userId)
          .get();
      // Sort in memory to avoid requiring composite index
      final stadiums = snapshot.docs
          .map((doc) => Stadium.fromFirestore(doc.data(), doc.id))
          .toList();
      stadiums.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return stadiums;
    } catch (e) {
      throw Exception('Failed to get stadiums by user: $e');
    }
  }

  @override
  Stream<List<Stadium>> watchAllStadiums() {
    try {
      return _firestore
          .collection('stadiums')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Stadium.fromFirestore(doc.data(), doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to watch stadiums: $e');
    }
  }

  @override
  Stream<Stadium?> watchStadium(String stadiumId) {
    try {
      return _firestore
          .collection('stadiums')
          .doc(stadiumId)
          .snapshots()
          .map((doc) => doc.exists
              ? Stadium.fromFirestore(doc.data()!, doc.id)
              : null);
    } catch (e) {
      throw Exception('Failed to watch stadium: $e');
    }
  }

  @override
  Future<void> updateStadium(Stadium stadium) async {
    try {
      await _firestore
          .collection('stadiums')
          .doc(stadium.id)
          .update(stadium.toFirestore());
    } catch (e) {
      throw Exception('Failed to update stadium: $e');
    }
  }

  @override
  Future<void> deleteStadium(String stadiumId) async {
    try {
      await _firestore.collection('stadiums').doc(stadiumId).delete();
    } catch (e) {
      throw Exception('Failed to delete stadium: $e');
    }
  }
}

