import 'package:flutter/foundation.dart';

class PollOption {
  final String id;
  final String label;
  int votes;

  PollOption({required this.id, required this.label, this.votes = 0});
}

class PollModel {
  final String id;
  final String title;
  final String? matchId;
  final String? matchTitle;
  final bool allowMultiple;
  final DateTime createdAt;
  DateTime? closesAt;
  bool isClosed;
  final List<PollOption> options;
  final Map<String, Set<String>> userVotes; // deviceUserId -> optionIds

  PollModel({
    required this.id,
    required this.title,
    this.matchId,
    this.matchTitle,
    required this.allowMultiple,
    required this.createdAt,
    this.closesAt,
    this.isClosed = false,
    required this.options,
    Map<String, Set<String>>? userVotes,
  }) : userVotes = userVotes ?? {};

  int get totalVotes => options.fold<int>(0, (sum, o) => sum + o.votes);

  double percentageFor(String optionId) {
    final total = totalVotes;
    if (total == 0) return 0.0;
    final opt = options.firstWhere((o) => o.id == optionId);
    return opt.votes / total;
  }
}