import 'package:flutter/material.dart';

import '../models/device_info.dart';
import '../models/phone_specs.dart';
import '../theme/app_theme.dart';

/// Product-style phone render on a light backdrop so device photos stay visible
/// on the dark app chrome.
class DevicePhoneImage extends StatelessWidget {
  const DevicePhoneImage({
    super.key,
    this.device,
    this.specs,
    this.size = 140,
  });

  final DeviceInfo? device;
  final PhoneSpecs? specs;
  final double size;

  bool get _hasDevice => device != null;

  @override
  Widget build(BuildContext context) {
    final frameHeight = size * 1.12;

    return Container(
      width: size,
      height: frameHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deviceImageBackdrop,
            AppColors.deviceImageBackdropEnd,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
          if (_hasDevice)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.12),
              blurRadius: 28,
              spreadRadius: -6,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: frameHeight * 0.42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.65),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.08,
                  vertical: size * 0.1,
                ),
                child: _buildImageContent(),
              ),
            ),
            if (_hasDevice)
              Positioned(
                bottom: size * 0.06,
                left: size * 0.22,
                right: size * 0.22,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final assetImage = specs?.assetImage;
    if (assetImage != null) {
      return Image.asset(
        assetImage,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _placeholderIcon(),
      );
    }

    final imageUrl = specs?.resolvedImageUrl;
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _placeholderIcon(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size * 0.35,
            height: size * 0.35,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          );
        },
      );
    }

    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    final connected = _hasDevice;
    final iconSize = size * (connected ? 0.38 : 0.34);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.smartphone_rounded,
          size: iconSize,
          color: connected
              ? const Color(0xFF3A3A42)
              : const Color(0xFF9A9AA8),
        ),
        if (!connected) ...[
          SizedBox(height: size * 0.04),
          Container(
            width: size * 0.28,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFC8CAD2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Shared device summary card used on the tools hub and unlock flow panels.
class DevicePreviewCard extends StatelessWidget {
  const DevicePreviewCard({
    super.key,
    required this.device,
    this.specs,
    required this.statusLabel,
    required this.statusColor,
    this.imageSize = 140,
    this.showManufacturer = true,
    this.showOsVersion = false,
  });

  final DeviceInfo? device;
  final PhoneSpecs? specs;
  final String statusLabel;
  final Color statusColor;
  final double imageSize;
  final bool showManufacturer;
  final bool showOsVersion;

  bool get _connected => device != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DevicePhoneImage(
          device: device,
          specs: specs,
          size: imageSize,
        ),
        SizedBox(height: imageSize * 0.12),
        Text(
          _connected ? (specs?.displayName ?? device!.model) : 'No device',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (_connected && showManufacturer && device!.manufacturer.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            device!.manufacturer,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        if (_connected) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.usb_rounded,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  device!.displayIdentifier,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          if (showOsVersion && device!.osVersion != null) ...[
            const SizedBox(height: 6),
            Text(
              device!.osVersion!,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
        const SizedBox(height: 16),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        DeviceStatusBadge(label: statusLabel, color: statusColor),
      ],
    );
  }
}

class DeviceStatusBadge extends StatelessWidget {
  const DeviceStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}
