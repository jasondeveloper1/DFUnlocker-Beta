import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../models/phone_specs.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';
import 'device_phone_image.dart';

class ConnectedDevicePreview extends StatelessWidget {
  const ConnectedDevicePreview({
    super.key,
    required this.device,
    this.specs,
    this.specsError,
  });

  final DeviceInfo? device;
  final PhoneSpecs? specs;
  final String? specsError;

  bool get _connected => device != null;

  @override
  Widget build(BuildContext context) {
    if (!_connected) {
      return _emptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            children: [
              _deviceHeader(),
              const SizedBox(height: 14),
              if (specs != null)
                _specsSummary(specs!)
              else
                _basicSpecsFallback(),
              if (specsError != null) ...[
                const SizedBox(height: 10),
                Text(
                  specsError!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        GlowCard(
          padding: const EdgeInsets.all(24),
          child: DevicePreviewCard(
            device: null,
            specs: null,
            statusLabel: 'Awaiting connection',
            statusColor: AppColors.textMuted,
            imageSize: 120,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Waiting for USB connection…',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Plug your phone via USB. Device photo and specs will appear here.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
      ],
    );
  }

  Widget _deviceHeader() {
    return GlowCard(
      padding: const EdgeInsets.all(20),
      child: DevicePreviewCard(
        device: device,
        specs: specs,
        statusLabel: 'Connected',
        statusColor: AppColors.accent,
        showOsVersion: true,
      ),
    );
  }

  Widget _specsSummary(PhoneSpecs specs) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          ...specs.highlightSpecs.take(6).map(
            (item) => _specRow(item.key, item.value),
          ),
          if (specs.specifications.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 4),
                iconColor: AppColors.textMuted,
                collapsedIconColor: AppColors.textMuted,
                title: const Text(
                  'All specifications',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                children: specs.specifications.entries.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.key,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...category.value.entries.map(
                          (spec) => _specRow(spec.key, _stripHtml(spec.value)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _basicSpecsFallback() {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device info',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _specRow('Model', device!.model),
          _specRow('Manufacturer', device!.manufacturer),
          if (device!.osVersion != null) _specRow('OS', device!.osVersion!),
          _specRow('Connection', device!.connectionType),
          _specRow(device!.imeiLabel, device!.displayIdentifier),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}
