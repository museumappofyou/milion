import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../atlas/atlas_assets.dart';
import '../atlas/certainty.dart';
import '../content/models.dart' show Honesty;
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/player_bar.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../shell/original_photo.dart';
import '../space/snapshot_builder.dart';
import '../walls/wall_player.dart' show SourcesSheet;
import 'siege.dart';
import 'siege_controller.dart';
import 'siege_painter.dart';

enum SiegePanel { story, accounts }

/// 1453 in 53 days (TM and SB, P15: XIX): a map sequence over the Atlas's
/// own base, from the camp on 6 April to the assault on 29 May. Every event
/// carries the accounts that report it, each attributed; the drawing is a
/// RECONSTRUCTION.
class SiegePlayer extends StatefulWidget {
  const SiegePlayer({super.key, required this.siege, this.atlas});
  final SiegeManifest siege;

  /// The Atlas's data; loaded on first use when not given.
  final Future<AtlasAssets>? atlas;
  @override
  SiegePlayerState createState() => SiegePlayerState();
}

class SiegePlayerState extends State<SiegePlayer>
    with SingleTickerProviderStateMixin {
  late final SiegeController controller = SiegeController(widget.siege);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  SiegePanel? _open;
  SiegePanel? get openPanel => _open;
  SiegeBase? base;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      controller.advance(dt);
    });
    controller.addListener(_changed);
    (widget.atlas ?? AtlasAssets.load()).then((atlas) async {
      final b = await SiegeBase.render(atlas, widget.siege);
      if (mounted) {
        setState(() => base = b);
      } else {
        b.image.dispose();
      }
    }, onError: (Object _) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (controller.reduced != reduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.setReduced(reduced);
      });
    }
  }

  void _changed() {
    if (controller.needsTicker && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!controller.needsTicker && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void controls(SiegePanel panel) =>
      setState(() => _open = _open == panel ? null : panel);
  void closeControls() => setState(() => _open = null);

  @override
  void dispose() {
    _ticker.dispose();
    controller.removeListener(_changed);
    controller.dispose();
    base?.image.dispose();
    super.dispose();
  }

  Future<void> showSources() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTheme.marble.colorScheme.surface,
    builder: (context) => Theme(
      data: DesignTheme.marble,
      child: SourcesSheet(
        ids: widget.siege.allSourceIds,
        intro: widget.siege.talkback,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DesignTheme.marble,
      child: Builder(
        builder: (context) {
          final s = context.l10n, lang = context.language;
          final c = controller, colours = MeasureColors.of(context);
          final m = widget.siege;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                m.title.inLanguage(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                PlayerSourcesButton(
                  key: const ValueKey('siege-appbar-sources'),
                  tooltip: s.sourcesTitle,
                  onPressed: showSources,
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      c.viewport = size;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Semantics(
                              label:
                                  '${m.title.inLanguage(lang)}. '
                                  '${m.talkback.inLanguage(lang)}',
                              hint: s.siegeHint,
                              customSemanticsActions: {
                                CustomSemanticsAction(label: s.plateNext): () =>
                                    c.step(1),
                                CustomSemanticsAction(
                                  label: s.platePrevious,
                                ): () =>
                                    c.step(-1),
                                CustomSemanticsAction(label: s.platePlay):
                                    c.playStory,
                              },
                              child: GestureDetector(
                                key: const ValueKey('siege-viewport'),
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  if (c.mode == SiegeMode.stills) c.step(1);
                                },
                                onScaleStart: (_) => _scale = 1,
                                onScaleUpdate: (d) {
                                  final k = size.width / c.view.width;
                                  c.panBy(
                                    -d.focalPointDelta.dx / k,
                                    d.focalPointDelta.dy / k,
                                  );
                                  if (d.scale != _scale) {
                                    c.zoomBy(d.scale / _scale);
                                    _scale = d.scale;
                                  }
                                },
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    key: const ValueKey('siege-paint'),
                                    size: Size.infinite,
                                    painter: SiegePainter(
                                      controller: c,
                                      base: base,
                                      ink: colours.ink,
                                      secondary: colours.secondary,
                                      accent: colours.accent,
                                      paper: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      text: TypeRole.measurement,
                                      language: lang,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (base == null)
                            Center(
                              child: Semantics(
                                label: s.siegeLoading,
                                child: const TesseraLoader(),
                              ),
                            ),
                          _SiegeLabels(
                            controller: c,
                            captionHeight: size.height * .32,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                DayScale(controller: c),
                if (_open case final panel?)
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: .5,
                      ),
                    ),
                    child: SiegeSheet(player: this, panel: panel),
                  ),
                PlayerDockBar(
                  items: [
                    PlayerDockItem(
                      key: const ValueKey('siege-story'),
                      symbol: PlanSymbol.story,
                      label: s.plateStory,
                      selected: _open == SiegePanel.story,
                      onTap: () => controls(SiegePanel.story),
                    ),
                    PlayerDockItem(
                      key: const ValueKey('siege-accounts'),
                      symbol: PlanSymbol.layers,
                      label: s.siegeAccounts,
                      selected: _open == SiegePanel.accounts,
                      onTap: () => controls(SiegePanel.accounts),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String siegeDate(DateTime d, String lang) =>
    DateFormat('d MMMM y', lang == 'tr' ? 'tr' : 'en').format(d);

class _SiegeLabels extends StatelessWidget {
  const _SiegeLabels({required this.controller, required this.captionHeight});
  final SiegeController controller;
  final double captionHeight;

  @override
  Widget build(BuildContext context) => SnapshotBuilder(
    listenable: controller,
    snapshot: () => (
      controller.caption,
      controller.currentBeat?.id,
      controller.mode,
      controller.day,
      controller.stillIndex,
    ),
    builder: (context) {
      final c = controller, lang = context.language, s = context.l10n;
      final ground = Theme.of(context).scaffoldBackgroundColor
          .withValues(alpha: .94);
      final caption = c.caption?.inLanguage(lang);
      final beat = c.currentBeat;
      return Stack(
        children: [
          Positioned(
            top: 8,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(color: ground),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: HonestyLabel(
                  c.honesty,
                  key: const ValueKey('siege-honesty'),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(color: ground),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        siegeDate(c.date, lang),
                        key: const ValueKey('siege-date'),
                        style: TypeRole.measurement.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        s.siegeDaysIn(c.day - 1),
                        style: TypeRole.measurement.copyWith(
                          fontSize: 11,
                          color: MeasureColors.of(context).secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (caption != null)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: captionHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ground,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: .5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.mode == SiegeMode.stills)
                            Text(
                              s.walkStill(
                                '${c.stillIndex + 1}',
                                '${c.manifest.stills.length}',
                              ),
                              style: TypeRole.measurement,
                            ),
                          if (beat != null)
                            Text(
                              beat.label.inLanguage(lang),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          Text(
                            caption,
                            key: const ValueKey('siege-caption'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// The 53 days as a measured scale: a tick a day, the story's days marked;
/// drag or tap to set the day.
class DayScale extends StatelessWidget {
  const DayScale({super.key, required this.controller});
  final SiegeController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final m = controller.manifest;
    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          int dayAt(double x) =>
              (((x - 16) / (w - 32)) * (m.days - 1)).round() + 1;
          return Semantics(
            slider: true,
            label: s.siegeDayScale,
            value: siegeDate(controller.date, lang),
            increasedValue: siegeDate(
              m.dateOf((controller.day + 1).clamp(1, m.days)),
              lang,
            ),
            decreasedValue: siegeDate(
              m.dateOf((controller.day - 1).clamp(1, m.days)),
              lang,
            ),
            onIncrease: () => controller.setDay(controller.day + 1),
            onDecrease: () => controller.setDay(controller.day - 1),
            child: GestureDetector(
              key: const ValueKey('siege-days'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => controller.setDay(dayAt(d.localPosition.dx)),
              onHorizontalDragUpdate: (d) =>
                  controller.setDay(dayAt(d.localPosition.dx)),
              child: CustomPaint(
                size: Size(w, 52),
                painter: _DayScalePainter(
                  controller: controller,
                  colours: MeasureColors.of(context),
                  language: lang,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayScalePainter extends CustomPainter {
  _DayScalePainter({
    required this.controller,
    required this.colours,
    required this.language,
  }) : super(repaint: controller);
  final SiegeController controller;
  final MeasureColors colours;
  final String language;

  @override
  void paint(Canvas canvas, Size size) {
    final m = controller.manifest;
    double x(int d) => 16 + (size.width - 32) * (d - 1) / (m.days - 1);
    final y = 18.0;
    final pen = Paint()
      ..color = colours.line
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x(1), y), Offset(x(m.days), y), pen);
    final beatDays = {for (final b in m.beats) b.day};
    for (var d = 1; d <= m.days; d++) {
      final date = m.dateOf(d);
      final major = date.day == 1 || beatDays.contains(d);
      canvas.drawLine(
        Offset(x(d), y - (major ? 6 : 3)),
        Offset(x(d), y + (major ? 6 : 3)),
        Paint()
          ..color = beatDays.contains(d) ? colours.accent : colours.line
          ..strokeWidth = beatDays.contains(d) ? 1.6 : 1,
      );
    }
    final fmt = DateFormat('d MMM', language == 'tr' ? 'tr' : 'en');
    for (final d in {1, m.days}) {
      final tp = TextPainter(
        text: TextSpan(
          text: fmt.format(m.dateOf(d)),
          style: TypeRole.measurement.copyWith(
            fontSize: 10,
            color: colours.secondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(d == 1 ? x(d) : x(d) - tp.width, y + 10));
    }
    // The day shown.
    final cx = x(controller.day);
    canvas.drawPath(
      Path()
        ..moveTo(cx, y - 2)
        ..lineTo(cx - 5, y - 11)
        ..lineTo(cx + 5, y - 11)
        ..close(),
      Paint()..color = colours.ink,
    );
  }

  @override
  bool shouldRepaint(_DayScalePainter old) =>
      old.controller != controller || old.colours != colours;
}

/// The docks: Story (reveal, story, beats) and Accounts (who tells each
/// event in view, by side).
class SiegeSheet extends StatelessWidget {
  const SiegeSheet({super.key, required this.player, required this.panel});
  final SiegePlayerState player;
  final SiegePanel panel;

  String _side(BuildContext context, AccountSide side) {
    final s = context.l10n;
    return switch (side) {
      AccountSide.byzantine => s.sideByzantine,
      AccountSide.venetian => s.sideVenetian,
      AccountSide.genoese => s.sideGenoese,
      AccountSide.ottoman => s.sideOttoman,
      AccountSide.ottomanGreek => s.sideOttomanGreek,
      AccountSide.slavonic => s.sideSlavonic,
      AccountSide.modern => s.sideModern,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final c = player.controller, m = c.manifest;
    final theme = Theme.of(context);
    final registry = AppScope.maybeOf(context)?.registry;
    final rows = switch (panel) {
      SiegePanel.story => <Widget>[
        if (c.reduced) Text(s.plateStillHint, style: theme.textTheme.bodySmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const ValueKey('siege-play-story'),
              onPressed: () {
                player.closeControls();
                c.playStory();
              },
              icon: const PlanIcon(PlanSymbol.story, size: 18),
              label: Text(s.platePlay),
            ),
            OutlinedButton.icon(
              key: const ValueKey('siege-play-reveal'),
              onPressed: () {
                player.closeControls();
                c.play();
              },
              icon: const PlanIcon(PlanSymbol.route, size: 18),
              label: Text(s.plateStartReveal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final b in m.beats)
          ListTile(
            key: ValueKey('siege-beat-${b.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(b.label.inLanguage(lang)),
            subtitle: Text(siegeDate(m.dateOf(b.day), lang)),
            onTap: () {
              player.closeControls();
              if (c.reduced) {
                final i = m.stills.indexOf(b.id);
                if (i >= 0) return c.stills(i);
              }
              c.goTo(b);
            },
          ),
      ],
      SiegePanel.accounts => <Widget>[
        if (c.focused.isEmpty)
          Text(s.siegeNoAccounts, style: theme.textTheme.bodySmall),
        for (final e in c.focused) ...[
          Text(
            e.label.inLanguage(lang),
            key: ValueKey('siege-event-${e.id}'),
            style: theme.textTheme.titleSmall,
          ),
          // A conjectural position or route, or a legend, is one reading of
          // the accounts: marked as such (the map draws it dashed).
          if (e.certainty == Certainty.conjectural) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: HonestyLabel(
                Honesty.IMAGINED,
                key: ValueKey('siege-imagined-${e.id}'),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(e.note.inLanguage(lang), style: theme.textTheme.bodySmall),
          if (e.photo case final photo?)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: ValueKey('siege-original-${e.id}'),
                onPressed: () =>
                    openOriginalPhoto(context, photo, title: e.label),
                icon: const Icon(Icons.photo_outlined, size: 18),
                label: Text(s.siegeSeeOriginal),
              ),
            ),
          const SizedBox(height: 6),
          for (final a in e.accounts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a.who.inLanguage(lang)} · ${_side(context, a.side)}',
                    style: TypeRole.measurement.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    a.says.inLanguage(lang),
                    style: theme.textTheme.bodyMedium,
                  ),
                  for (final id in a.sourceIds)
                    if (registry?.source(id) case final src?)
                      Text(
                        src.title.inLanguage(lang),
                        style: theme.textTheme.bodySmall,
                      ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .4,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        shrinkWrap: true,
        children: rows,
      ),
    );
  }
}
