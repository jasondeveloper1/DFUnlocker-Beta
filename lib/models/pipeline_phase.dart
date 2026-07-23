class PipelinePhase {
  const PipelinePhase({
    required this.message,
    this.detail,
  });

  final String message;
  final String? detail;
}

typedef PipelineProgressCallback = void Function(
  int phaseIndex,
  String message, {
  String? detail,
});
