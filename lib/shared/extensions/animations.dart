import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension Animations on Widget {
  Widget scaleShimmerShake({
    required int duration,
    required Color color,
    required double hz,
    required Curve curve,
    required int delay,
  }) {
    return animate()
        .scale(duration: duration.ms, curve: curve)
        .then(delay: delay.ms)
        .shimmer(duration: duration.ms, color: color)
        .then(delay: delay.ms)
        .shake(hz: hz, curve: curve);
  }

  Widget shimmer({required int duration, required Color color}) {
    return animate().shimmer(duration: duration.ms, color: color);
  }

  Widget shake({required double hz, required Curve curve}) {
    return animate().shake(hz: hz, curve: curve);
  }

  Widget fadeIn({required int duration, required int delay}) {
    return animate().fadeIn(duration: duration.ms, delay: delay.ms);
  }

  Widget slideY({
    required double begin,
    required double end,
    required int duration,
    required Curve curve,
  }) {
    return animate().slideY(
      begin: begin,
      end: end,
      duration: duration.ms,
      curve: curve,
    );
  }
}
