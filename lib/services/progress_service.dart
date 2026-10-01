import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Milestones this person has opened. A provisional measure for the Today
/// strip until P19 earns tesserae; P19 imports this key unchanged.
class MilestoneProgress extends ChangeNotifier {
  static const key = 'milion_opened_milestones';
  final Set<String> _opened = {};
  bool _disposed = false;
  Set<String> get opened => Set.unmodifiable(_opened);
  bool isOpened(String milestoneId) => _opened.contains(milestoneId);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    final stored = (await SharedPreferences.getInstance()).getStringList(key);
    if (_disposed) return;
    _opened.addAll(stored ?? const []);
    notifyListeners();
  }

  Future<void> open(String milestoneId) async {
    if (!_opened.add(milestoneId)) return;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setStringList(
      key,
      _opened.toList()..sort(),
    );
  }
}

class ProgressScope extends InheritedNotifier<MilestoneProgress> {
  const ProgressScope({
    super.key,
    required MilestoneProgress progress,
    required super.child,
  }) : super(notifier: progress);
  static final _none = MilestoneProgress();
  static MilestoneProgress of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProgressScope>()?.notifier ??
      _none;
}
