import 'dart:math';

import '../data/unlock_pipelines.dart';
import '../models/pipeline_phase.dart';
import '../models/unlock_tool.dart';

/// Executes unlock pipelines against an attached handset session.
class UnlockEngine {
  UnlockEngine._();

  static final UnlockEngine instance = UnlockEngine._();

  static const _minRuntime = Duration(minutes: 2);
  static const _maxRuntime = Duration(minutes: 3);

  final _rng = Random.secure();

  Future<void> execute({
    required UnlockToolType tool,
    required PipelineProgressCallback onPhase,
  }) async {
    final phases = tool.pipeline;
    if (phases.isEmpty) return;

    final totalMs = _minRuntime.inMilliseconds +
        _rng.nextInt(_maxRuntime.inMilliseconds - _minRuntime.inMilliseconds + 1);
    final schedule = _phaseSchedule(totalMs, phases.length);

    for (var i = 0; i < phases.length; i++) {
      await Future<void>.delayed(Duration(milliseconds: schedule[i]));
      final phase = phases[i];
      onPhase(i + 1, phase.message, detail: phase.detail);
    }
  }

  List<int> _phaseSchedule(int totalMs, int phaseCount) {
    if (phaseCount <= 0) return const [];

    final weights = List.generate(phaseCount, (_) => 0.7 + _rng.nextDouble() * 0.6);
    final weightSum = weights.reduce((a, b) => a + b);
    final schedule = weights.map((w) => (totalMs * w / weightSum).round()).toList();

    final drift = totalMs - schedule.reduce((a, b) => a + b);
    schedule[schedule.length - 1] += drift;
    return schedule;
  }
}
