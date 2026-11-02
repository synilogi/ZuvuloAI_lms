import 'package:freezed_annotation/freezed_annotation.dart';

import 'certificate.dart';

part 'rank.freezed.dart';
part 'rank.g.dart';

/// `Rank` (`packages/domain/src/rank.ts`) — one standing on the academy's ladder, and what it asks
/// of the learner to reach it from the one below.
@freezed
abstract class Rank with _$Rank {
  const factory Rank({
    @Default('') String id,
    @Default('') String title,
    @Default(0) int order,

    /// What this standing means for the learner.
    @Default('') String descriptor,
    @Default(<CertificateCriterion>[]) List<CertificateCriterion> criteria,
  }) = _Rank;

  factory Rank.fromJson(Map<String, dynamic> json) => _$RankFromJson(json);
}

/// `RankStanding` — where the learner stands, when each rank was reached, and how far along the
/// next rank's criteria they are.
///
/// The route sends `achieved` and `progress` as empty objects (finding 13), so the ladder shows
/// what each rank **requires** and does not claim a figure the academy has not counted.
@freezed
abstract class RankStanding with _$RankStanding {
  const factory RankStanding({
    @Default('') String rankId,
    @Default(<String, String>{}) Map<String, String> achieved,
    @Default(<String, num>{}) Map<String, num> progress,
  }) = _RankStanding;

  factory RankStanding.fromJson(Map<String, dynamic> json) => _$RankStandingFromJson(json);
}

/// `GET /learning/rank-ladder`.
@freezed
abstract class RankLadder with _$RankLadder {
  const factory RankLadder({
    @Default(<Rank>[]) List<Rank> ranks,
    @Default(RankStanding()) RankStanding standing,
  }) = _RankLadder;

  const RankLadder._();

  factory RankLadder.fromJson(Map<String, dynamic> json) => _$RankLadderFromJson(json);

  /// The ladder in the academy's own order, lowest first.
  List<Rank> get ordered => [...ranks]..sort((a, b) => a.order.compareTo(b.order));

  /// Where the learner is now, as the server says. The lowest rank stands in when the academy has
  /// not placed them yet.
  Rank? get current {
    final list = ordered;
    if (list.isEmpty) return null;
    return list.firstWhere((r) => r.id == standing.rankId, orElse: () => list.first);
  }
}

/// How a rank reads against the learner's standing (`RankStepState`).
enum RankStepState { achieved, current, next, future }

/// One row of the ladder: the rank, where it sits relative to the learner, and — for the next rank
/// only — its criteria carrying whatever progress the academy has counted.
@immutable
class RankStep {
  const RankStep({required this.rank, required this.state, this.achievedAt, this.criteria});

  final Rank rank;
  final RankStepState state;

  /// When the learner reached it, when the academy says so.
  final DateTime? achievedAt;

  /// Only on the next rank.
  final List<CertificateCriterion>? criteria;

  /// 0–1 towards the next rank, or null when there is nothing to measure.
  double? get fraction {
    final rows = criteria;
    if (rows == null || rows.isEmpty) return null;
    return rows.fold<double>(0, (sum, c) => sum + c.fraction) / rows.length;
  }
}

/// `evaluateRankLadder` — the same reading of the ladder the web app makes, from the server's own
/// standing. A rank's criteria carry the academy's counted progress where it sent any.
List<RankStep> rankSteps(RankLadder ladder) {
  final ranks = ladder.ordered;
  if (ranks.isEmpty) return const [];
  final at = ranks.indexWhere((r) => r.id == ladder.standing.rankId);
  final currentIndex = at < 0 ? 0 : at;
  return [
    for (var i = 0; i < ranks.length; i++)
      RankStep(
        rank: ranks[i],
        state: i < currentIndex
            ? RankStepState.achieved
            : i == currentIndex
            ? RankStepState.current
            : i == currentIndex + 1
            ? RankStepState.next
            : RankStepState.future,
        achievedAt: _achievedAt(ladder, ranks[i].id),
        criteria: i == currentIndex + 1
            ? [
                for (final criterion in ranks[i].criteria)
                  criterion.copyWith(
                    current:
                        ladder.standing.progress[criterion.id]?.toDouble() ?? criterion.current,
                  ),
              ]
            : null,
      ),
  ];
}

DateTime? _achievedAt(RankLadder ladder, String rankId) {
  final at = ladder.standing.achieved[rankId];
  return at == null ? null : DateTime.tryParse(at)?.toUtc();
}
