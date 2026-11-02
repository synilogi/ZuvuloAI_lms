import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/format/durations.dart';
import '../../../core/media/media_url_resolver.dart';
import '../../../core/theme/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/widgets.dart';
import '../application/media_auth.dart';

/// A point of interest on the scrubber (`content.video.markers`).
class VideoMarker {
  const VideoMarker({required this.position, required this.label});

  final Duration position;
  final String label;
}

/// The lesson video player (§13, §14): the file is streamed from `GET /media/:id` with the bearer
/// header, so range requests come straight from the API. Position is reported at most every 15 s
/// while playing, and on pause and exit, for the server to record (§17).
class AppVideoPlayer extends ConsumerStatefulWidget {
  const AppVideoPlayer({
    required this.url,
    super.key,
    this.markers = const [],
    this.startAt,
    this.onPosition,
    this.onEnded,
    this.autoPlay = false,
  });

  /// The `/media/<id>` path from the lesson's content.
  final String url;
  final List<VideoMarker> markers;

  /// Where to resume from, as the server recorded it.
  final Duration? startAt;

  /// Throttled position updates: the seconds watched and the fraction of the video.
  final void Function(Duration position, double fraction)? onPosition;
  final VoidCallback? onEnded;
  final bool autoPlay;

  static const reportEvery = Duration(seconds: 15);

  @override
  ConsumerState<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends ConsumerState<AppVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;
  DateTime? _lastReport;
  bool _endedReported = false;
  bool _fullscreen = false;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final resolved = ref.read(mediaUrlResolverProvider).resolve(widget.url);
    if (resolved == null) {
      setState(() => _error = 'unresolvable');
      return;
    }
    // Headers go only to the API host — the resolver has already refused anything else.
    final headers = await ref.read(mediaAuthHeadersProvider.future);
    final controller = VideoPlayerController.networkUrl(resolved, httpHeaders: headers);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      if (widget.startAt != null) await controller.seekTo(widget.startAt!);
      controller.addListener(_onTick);
      setState(() => _controller = controller);
      if (widget.autoPlay) await controller.play();
    } on Object catch (error) {
      await controller.dispose();
      if (mounted) setState(() => _error = error);
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final value = controller.value;

    if (value.isPlaying) {
      final now = DateTime.now();
      if (_lastReport == null || now.difference(_lastReport!) >= AppVideoPlayer.reportEvery) {
        _lastReport = now;
        _report();
      }
    }
    if (value.position >= value.duration && value.duration > Duration.zero && !_endedReported) {
      _endedReported = true;
      _report();
      widget.onEnded?.call();
    }
    if (mounted) setState(() {});
  }

  void _report() {
    final value = _controller?.value;
    if (value == null || !value.isInitialized || value.duration == Duration.zero) return;
    widget.onPosition?.call(
      value.position,
      (value.position.inMilliseconds / value.duration.inMilliseconds).clamp(0.0, 1.0),
    );
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      // Pausing is a good moment to tell the server where they are.
      _report();
    } else {
      await controller.play();
    }
  }

  Future<void> _skip(Duration by) async {
    final controller = _controller;
    if (controller == null) return;
    final target = controller.value.position + by;
    await controller.seekTo(
      target < Duration.zero
          ? Duration.zero
          : (target > controller.value.duration ? controller.value.duration : target),
    );
  }

  Future<void> _setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
    setState(() => _speed = speed);
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _fullscreen = !_fullscreen);
    // Video is the one screen that turns (§2.3).
    await SystemChrome.setPreferredOrientations(
      _fullscreen
          ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : const [DeviceOrientation.portraitUp],
    );
    await SystemChrome.setEnabledSystemUIMode(
      _fullscreen ? SystemUiMode.immersive : SystemUiMode.edgeToEdge,
    );
  }

  @override
  void dispose() {
    // Leaving reports the last position, so nothing watched is lost.
    _report();
    _controller?.removeListener(_onTick);
    unawaited(_controller?.dispose());
    if (_fullscreen) {
      unawaited(SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]));
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_error != null) {
      return _Stage(
        child: StateLayout(
          icon: AppIcons.error,
          tone: Tone.danger,
          title: l10n.mediaVideoFailed,
          actionLabel: l10n.actionRetry,
          onAction: () {
            setState(() => _error = null);
            unawaited(_open());
          },
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _Stage(child: Center(child: CircularProgressIndicator()));
    }

    return _Stage(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          if (controller.value.isBuffering) const Center(child: CircularProgressIndicator()),
          _Controls(
            controller: controller,
            markers: widget.markers,
            speed: _speed,
            fullscreen: _fullscreen,
            onPlayPause: _togglePlay,
            onSkip: _skip,
            onSpeed: _setSpeed,
            onFullscreen: _toggleFullscreen,
          ),
        ],
      ),
    );
  }
}

/// Video always sits on the deep indigo-black ground, in either theme (§22.2).
class _Stage extends StatelessWidget {
  const _Stage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: ColoredBox(color: context.colors.mediaGround, child: child),
  );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.markers,
    required this.speed,
    required this.fullscreen,
    required this.onPlayPause,
    required this.onSkip,
    required this.onSpeed,
    required this.onFullscreen,
  });

  final VideoPlayerController controller;
  final List<VideoMarker> markers;
  final double speed;
  final bool fullscreen;
  final VoidCallback onPlayPause;
  final void Function(Duration) onSkip;
  final void Function(double) onSpeed;
  final VoidCallback onFullscreen;

  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = controller.value;
    final ink = context.colors.mediaInk;
    final position = value.position;
    final duration = value.duration;

    return Container(
      padding: const EdgeInsets.fromLTRB(Space.s2, Space.s4, Space.s2, Space.s1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [context.colors.mediaGround, context.colors.mediaGround.withValues(alpha: 0)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Scrubber(controller: controller, markers: markers),
          Row(
            children: [
              IconButton(
                tooltip: value.isPlaying ? l10n.mediaPause : l10n.mediaPlay,
                onPressed: onPlayPause,
                icon: AppIcon(value.isPlaying ? AppIcons.pause : AppIcons.play, color: ink),
              ),
              IconButton(
                tooltip: l10n.mediaBack10,
                onPressed: () => onSkip(const Duration(seconds: -10)),
                icon: AppIcon(AppIcons.back, color: ink),
              ),
              IconButton(
                tooltip: l10n.mediaForward10,
                onPressed: () => onSkip(const Duration(seconds: 10)),
                icon: AppIcon(AppIcons.forward, color: ink),
              ),
              Expanded(
                child: Text(
                  '${AppDurations.clock(position.inSeconds)} / ${AppDurations.clock(duration.inSeconds)}',
                  style: context.type.caption.copyWith(color: ink),
                ),
              ),
              PopupMenuButton<double>(
                tooltip: l10n.mediaSpeed,
                initialValue: speed,
                onSelected: onSpeed,
                itemBuilder: (context) => [
                  for (final option in _speeds)
                    PopupMenuItem(
                      value: option,
                      child: Text(l10n.mediaSpeedValue(option.toString())),
                    ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s3),
                  child: Text(
                    l10n.mediaSpeedValue(speed.toString()),
                    style: context.type.label.copyWith(color: ink),
                  ),
                ),
              ),
              IconButton(
                tooltip: fullscreen ? l10n.mediaExitFullscreen : l10n.mediaFullscreen,
                onPressed: onFullscreen,
                icon: AppIcon(fullscreen ? AppIcons.close : AppIcons.external, color: ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.controller, required this.markers});

  final VideoPlayerController controller;
  final List<VideoMarker> markers;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final duration = value.duration.inMilliseconds;
    final position = duration == 0 ? 0.0 : value.position.inMilliseconds / duration;
    final colors = context.colors;

    return Semantics(
      label: context.l10n.progressPercentComplete((position * 100).round()),
      child: SizedBox(
        height: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Slider(
              value: position.clamp(0.0, 1.0),
              onChanged: (fraction) =>
                  controller.seekTo(Duration(milliseconds: (fraction * duration).round())),
              activeColor: colors.accent,
              inactiveColor: colors.mediaInk.withValues(alpha: 0.24),
            ),
            if (duration > 0)
              IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      for (final marker in markers)
                        Positioned(
                          left:
                              (marker.position.inMilliseconds / duration).clamp(0.0, 1.0) *
                              (constraints.maxWidth - 8),
                          top: 9,
                          child: Container(
                            width: 3,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colors.warn,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
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
