import 'package:flutter/widgets.dart';

/// Rebuilds when [snapshot] changes, not on every notification of
/// [listenable]. Playback ticks the space controller every frame; a sheet or
/// label rebuilt per frame costs time on the main thread and, with TalkBack
/// on, sends a semantics update every frame (2026-11-09). [snapshot] must
/// name everything [builder] shows, as a record or other value with `==`.
class SnapshotBuilder extends StatefulWidget {
  const SnapshotBuilder({
    super.key,
    required this.listenable,
    required this.snapshot,
    required this.builder,
  });
  final Listenable listenable;
  final Object? Function() snapshot;
  final WidgetBuilder builder;

  @override
  State<SnapshotBuilder> createState() => _SnapshotBuilderState();
}

class _SnapshotBuilderState extends State<SnapshotBuilder> {
  late Object? _shown;

  @override
  void initState() {
    super.initState();
    _shown = widget.snapshot();
    widget.listenable.addListener(_changed);
  }

  void _changed() {
    final now = widget.snapshot();
    if (now != _shown) setState(() => _shown = now);
  }

  @override
  void didUpdateWidget(SnapshotBuilder old) {
    super.didUpdateWidget(old);
    if (old.listenable != widget.listenable) {
      old.listenable.removeListener(_changed);
      widget.listenable.addListener(_changed);
    }
    _shown = widget.snapshot();
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
