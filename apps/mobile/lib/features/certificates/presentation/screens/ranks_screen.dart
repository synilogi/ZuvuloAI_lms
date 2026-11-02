import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/certificate_controller.dart';
import '../widgets/certificate_parts.dart';

/// `/ranks` — the academy's ladder and where this learner stands on it. The standing is the
/// server's; the app never works out a rank (§18, §26). A shell body.
class RanksScreen extends ConsumerWidget {
  const RanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(rankLadderProvider.future),
      child: AsyncView<RankLadder>(
        value: ref.watch(rankLadderProvider),
        onRetry: () => ref.invalidate(rankLadderProvider),
        data: (ladder) {
          final steps = rankSteps(ladder);
          if (steps.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 360,
                  child: EmptyState(title: l10n.ranksEmptyTitle, message: l10n.ranksEmptyBody),
                ),
              ],
            );
          }
          final current = ladder.current;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s4, Space.s6),
            children: [
              if (current != null) ...[
                // Where the learner stands, on the gold the app keeps for what is earned.
                AppCard(
                  color: context.colors.hue(Hue.gold).soft,
                  padding: const EdgeInsets.symmetric(vertical: Space.s5, horizontal: Space.s4),
                  child: Column(
                    children: [
                      // The ring shows the standing itself: the academy publishes no figure for
                      // how far along the next rank a learner is (finding 13), and the app will not
                      // invent one.
                      RankRing(rankName: current.title, progressToNext: null),
                      const SizedBox(height: Space.s2),
                      Text(
                        l10n.ranksProgressUnknown,
                        textAlign: TextAlign.center,
                        style: context.type.caption.copyWith(color: context.colors.text),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.sectionGap),
              ],
              RankLadderList(steps: steps),
            ],
          );
        },
      ),
    );
  }
}
