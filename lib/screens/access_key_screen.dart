import 'package:flutter/material.dart';
import '../core/runtime_config.dart';
import '../constants/app_branding.dart';
import '../services/license_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_shell.dart';
import '../widgets/step_progress_bar.dart';
import 'tools_hub_screen.dart';

class AccessKeyScreen extends StatefulWidget {
  const AccessKeyScreen({super.key});

  @override
  State<AccessKeyScreen> createState() => _AccessKeyScreenState();
}

class _AccessKeyScreenState extends State<AccessKeyScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _isVerifying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final key = _controller.text;
    if (key.trim().isEmpty) {
      setState(() => _error = 'Please enter your access key.');
      return;
    }

    if (key.length > LicenseService.maxKeyLength) {
      setState(() => _error = 'Access key is too long.');
      return;
    }

    setState(() {
      _error = null;
      _isVerifying = true;
    });

    await Future<void>.delayed(RuntimeConfig.licenseVerificationDelay);

    if (!mounted) return;

    switch (LicenseService.verify(key)) {
      case LicenseStatus.valid:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const ToolsHubScreen()),
        );
      case LicenseStatus.malformed:
        setState(() {
          _isVerifying = false;
          _error = 'Enter a license key with at least 8 characters.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppShell(
        leftChild: Padding(
          padding: const EdgeInsets.fromLTRB(40, 36, 32, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: AppLogo(size: 32)),
              const SizedBox(height: 28),
              const Text(
                'Access Key',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const StepProgressBar(totalSteps: 3, currentStep: 1),
              const SizedBox(height: 32),
              const InfoLabel(label: 'Enter access key'),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                obscureText: true,
                maxLength: LicenseService.maxKeyLength,
                enabled: !_isVerifying,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Your license key',
                  counterText: '',
                ),
                onSubmitted: _isVerifying ? null : (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Enter tool',
                isLoading: _isVerifying,
                onPressed: _verify,
              ),
            ],
          ),
        ),
        rightChild: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              GlowCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.vpn_key_rounded, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppBranding.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: AppColors.accent),
                                SizedBox(width: 4),
                                Text(
                                  'Licensed tool',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 12),
                    _previewLine(width: 120),
                    const SizedBox(height: 8),
                    _previewLine(width: 80),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter your license key to access the unlocking toolkit. '
                'All operations are handled automatically by the engine.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewLine({required double width}) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
