import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum MeasureMotion { settle, dig, sweep }

abstract final class MotionToken {
  static const durations = {
    MeasureMotion.settle: Duration(milliseconds: 160),
    MeasureMotion.dig: Duration(milliseconds: 360),
    MeasureMotion.sweep: Duration(milliseconds: 520),
  };
  static const curves = {
    MeasureMotion.settle: Curves.easeOutCubic,
    MeasureMotion.dig: Curves.easeInOutCubic,
    MeasureMotion.sweep: Curves.easeOutQuart,
  };
  static Duration duration(MeasureMotion motion, {required bool reduced}) =>
      reduced ? Duration.zero : durations[motion]!;
  static Future<void> detent({bool enabled = true}) async {
    if (enabled) await HapticFeedback.lightImpact();
  }

  static Future<void> collect({bool enabled = true}) async {
    if (enabled) await HapticFeedback.mediumImpact();
  }
}
