import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _fire = FirebaseFirestore.instance;

  /// Check if a given uid is listed in admins collection
  static Future<bool> isAdmin(String uid) async {
    final doc = await _fire.collection('admins').doc(uid).get();
    return doc.exists;
  }

  /// Convenience: current user is admin
  static Future<bool> currentUserIsAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    return isAdmin(uid);
  }
}
