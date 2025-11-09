import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollService {
  static final FirebaseFirestore _fire = FirebaseFirestore.instance;

  /// Create a poll under matches/{matchId}/polls
  static Future<void> createPoll({
    required String matchId,
    required String title,
    required List<String> options,
    bool allowMultiple = false,
    DateTime? closesAt,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final coll = _fire.collection('matches').doc(matchId).collection('polls');
    final doc = coll.doc();
    final optionMaps = options
        .asMap()
        .entries
        .map((e) => {'id': 'opt_${e.key}', 'label': e.value})
        .toList();

    await doc.set({
      'title': title,
      'allowMultiple': allowMultiple,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'closesAt': closesAt != null ? Timestamp.fromDate(closesAt) : null,
      'isClosed': false,
      'options': optionMaps,
    });
  }

  /// Stream polls for a match (poll documents only)
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamPollsForMatch(String matchId) {
    final coll = _fire.collection('matches').doc(matchId).collection('polls');
    return coll.orderBy('createdAt', descending: true).snapshots();
  }

  /// Vote (overwrites user's vote to enforce one-vote-per-user)
  static Future<void> vote({
    required String matchId,
    required String pollId,
    required List<String> optionIds,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final voteDoc = _fire
        .collection('matches')
        .doc(matchId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(uid);

    await voteDoc.set({
      'userId': uid,
      'optionIds': optionIds,
      'votedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream votes for a poll
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamVotes({
    required String matchId,
    required String pollId,
  }) {
    return _fire
        .collection('matches')
        .doc(matchId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .snapshots();
  }

  /// Stream the current user's vote document for a poll
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserVote({
    required String matchId,
    required String pollId,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return _fire
        .collection('matches')
        .doc(matchId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(uid)
        .snapshots();
  }

  /// Get whether current user already voted for this poll
  static Future<DocumentSnapshot<Map<String, dynamic>>> getUserVote({
    required String matchId,
    required String pollId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final voteDoc = _fire
        .collection('matches')
        .doc(matchId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(uid);
    return voteDoc.get();
  }

  /// Delete a poll and its votes. Only creator can delete.
  static Future<void> deletePoll({
    required String matchId,
    required String pollId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Non authentifié');

    // Get poll to check creator
    final pollDoc = await _fire
        .collection('matches')
        .doc(matchId)
        .collection('polls')
        .doc(pollId)
        .get();

    if (!pollDoc.exists) throw Exception('Sondage introuvable');
    final data = pollDoc.data()!;
    if (data['createdBy'] != uid) throw Exception('Seul le créateur peut supprimer ce sondage');

    // Delete votes subcollection first
    final votesSnapshot = await _fire
        .collection('matches')
        .doc(matchId)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .get();

    final batch = _fire.batch();
    for (var doc in votesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    // Delete poll document
    batch.delete(pollDoc.reference);
    await batch.commit();
  }

  /// Close or reopen a poll (creator-only via rules)
  static Future<void> setPollClosed({
    required String matchId,
    required String pollId,
    required bool closed,
  }) async {
    final ref = _fire
        .collection('matches')
        .doc(matchId)
        .collection('polls')
        .doc(pollId);

    await ref.update({
      'isClosed': closed,
      // If closing now, stamp closesAt; if reopening, clear it
      'closesAt': closed ? FieldValue.serverTimestamp() : null,
    });
  }
}
