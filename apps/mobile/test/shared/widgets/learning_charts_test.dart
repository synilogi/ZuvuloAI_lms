import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syniastrolms_mobile/shared/widgets/widgets.dart';

import '../../helpers/pump.dart';

void main() {
  test('enums parse backend values and fall back for unknown ones', () {
    expect(CoverMotif.parse('nakshatra'), CoverMotif.nakshatra);
    expect(CoverMotif.parse('comet'), CoverMotif.unknown);
    expect(LessonType.parse('assessment'), LessonType.assessment);
    expect(LessonType.parse(null), LessonType.unknown);
    expect(CertificateAccent.parse('saffron'), CertificateAccent.saffron);
    expect(CertificateAccent.parse('teal'), CertificateAccent.indigo);
  });

  group('QuizQuestionCard', () {
    testWidgets('single choice replaces the selection', (tester) async {
      Set<String>? last;
      await pumpThemed(
        tester,
        QuizQuestionCard(
          number: 1,
          total: 3,
          prompt: 'Q',
          kind: QuestionKind.single,
          options: const [QuestionOption('a', 'Sun'), QuestionOption('b', 'Moon')],
          selectedIds: const {'a'},
          onSelectionChanged: (v) => last = v,
        ),
      );
      expect(find.text('Question 1 of 3'), findsOneWidget);
      await tester.tap(find.text('Moon'));
      expect(last, {'b'});
    });

    testWidgets('multiple choice toggles within the selection', (tester) async {
      Set<String>? last;
      await pumpThemed(
        tester,
        QuizQuestionCard(
          number: 2,
          total: 3,
          prompt: 'Q',
          kind: QuestionKind.multiple,
          options: const [QuestionOption('a', 'Aries'), QuestionOption('c', 'Leo')],
          selectedIds: const {'a'},
          onSelectionChanged: (v) => last = v,
        ),
      );
      await tester.tap(find.text('Leo'));
      expect(last, {'a', 'c'});
      await tester.tap(find.text('Aries'));
      expect(last, <String>{});
    });

    testWidgets('true/false supplies its own options', (tester) async {
      Set<String>? last;
      await pumpThemed(
        tester,
        QuizQuestionCard(
          number: 3,
          total: 3,
          prompt: 'Q',
          kind: QuestionKind.trueFalse,
          onSelectionChanged: (v) => last = v,
        ),
      );
      await tester.tap(find.text('False'));
      expect(last, {QuizQuestionCard.falseId});
    });
  });

  testWidgets('RubricScorer stays within 0 and the maximum and totals the scores', (tester) async {
    final scores = <String, num>{'a': 9, 'b': 0};
    await pumpThemed(
      tester,
      StatefulBuilder(
        builder: (context, setState) => RubricScorer(
          scores: scores,
          onChanged: (id, v) => setState(() => scores[id] = v),
          criteria: const [
            ScoringCriterion(id: 'a', title: 'Accuracy', maxPoints: 10),
            ScoringCriterion(id: 'b', title: 'Reasoning', maxPoints: 5),
          ],
        ),
      ),
    );
    expect(find.text('Total 9 / 15'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase').first);
    await tester.pump();
    expect(scores['a'], 10);
    await tester.tap(find.byTooltip('Increase').first);
    await tester.pump();
    expect(scores['a'], 10, reason: 'cannot exceed the maximum');
    await tester.tap(find.byTooltip('Decrease').last);
    await tester.pump();
    expect(scores['b'], 0, reason: 'cannot go below zero');
    expect(find.text('Total 10 / 15'), findsOneWidget);
  });

  testWidgets('LessonNavBar shows the server rule hint instead of Mark complete', (tester) async {
    await pumpThemed(
      tester,
      const LessonNavBar(completion: CompletionHint('Watch 80% to complete')),
    );
    expect(find.text('Watch 80% to complete'), findsOneWidget);
    expect(find.text('Mark complete'), findsNothing);
  });

  testWidgets('LessonNavBar marks complete and navigates', (tester) async {
    final events = <String>[];
    await pumpThemed(
      tester,
      LessonNavBar(
        completion: const CanComplete(),
        onPrevious: () => events.add('prev'),
        onNext: () => events.add('next'),
        onMarkComplete: () => events.add('complete'),
      ),
    );
    await tester.tap(find.byTooltip('Previous'));
    await tester.tap(find.text('Mark complete'));
    await tester.tap(find.byTooltip('Next'));
    expect(events, ['prev', 'complete', 'next']);
  });

  testWidgets('CurriculumTree opens the current chapter and announces lock reasons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    CurriculumLessonNode? tapped;
    await pumpThemed(
      tester,
      CurriculumTree(
        onLessonTap: (l) => tapped = l,
        chapters: const [
          CurriculumChapterNode(
            id: 'c1',
            title: 'Chapter 1',
            lessons: [
              CurriculumLessonNode(
                id: 'l1',
                title: 'Welcome',
                type: LessonType.video,
                state: LessonNodeState.completed,
                isCurrent: true,
              ),
              CurriculumLessonNode(
                id: 'l2',
                title: 'Houses',
                type: LessonType.reading,
                state: LessonNodeState.locked,
                lockedReason: 'Pass the quiz.',
              ),
            ],
          ),
        ],
      ),
    );
    expect(find.text('1 of 2 lessons'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Houses, Reading, Locked, Pass the quiz.')),
      findsOneWidget,
    );
    await tester.tap(find.text('Houses'));
    expect(tapped?.id, 'l2');
    handle.dispose();
  });

  testWidgets('CertificateCanvas stays proportionate in landscape and portrait', (tester) async {
    const data = CertificateCanvasData(
      academyName: 'Academy',
      heading: 'Certificate',
      statement: 'has completed',
      learnerName: 'Asha Verma',
      courseTitle: 'Foundations',
      credentialId: 'SYN-1',
      accent: CertificateAccent.saffron,
    );
    for (final size in const [Size(360, 800), Size(800, 360)]) {
      await pumpThemed(
        tester,
        const CertificateCanvas(data: data, semanticLabel: 'Certificate for Asha Verma'),
        size: size,
      );
      final box = tester.getSize(find.byType(CertificateCanvas));
      expect(box.width / box.height, closeTo(842 / 595, 0.01));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('StudyWeekBars announces each day', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpThemed(
      tester,
      const StudyWeekBars(
        days: [
          StudyDay(label: 'Mon', minutes: 1),
          StudyDay(label: 'Tue', minutes: 0),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Mon: 1 minute'), findsOneWidget);
    expect(find.bySemanticsLabel('Tue: no study'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('charts toggle to an accessible list read-out', (tester) async {
    await pumpThemed(
      tester,
      const TrendChart(
        title: 'Enrolments',
        points: [ChartPoint('Jun', 12, '12 learners'), ChartPoint('Jul', 18, '18 learners')],
      ),
    );
    expect(find.text('18 learners'), findsNothing);
    await tester.tap(find.byTooltip('Show as list'));
    await tester.pump();
    expect(find.text('18 learners'), findsOneWidget);
    expect(find.byTooltip('Show as chart'), findsOneWidget);
  });

  testWidgets('BarList reads as text rows', (tester) async {
    await pumpThemed(
      tester,
      const BarList(
        points: [ChartPoint('Jyotish', 10, '10 learners'), ChartPoint('Houses', 0, '0 learners')],
      ),
    );
    expect(find.text('10 learners'), findsOneWidget);
    expect(find.text('0 learners'), findsOneWidget);
  });
}
