import 'package:flutter/material.dart';
import '../core/runtime_config.dart';
import '../data/unlock_pipelines.dart';
import '../models/device_info.dart';
import '../models/phone_specs.dart';
import '../models/unlock_tool.dart';
import '../services/device_connection_controller.dart';
import '../services/phone_specs_service.dart';
import '../services/unlock_engine.dart';
import '../services/usb_device_detector.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_shell.dart';
import '../widgets/device_phone_image.dart';
import '../widgets/step_progress_bar.dart';

class UnlockFlowScreen extends StatefulWidget {
  const UnlockFlowScreen({
    super.key,
    required this.tool,
    this.initialDevice,
    this.initialSpecs,
  });

  final UnlockToolType tool;
  final DeviceInfo? initialDevice;
  final PhoneSpecs? initialSpecs;

  @override
  State<UnlockFlowScreen> createState() => _UnlockFlowScreenState();
}

class _UnlockFlowScreenState extends State<UnlockFlowScreen> {
  final _deviceConnection = DeviceConnectionController.instance;
  UnlockFlowStep _step = UnlockFlowStep.connect;
  DeviceInfo? _device;
  PhoneSpecs? _deviceSpecs;
  int _processStep = 0;
  String _currentMessage = '';
  String? _currentDetail;
  final List<String> _messageLog = [];
  bool _isBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _deviceSpecs = widget.initialSpecs;
    _deviceConnection.addListener(_onDeviceChanged);
    _loadSpecsForDevice(_previewDevice);
  }

  void _onDeviceChanged() {
    if (!mounted) return;
    _loadSpecsForDevice(_previewDevice);
    setState(() {});
  }

  void _loadSpecsForDevice(DeviceInfo? device) {
    if (device == null) {
      if (_deviceSpecs != null) {
        setState(() => _deviceSpecs = null);
      }
      return;
    }

    final specs = PhoneSpecsService.instance.resolveSync(device);
    if (specs == _deviceSpecs) return;
    setState(() => _deviceSpecs = specs ?? widget.initialSpecs);
  }

  @override
  void dispose() {
    _deviceConnection.removeListener(_onDeviceChanged);
    super.dispose();
  }

  DeviceInfo? get _liveDevice =>
      _deviceConnection.currentDevice ?? widget.initialDevice;

  int get _progressStep => switch (_step) {
        UnlockFlowStep.connect => 1,
        UnlockFlowStep.detect => 2,
        UnlockFlowStep.process => 3,
        UnlockFlowStep.done => 4,
      };

  Future<void> _connectDevice() async {
    final live = _liveDevice ?? await UsbDeviceDetector.instance.detectDevice();
    if (live == null) {
      if (!mounted) return;
      setState(() {
        _error = 'No phone detected. Plug in via USB and tap Trust on your device.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
      _step = UnlockFlowStep.detect;
    });

    try {
      await Future<void>.delayed(RuntimeConfig.deviceScanDelay);
      final refreshed = await UsbDeviceDetector.instance.detectDevice() ?? live;

      if (!mounted) return;
      setState(() {
        _device = refreshed;
      });
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _startProcess() async {
    final device = _device;
    if (device == null) return;

    final phases = widget.tool.pipeline;
    if (phases.isEmpty) return;

    setState(() {
      _isBusy = true;
      _step = UnlockFlowStep.process;
      _processStep = 1;
      _messageLog.clear();
      _currentMessage = phases.first.message;
      _currentDetail = phases.first.detail;
    });

    try {
      await UnlockEngine.instance.execute(
        tool: widget.tool,
        onPhase: (step, message, {detail}) {
          if (!mounted) return;
          setState(() {
            if (_currentMessage.isNotEmpty && step > 1) {
              _messageLog.add(_currentMessage);
            }
            _processStep = step;
            _currentMessage = message;
            _currentDetail = detail;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _error = 'The process was interrupted. Please try again.';
        _step = UnlockFlowStep.detect;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _step = UnlockFlowStep.done;
    });
  }

  void _reset() {
    setState(() {
      _step = UnlockFlowStep.connect;
      _device = null;
      _processStep = 0;
      _currentMessage = '';
      _currentDetail = null;
      _messageLog.clear();
      _isBusy = false;
      _error = null;
    });
  }

  DeviceInfo? get _previewDevice => _device ?? _liveDevice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppShell(
        maxWidth: 1000,
        maxHeight: 680,
        leftChild: Padding(
          padding: const EdgeInsets.fromLTRB(40, 36, 32, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppLogo(size: 32)),
              const SizedBox(height: 28),
              Text(
                widget.tool.shortTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              StepProgressBar(totalSteps: 4, currentStep: _progressStep),
              const SizedBox(height: 28),
              Expanded(child: _buildStepContent()),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                const SizedBox(height: 12),
              ],
              _buildActions(),
            ],
          ),
        ),
        rightChild: _DevicePreviewPanel(
          step: _step,
          device: _previewDevice,
          specs: _deviceSpecs,
          tool: widget.tool,
          processStep: _processStep,
          totalProcessSteps: widget.tool.pipeline.length,
          currentMessage: _currentMessage,
          currentDetail: _currentDetail,
          hasActiveLink: _liveDevice != null,
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      UnlockFlowStep.connect => _ConnectStep(
          isBusy: _isBusy,
          liveDevice: _liveDevice,
        ),
      UnlockFlowStep.detect => _DetectStep(device: _device, isBusy: _isBusy),
      UnlockFlowStep.process => _ProcessStep(
          message: _currentMessage,
          detail: _currentDetail,
          log: _messageLog,
          step: _processStep,
          total: widget.tool.pipeline.length,
        ),
      UnlockFlowStep.done => _device != null
          ? _DoneStep(tool: widget.tool, device: _device!)
          : const SizedBox.shrink(),
    };
  }

  Widget _buildActions() {
    return Row(
      children: [
        BackButtonCircle(
          onPressed: _isBusy
              ? null
              : () {
                  if (_step == UnlockFlowStep.connect || _step == UnlockFlowStep.done) {
                    Navigator.of(context).pop();
                  } else {
                    _reset();
                  }
                },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: _actionLabel,
            isLoading: _isBusy,
            onPressed: _isBusy ? null : _onPrimaryAction,
          ),
        ),
      ],
    );
  }

  String get _actionLabel => switch (_step) {
        UnlockFlowStep.connect =>
          _liveDevice != null ? 'Use detected device' : 'Connect device',
        UnlockFlowStep.detect => 'Start process',
        UnlockFlowStep.process => 'Processing…',
        UnlockFlowStep.done => 'Done — back to tools',
      };

  void _onPrimaryAction() {
    switch (_step) {
      case UnlockFlowStep.connect:
        _connectDevice();
      case UnlockFlowStep.detect:
        _startProcess();
      case UnlockFlowStep.process:
        break;
      case UnlockFlowStep.done:
        Navigator.of(context).pop();
    }
  }
}

class _ConnectStep extends StatelessWidget {
  const _ConnectStep({required this.isBusy, this.liveDevice});

  final bool isBusy;
  final DeviceInfo? liveDevice;

  @override
  Widget build(BuildContext context) {
    final detected = liveDevice != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoLabel(label: 'Device connection'),
        const SizedBox(height: 16),
        GlowCard(
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: isBusy
                    ? const CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)
                    : Icon(
                        detected ? Icons.check_circle_outline : Icons.usb_rounded,
                        color: AppColors.accent,
                        size: detected ? 32 : 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detected ? '${liveDevice!.model} detected' : 'Plug your phone',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detected
                          ? 'USB connection active — ${liveDevice!.manufacturer} · ${liveDevice!.serial}'
                          : 'Connect via USB cable. Trust this computer on your device if prompted.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          detected
              ? 'Your device was detected over USB. The toolkit will read its identifiers — no changes are made to your phone.'
              : 'Waiting for a USB connection. The app scans automatically every few seconds.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}

class _DetectStep extends StatelessWidget {
  const _DetectStep({required this.device, required this.isBusy});

  final DeviceInfo? device;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    if (isBusy || device == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InfoLabel(label: 'Scanning device'),
          const SizedBox(height: 16),
          const GlowCard(
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                ),
                SizedBox(width: 16),
                Text(
                  'Identifying device profile…',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoLabel(label: 'Device identified'),
        const SizedBox(height: 16),
        _InfoRow(label: 'Model', value: device!.model),
        const SizedBox(height: 10),
        _InfoRow(label: 'Manufacturer', value: device!.manufacturer),
        const SizedBox(height: 10),
        _InfoRow(label: device!.imeiLabel, value: device!.displayIdentifier, highlight: true),
        const SizedBox(height: 10),
        _InfoRow(label: 'Serial', value: device!.serial),
        if (device!.osVersion != null) ...[
          const SizedBox(height: 10),
          _InfoRow(label: 'OS', value: device!.osVersion!),
        ],
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentDim.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: AppColors.accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Device ready. Press Start process to begin.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              color: highlight ? AppColors.accent : AppColors.textPrimary,
              fontFamily: highlight ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({
    required this.message,
    required this.detail,
    required this.log,
    required this.step,
    required this.total,
  });

  final String message;
  final String? detail;
  final List<String> log;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeStep = step.clamp(0, safeTotal);
    final progress = safeStep / safeTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InfoLabel(label: 'Engine processing'),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Step $safeStep of $safeTotal · ~${((safeTotal - safeStep) * 10 / 60).ceil()} min remaining',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontFamily: 'monospace',
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (detail != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            detail!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (log.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 100),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: log.reversed.take(5).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '✓ $entry',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Do not disconnect your device. The engine is handling all operations automatically.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.tool, required this.device});

  final UnlockToolType tool;
  final DeviceInfo device;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.accentDim.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Process completed successfully.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${tool.title} has been applied to ${device.model} (${device.imeiLabel} ${device.displayIdentifier}).',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 12),
        const Text(
          'You may safely disconnect your device.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _DevicePreviewPanel extends StatelessWidget {
  const _DevicePreviewPanel({
    required this.step,
    required this.device,
    required this.specs,
    required this.tool,
    required this.processStep,
    required this.totalProcessSteps,
    required this.currentMessage,
    required this.currentDetail,
    required this.hasActiveLink,
  });

  final UnlockFlowStep step;
  final DeviceInfo? device;
  final PhoneSpecs? specs;
  final UnlockToolType tool;
  final int processStep;
  final int totalProcessSteps;
  final String currentMessage;
  final String? currentDetail;
  final bool hasActiveLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          GlowCard(
            padding: const EdgeInsets.all(24),
            child: DevicePreviewCard(
              device: device,
              specs: specs,
              statusLabel: _statusLabel,
              statusColor: _statusColor,
              showManufacturer: false,
            ),
          ),
          if (step == UnlockFlowStep.connect) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                hasActiveLink
                    ? 'USB device connected'
                    : 'Waiting for USB connection…',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
              ),
            ),
          ],
          if (step == UnlockFlowStep.process && currentMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              currentMessage,
              style: const TextStyle(fontSize: 11, color: AppColors.accent, fontFamily: 'monospace'),
            ),
            if (currentDetail != null) ...[
              const SizedBox(height: 4),
              Text(
                currentDetail!,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Text(
            _helpText,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  String get _statusLabel => switch (step) {
        UnlockFlowStep.connect when hasActiveLink => 'Connected',
        UnlockFlowStep.connect => 'Awaiting connection',
        UnlockFlowStep.detect => 'Identifying…',
        UnlockFlowStep.process => 'Processing',
        UnlockFlowStep.done => 'Complete',
      };

  Color get _statusColor => switch (step) {
        UnlockFlowStep.connect when !hasActiveLink => AppColors.textMuted,
        UnlockFlowStep.done => AppColors.success,
        _ => AppColors.accent,
      };

  String get _helpText => switch (step) {
        UnlockFlowStep.connect =>
          'Connect your device with a USB cable. The toolkit will handle detection automatically.',
        UnlockFlowStep.detect =>
          'Reading device identifiers and validating compatibility with ${tool.shortTitle}.',
        UnlockFlowStep.process =>
          'Engine is running step $processStep of $totalProcessSteps. Please wait.',
        UnlockFlowStep.done =>
          'All steps completed. Your device preview reflects the successful operation.',
      };
}
