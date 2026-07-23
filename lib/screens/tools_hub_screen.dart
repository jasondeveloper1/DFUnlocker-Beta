import 'package:flutter/material.dart';
import '../models/device_info.dart';
import '../models/phone_specs.dart';
import '../models/unlock_tool.dart';
import '../services/device_connection_controller.dart';
import '../services/phone_specs_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_shell.dart';
import '../widgets/connected_device_preview.dart';
import '../widgets/step_progress_bar.dart';
import 'access_key_screen.dart';
import 'unlock_flow_screen.dart';

class ToolsHubScreen extends StatefulWidget {
  const ToolsHubScreen({super.key});

  @override
  State<ToolsHubScreen> createState() => _ToolsHubScreenState();
}

class _ToolsHubScreenState extends State<ToolsHubScreen> {
  final _deviceConnection = DeviceConnectionController.instance;
  PhoneSpecs? _deviceSpecs;
  String? _specsError;

  @override
  void initState() {
    super.initState();
    _deviceConnection.addListener(_onDeviceChanged);
    _loadSpecsForDevice(_deviceConnection.currentDevice);
  }

  void _onDeviceChanged() {
    if (!mounted) return;
    setState(() {});
    _loadSpecsForDevice(_deviceConnection.currentDevice);
  }

  void _loadSpecsForDevice(DeviceInfo? device) {
    if (device == null) {
      setState(() {
        _deviceSpecs = null;
        _specsError = null;
      });
      return;
    }

    final specs = PhoneSpecsService.instance.resolveSync(device);
    setState(() {
      _deviceSpecs = specs;
      _specsError = null;
    });
  }

  @override
  void dispose() {
    _deviceConnection.removeListener(_onDeviceChanged);
    super.dispose();
  }

  void _returnToAccessKey() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AccessKeyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveDevice = _deviceConnection.currentDevice;
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
              const Text(
                'Unlock Tools',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                liveDevice != null
                    ? '${liveDevice.model} connected — select a tool to begin.'
                    : 'Select a tool to begin. Connect your device when prompted.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const StepProgressBar(totalSteps: 3, currentStep: 2),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: UnlockToolType.values.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tool = UnlockToolType.values[index];
                    final enabled = tool.isCompatibleWith(liveDevice);
                    return _ToolCard(
                      tool: tool,
                      enabled: enabled,
                      disabledReason: liveDevice != null && !enabled
                          ? tool.incompatibilityReason(liveDevice)
                          : null,
                      onTap: enabled
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => UnlockFlowScreen(
                                    tool: tool,
                                    initialDevice: liveDevice,
                                    initialSpecs: _deviceSpecs,
                                  ),
                                ),
                              )
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _returnToAccessKey,
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text('Re-enter access key'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        rightChild: Padding(
          padding: const EdgeInsets.all(36),
          child: ConnectedDevicePreview(
            device: liveDevice,
            specs: _deviceSpecs,
            specsError: _specsError,
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  const _ToolCard({
    required this.tool,
    required this.enabled,
    this.disabledReason,
    this.onTap,
  });

  final UnlockToolType tool;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback? onTap;

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final canHover = widget.enabled;

    return MouseRegion(
      onEnter: canHover ? (_) => setState(() => _hovered = true) : null,
      onExit: canHover ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.enabled
                ? (_hovered
                    ? AppColors.surfaceElevated
                    : AppColors.surfaceElevated.withValues(alpha: 0.5))
                : AppColors.surfaceElevated.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.enabled
                  ? (_hovered ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border)
                  : AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? AppColors.accentDim.withValues(alpha: 0.5)
                      : AppColors.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.tool.icon,
                  color: widget.enabled ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tool.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.enabled ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.disabledReason ?? widget.tool.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.enabled ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.enabled ? Icons.arrow_forward_ios_rounded : Icons.block_rounded,
                size: 14,
                color: widget.enabled
                    ? (_hovered ? AppColors.accent : AppColors.textMuted)
                    : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
