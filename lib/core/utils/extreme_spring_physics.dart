import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class ExtremeSpringPhysics extends ScrollPhysics {
  final double springStrength;
  final double damping;

  const ExtremeSpringPhysics({
    this.springStrength = 800.0,
    this.damping = 15.0,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  @override
  ExtremeSpringPhysics applyTo(ScrollPhysics? ancestor) {
    return ExtremeSpringPhysics(
      springStrength: springStrength,
      damping: damping,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange) {
      final bool beyondMax = position.pixels > position.maxScrollExtent;

      final double end = beyondMax
          ? position.maxScrollExtent
          : position.minScrollExtent;

      return SpringSimulation(
        SpringDescription(
          mass: 0.8,
          stiffness: springStrength,
          damping: damping,
        ),
        position.pixels,     // start
        end,                 // end
        velocity * 0.3,      // velocity
        tolerance: Tolerance.defaultTolerance,
      );
    }

    return super.createBallisticSimulation(position, velocity);
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.outOfRange) {
      final double overscroll = position.pixels + offset;
      const double maxOverscroll = 100.0;

      if (overscroll > position.maxScrollExtent) {
        final double excess =
            overscroll - position.maxScrollExtent;
        return offset * (1.0 - (excess / maxOverscroll).clamp(0.0, 1.0));
      }

      if (overscroll < position.minScrollExtent) {
        final double excess =
            position.minScrollExtent - overscroll;
        return offset * (1.0 - (excess / maxOverscroll).clamp(0.0, 1.0));
      }
    }

    return offset;
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}
