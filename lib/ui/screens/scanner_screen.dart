import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as scanner;

import '../../services/barcode_scan_service.dart';

class ScanResult {
  const ScanResult({required this.value, required this.format});

  final String value;
  final String format;
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final scanner.MobileScannerController controller =
      scanner.MobileScannerController(
        detectionSpeed: scanner.DetectionSpeed.normal,
        detectionTimeoutMs: 250,
        autoZoom: false,
        formats: const [
          scanner.BarcodeFormat.code128,
          scanner.BarcodeFormat.code39,
          scanner.BarcodeFormat.code93,
          scanner.BarcodeFormat.codabar,
          scanner.BarcodeFormat.dataMatrix,
          scanner.BarcodeFormat.ean13,
          scanner.BarcodeFormat.ean8,
          scanner.BarcodeFormat.itf2of5,
          scanner.BarcodeFormat.itf2of5WithChecksum,
          scanner.BarcodeFormat.itf14,
          scanner.BarcodeFormat.qrCode,
          scanner.BarcodeFormat.microQrCode,
          scanner.BarcodeFormat.upcA,
          scanner.BarcodeFormat.upcE,
          scanner.BarcodeFormat.pdf417,
          scanner.BarcodeFormat.aztec,
        ],
      );
  bool found = false;
  String? candidateKey;
  int confirmationCount = 0;
  DateTime? candidateStartedAt;
  String scanStatus = 'Le scan se fait automatiquement';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(scanner.BarcodeCapture capture) async {
    if (found || capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first;
    final value = barcode.rawValue;
    if (value == null) return;
    final validated = BarcodeScanService.validate(
      rawValue: value,
      rawFormat: barcode.format.name,
    );
    if (validated == null) {
      if (mounted) {
        setState(() {
          candidateKey = null;
          confirmationCount = 0;
          candidateStartedAt = null;
          scanStatus = 'Lecture incertaine, maintenez la carte bien droite';
        });
      }
      return;
    }

    final key = '${validated.format}|${validated.value}';
    if (candidateKey == key) {
      confirmationCount++;
    } else {
      candidateKey = key;
      confirmationCount = 1;
      candidateStartedAt = DateTime.now();
    }
    final requiredConfirmations = BarcodeScanService.requiredConfirmations(
      validated.format,
    );
    final stableFor = DateTime.now().difference(candidateStartedAt!);
    final requiredDuration = BarcodeScanService.requiredStableDuration(
      validated.format,
    );
    if (confirmationCount < requiredConfirmations ||
        stableFor < requiredDuration) {
      if (mounted) {
        setState(() {
          final displayedCount = confirmationCount.clamp(
            1,
            requiredConfirmations,
          );
          scanStatus =
              '${validated.formatLabel} détecté · stabilisation '
              '$displayedCount/$requiredConfirmations';
        });
      }
      return;
    }

    found = true;
    await controller.stop();
    if (!mounted) return;
    Navigator.pop(
      context,
      ScanResult(value: validated.value, format: validated.format),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final scanWidth = (size.width - 48).clamp(220.0, 310.0);
          final scanWindow = Rect.fromCenter(
            center: size.center(Offset.zero),
            width: scanWidth,
            height: scanWidth * .52,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              scanner.MobileScanner(
                controller: controller,
                onDetect: _onDetect,
                scanWindow: scanWindow,
                scanWindowUpdateThreshold: 1,
                tapToFocus: true,
                errorBuilder: (context, error) => _CameraError(
                  message:
                      error.errorDetails?.message ??
                      'La caméra est indisponible sur cet appareil.',
                ),
              ),
              _ScannerOverlay(scanWindow: scanWindow),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _RoundButton(
                            tooltip: 'Fermer',
                            icon: Icons.close_rounded,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          _RoundButton(
                            tooltip: 'Lampe',
                            icon: Icons.flashlight_on_rounded,
                            onPressed: controller.toggleTorch,
                          ),
                          const SizedBox(width: 10),
                          _RoundButton(
                            tooltip: 'Changer de caméra',
                            icon: Icons.cameraswitch_rounded,
                            onPressed: controller.switchCamera,
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Centrez le code et restez immobile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        scanStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .72),
                        ),
                      ),
                      const SizedBox(height: 54),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({required this.scanWindow});

  final Rect scanWindow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                backgroundBlendMode: BlendMode.dstOut,
              ),
            ),
            Positioned.fromRect(
              rect: scanWindow,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: .48),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF17151F),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 50,
              ),
              const SizedBox(height: 18),
              const Text(
                'Impossible d’ouvrir la caméra',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
