import 'package:flutter/material.dart';

import 'plan_icon.dart';
import 'tokens.dart';

/// One segment in the shared bottom instrument dock of all four players
/// (Space, Plate, Section, Walk).
class PlayerDockItem {
  const PlayerDockItem({
    required this.key,
    required this.symbol,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key key;
  final PlanSymbol symbol;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
}

/// Unified bottom instrument bar shared by SpacePlayer, PlatePlayer,
/// SectionPlayer and WalkPlayer: crisp hairline top rule, full-width evenly
/// divided segments, and a 2 px architectural top indicator for the active dock.
class PlayerDockBar extends StatelessWidget {
  const PlayerDockBar({super.key, required this.items});

  final List<PlayerDockItem> items;

  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.ground,
        border: Border(top: BorderSide(color: c.line.withValues(alpha: .7))),
      ),
      child: SafeArea(
        top: false,
        child: largeText
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final item in items)
                      _Segment(item: item, compact: true),
                  ],
                ),
              )
            : Row(
                children: [
                  for (final item in items)
                    Expanded(child: _Segment(item: item, compact: false)),
                ],
              ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.item, required this.compact});

  final PlayerDockItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    // Marble on lamp, porphyry on marble: gold is kept for collected items.
    final activeColor = Theme.of(context).brightness == Brightness.dark
        ? c.ink
        : c.accent;
    final enabled = item.onTap != null;
    final fg = !enabled
        ? c.secondary.withValues(alpha: .45)
        : item.selected
        ? activeColor
        : c.ink;
    return Semantics(
      button: true,
      selected: item.selected,
      enabled: enabled,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        key: item.key,
        onTap: item.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: item.selected ? c.poche : Colors.transparent,
            border: Border(
              top: BorderSide(
                color: item.selected ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 6,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlanIcon(item.symbol, size: 19, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: TypeRole.bodyFamily,
                    fontSize: 13,
                    fontWeight: item.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    letterSpacing: .2,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent top-right Sources action for every player AppBar.
class PlayerSourcesButton extends StatelessWidget {
  const PlayerSourcesButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: const PlanIcon(PlanSymbol.story, size: 21),
  );
}
