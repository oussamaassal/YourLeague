// filepath: c:\Users\Blue\Desktop\YourLeague\lib\User\features\matches\presentation\pages\bracket_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/domain/entities/leaderboard.dart';
import 'package:yourleague/User/features/matches/domain/entities/match.dart' as m;
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_states.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;

class BracketPage extends StatefulWidget {
  final String tournamentId;
  final String? highlightMatchId; // optional: to highlight a specific match slot
  final String? organizerUid; // optional: to enable organizer-only controls
  const BracketPage({super.key, required this.tournamentId, this.highlightMatchId, this.organizerUid});

  @override
  State<BracketPage> createState() => _BracketPageState();
}

class _BracketPageState extends State<BracketPage> {
  bool _isOrganizer = false;
  String? _tournamentName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MatchesCubit>().getBracketData(widget.tournamentId);
      await _loadOrganizer();
    });
  }

  Future<void> _loadOrganizer() async {
    try {
      final currentUid = context.read<AuthCubit>().currentUser?.uid;
      if (currentUid == null) return;

      if (widget.organizerUid != null) {
        setState(() {
          _isOrganizer = widget.organizerUid == currentUid;
        });
        // don't return; still fetch tournament name below
      }

      final doc = await fs.FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournamentId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final organizerRef = data['organizer'];
        String? organizerId;
        if (organizerRef is fs.DocumentReference) {
          organizerId = organizerRef.id;
        } else if (organizerRef is String) {
          final parts = organizerRef.split('/');
          organizerId = parts.isNotEmpty ? parts.last : null;
        }
        setState(() {
          _isOrganizer = organizerId != null && organizerId == currentUid || _isOrganizer;
          _tournamentName = (data['name'] as String?)?.trim();
        });
      }
    } catch (e) {
      setState(() => _isOrganizer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournamentName != null && _tournamentName!.isNotEmpty
            ? '${_tournamentName!} · Bracket'
            : 'Bracket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await context.read<MatchesCubit>().getBracketData(widget.tournamentId);
              await _loadOrganizer();
            },
          ),
        ],
      ),
      body: BlocBuilder<MatchesCubit, MatchesState>(
        builder: (context, state) {
          if (state is MatchesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BracketDataLoaded) {
            final data = _computeBracketWithResults(state.leaderboards, state.matches);
            final highlight = _detectHighlightSlot(state.matches, data, widget.highlightMatchId);
            return _BracketView(
              tournamentId: widget.tournamentId,
              qf: data.qf,
              sf: data.sf,
              f: data.f,
              allMatches: state.matches,
              highlight: highlight,
              isOrganizer: _isOrganizer,
            );
          }
          return const Center(child: Text('Loading bracket...'));
        },
      ),
    );
  }

  _BracketData _computeBracketWithResults(List<Leaderboard> leaderboards, List<m.Match> matches) {
    // Seed top 8 and pad with TBD
    final teams = leaderboards.map((e) => e.teamName).toList();
    final padded = List<String>.from(teams);
    while (padded.length < 8) padded.add('TBD');
    if (padded.length > 8) padded.removeRange(8, padded.length);

    // QF seed order: 1-8, 4-5, 3-6, 2-7
    final qf = <_Pair>[
      _Pair(padded[0], padded[7]),
      _Pair(padded[3], padded[4]),
      _Pair(padded[2], padded[5]),
      _Pair(padded[1], padded[6]),
    ];

    String winnerOf(_Pair p) {
      m.Match? found;
      for (final x in matches) {
        final same = (x.team1Name == p.a && x.team2Name == p.b) || (x.team1Name == p.b && x.team2Name == p.a);
        if (same) { found = x; break; }
      }
      if (found == null) return 'Winner of ${_pairLabel(qf.indexOf(p))}';
      if (found.score1 == found.score2) return 'Winner of ${_pairLabel(qf.indexOf(p))}';
      final aScore = found.team1Name == p.a ? found.score1 : found.score2;
      final bScore = found.team1Name == p.a ? found.score2 : found.score1;
      return aScore > bScore ? p.a : p.b;
    }

    // SF from QF winners
    final qfWinners = [winnerOf(qf[0]), winnerOf(qf[1]), winnerOf(qf[2]), winnerOf(qf[3])];
    final sf = <_Pair>[
      _Pair(qfWinners[0], qfWinners[1]),
      _Pair(qfWinners[2], qfWinners[3]),
    ];

    // Final from SF winners if possible
    String winnerOfSf(_Pair p, int sfIndex) {
      final a = p.a; final b = p.b;
      if (_isPlaceholder(a) || _isPlaceholder(b)) return 'Winner of SF${sfIndex+1}';
      m.Match? found;
      for (final x in matches) {
        final same = (x.team1Name == a && x.team2Name == b) || (x.team1Name == b && x.team2Name == a);
        if (same) { found = x; break; }
      }
      if (found == null || found.score1 == found.score2) return 'Winner of SF${sfIndex+1}';
      final aScore = found.team1Name == a ? found.score1 : found.score2;
      final bScore = found.team1Name == a ? found.score2 : found.score1;
      return aScore > bScore ? a : b;
    }

    final sfWinners = [winnerOfSf(sf[0], 0), winnerOfSf(sf[1], 1)];
    final f = <_Pair>[
      _Pair(sfWinners[0], sfWinners[1]),
    ];

    return _BracketData(qf: qf, sf: sf, f: f);
  }

  String _pairLabel(int qfIndex) => 'QF${qfIndex + 1}';
  bool _isPlaceholder(String x) => x == 'TBD' || x.startsWith('Winner of');

  _HighlightSlot _detectHighlightSlot(List<m.Match> matches, _BracketData data, String? matchId) {
    if (matchId == null) return _HighlightSlot.none();
    m.Match? match;
    for (final x in matches) {
      if (x.id == matchId) {
        match = x;
        break;
      }
    }
    if (match == null) return _HighlightSlot.none();

    final a = match.team1Name;
    final b = match.team2Name;

    // Helper to check unordered equality
    bool samePair(_Pair p) {
      return (p.a == a && p.b == b) || (p.a == b && p.b == a);
    }

    for (var i = 0; i < data.qf.length; i++) {
      if (samePair(data.qf[i])) return _HighlightSlot.qf(i);
    }
    // For SF and Final, we try to infer by halves
    // Left half pool: QF1+QF2; Right half pool: QF3+QF4
    final leftPool = {
      data.qf[0].a, data.qf[0].b, data.qf[1].a, data.qf[1].b
    };
    final rightPool = {
      data.qf[2].a, data.qf[2].b, data.qf[3].a, data.qf[3].b
    };

    if (leftPool.contains(a) && leftPool.contains(b)) return _HighlightSlot.sf(0);
    if (rightPool.contains(a) && rightPool.contains(b)) return _HighlightSlot.sf(1);

    // If teams are from different halves, it's likely the Final
    return _HighlightSlot.f(0);
  }
}

class _BracketView extends StatelessWidget {
  final String tournamentId;
  final List<_Pair> qf;
  final List<_Pair> sf;
  final List<_Pair> f;
  final List<m.Match> allMatches;
  final _HighlightSlot highlight;
  final bool isOrganizer;

  const _BracketView({
    // removed key to avoid unused optional parameter warning
    required this.tournamentId,
    required this.qf,
    required this.sf,
    required this.f,
    required this.allMatches,
    required this.highlight,
    required this.isOrganizer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoundColumn(
                    title: 'Quarterfinals',
                    matches: List.generate(4, (i) => _matchCard(context, qf[i], _Round.qf, i)),
                  ),
                  const SizedBox(width: 24),
                  _RoundColumn(
                    title: 'Semifinals',
                    matches: List.generate(2, (i) => _matchCard(context, sf[i], _Round.sf, i)),
                  ),
                  const SizedBox(width: 24),
                  _RoundColumn(
                    title: 'Final',
                    matches: List.generate(1, (i) => _matchCard(context, f[i], _Round.f, i)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _matchCard(BuildContext context, _Pair pair, _Round round, int index) {
    final score = _findScore(pair);
    final isHighlight =
        highlight.round == round && highlight.index == index && highlight.enabled;

    return Card(
      elevation: isHighlight ? 6 : 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isHighlight ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _teamRow(context, pair.a, isTop: true),
            const Divider(height: 16),
            _teamRow(context, pair.b),
            if (score != null) ...[
              const SizedBox(height: 8),
              Text('Score: ${score.$1} - ${score.$2}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            if (isOrganizer && pair.a != 'TBD' && pair.b != 'TBD' && !pair.a.startsWith('Winner of'))
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.read<MatchesCubit>().setBracketMatchWinner(
                      tournamentId: tournamentId,
                      teamA: pair.a,
                      teamB: pair.b,
                      winnerName: pair.a,
                    ),
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: Text('Set ${pair.a} wins'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => context.read<MatchesCubit>().setBracketMatchWinner(
                      tournamentId: tournamentId,
                      teamA: pair.a,
                      teamB: pair.b,
                      winnerName: pair.b,
                    ),
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: Text('Set ${pair.b} wins'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  (int, int)? _findScore(_Pair pair) {
    m.Match? found;
    for (final x in allMatches) {
      final sameOrder = x.team1Name == pair.a && x.team2Name == pair.b;
      final flipped = x.team1Name == pair.b && x.team2Name == pair.a;
      if (sameOrder || flipped) {
        found = x;
        break;
      }
    }
    if (found == null) return null;
    if (found.team1Name == pair.a) {
      return (found.score1, found.score2);
    } else {
      return (found.score2, found.score1);
    }
  }

  Widget _teamRow(BuildContext context, String name, {bool isTop = false}) {
    final isTbd = name.toUpperCase() == 'TBD' || name.startsWith('Winner of');
    return Row(
      children: [
        Icon(
          isTbd ? Icons.hourglass_empty : Icons.sports_soccer,
          size: 18,
          color: isTbd ? Colors.grey : Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: isTop ? FontWeight.w600 : FontWeight.normal,
              color: isTbd ? Colors.grey : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundColumn extends StatelessWidget {
  final String title;
  final List<Widget> matches;
  const _RoundColumn({required this.title, required this.matches});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...matches,
        ],
      ),
    );
  }
}

class _Pair {
  final String a;
  final String b;
  _Pair(this.a, this.b);
}

class _BracketData {
  final List<_Pair> qf;
  final List<_Pair> sf;
  final List<_Pair> f;
  _BracketData({required this.qf, required this.sf, required this.f});
}

enum _Round { qf, sf, f }

class _HighlightSlot {
  final _Round round;
  final int index;
  final bool enabled;
  const _HighlightSlot(this.round, this.index, this.enabled);
  factory _HighlightSlot.none() => const _HighlightSlot(_Round.qf, -1, false);
  factory _HighlightSlot.qf(int i) => _HighlightSlot(_Round.qf, i, true);
  factory _HighlightSlot.sf(int i) => _HighlightSlot(_Round.sf, i, true);
  factory _HighlightSlot.f(int i) => _HighlightSlot(_Round.f, i, true);
}
