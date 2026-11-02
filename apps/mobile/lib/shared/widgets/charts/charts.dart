import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../icons/app_icons.dart';

/// One data point: [label] (the x category), [value] (plotted) and [valueLabel] (the formatted
/// value shown in read-outs, e.g. "₹12,400" or "38 learners").
@immutable
class ChartPoint {
  const ChartPoint(this.label, this.value, this.valueLabel);

  final String label;
  final double value;
  final String valueLabel;
}

/// A tiny inline trend line, decorative next to a number; its data is summarised by [semanticLabel].
class Sparkline extends StatelessWidget {
  const Sparkline({required this.values, required this.semanticLabel, super.key, this.height = 32});

  final List<double> values;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _LinePainter(values: values, color: context.colors.accent, fill: false),
        ),
      ),
    );
  }
}

/// A frame for full charts: the chart, and a toggle to a list read-out of every value — the
/// accessible alternative and the phone-friendly view (§20).
class _ChartFrame extends StatefulWidget {
  const _ChartFrame({required this.points, required this.chart, required this.title});

  final List<ChartPoint> points;
  final Widget chart;
  final String title;

  @override
  State<_ChartFrame> createState() => _ChartFrameState();
}

class _ChartFrameState extends State<_ChartFrame> {
  bool _asList = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(header: true, child: Text(widget.title, style: context.type.titleS)),
            ),
            IconButton(
              tooltip: _asList ? l10n.actionShowAsChart : l10n.actionShowAsList,
              onPressed: () => setState(() => _asList = !_asList),
              icon: AppIcon(_asList ? AppIcons.chart : AppIcons.list, size: 20, color: c.muted),
            ),
          ],
        ),
        if (_asList)
          Column(
            children: [
              for (final p in widget.points)
                MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.s2),
                    child: Row(
                      children: [
                        Expanded(child: Text(p.label, style: context.type.bodyM)),
                        Text(p.valueLabel, style: context.type.titleS),
                      ],
                    ),
                  ),
                ),
            ],
          )
        else
          Semantics(
            label: [
              for (final p in widget.points) l10n.chartReadoutItem(p.label, p.valueLabel),
            ].join('; '),
            excludeSemantics: true,
            child: widget.chart,
          ),
      ],
    );
  }
}

/// A line chart over time with first/last labels on the x axis.
class TrendChart extends StatelessWidget {
  const TrendChart({required this.title, required this.points, super.key, this.height = 160});

  final String title;
  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ChartFrame(
      title: title,
      points: points,
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: CustomPaint(
              painter: _LinePainter(
                values: [for (final p in points) p.value],
                color: c.accent,
                fill: true,
                grid: c.border,
              ),
            ),
          ),
          if (points.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.s1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(points.first.label, style: context.type.caption.copyWith(color: c.muted)),
                  Text(points.last.label, style: context.type.caption.copyWith(color: c.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Vertical columns, one hue; the tallest value is labelled.
class ColumnChart extends StatelessWidget {
  const ColumnChart({required this.title, required this.points, super.key, this.height = 160});

  final String title;
  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = points.fold<double>(0, (m, p) => math.max(m, p.value));
    return _ChartFrame(
      title: title,
      points: points,
      chart: SizedBox(
        height: height + 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final p in points)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: maxValue == 0 ? 2 : math.max(2, height * p.value / maxValue),
                        decoration: BoxDecoration(
                          color: p.value == maxValue && maxValue > 0 ? c.accent : c.track,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xs)),
                        ),
                      ),
                      const SizedBox(height: Space.s1),
                      Text(
                        p.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.noScaling,
                        style: context.type.caption.copyWith(color: c.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A ranked horizontal bar list — the phone's replacement for wide tables (§20). Labels and
/// values are real text, so it reads correctly at any text scale.
class BarList extends StatelessWidget {
  const BarList({required this.points, super.key, this.title});

  final String? title;
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxValue = points.fold<double>(0, (m, p) => math.max(m, p.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s2),
            child: Semantics(header: true, child: Text(title!, style: context.type.titleS)),
          ),
        for (final p in points)
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(p.label, style: context.type.bodyM)),
                      const SizedBox(width: Space.s2),
                      Text(p.valueLabel, style: context.type.titleS),
                    ],
                  ),
                  const SizedBox(height: Space.s1),
                  ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: LinearProgressIndicator(
                        value: maxValue == 0 ? 0 : p.value / maxValue,
                        minHeight: 6,
                        backgroundColor: c.track,
                        color: c.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values, required this.color, required this.fill, this.grid});

  final List<double> values;
  final Color color;
  final bool fill;
  final Color? grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (grid != null) {
      final gridPaint = Paint()
        ..color = grid!
        ..strokeWidth = 1;
      for (var i = 0; i <= 3; i++) {
        final y = size.height * i / 3;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
    if (values.length < 2) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final pad = size.height * 0.08;
    Offset at(int i) => Offset(
      size.width * i / (values.length - 1),
      pad + (size.height - pad * 2) * (1 - (values[i] - lo) / span),
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    if (fill) {
      final area = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(at(values.length - 1), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.color != color || old.grid != grid;
}
