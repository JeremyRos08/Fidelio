import 'package:barcode_widget/barcode_widget.dart' as barcode_widget;
import 'package:flutter/material.dart';

import '../../models/loyalty_models.dart';
import '../../theme/app_theme.dart';

class CardCodeWidget extends StatelessWidget {
  const CardCodeWidget({super.key, required this.card, this.height = 170});

  final StoreLoyaltyCard card;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isMatrix = _isMatrix(card.codeFormat);
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMatrix ? 28 : 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E5ED)),
      ),
      child: barcode_widget.BarcodeWidget(
        barcode: _barcode(card.codeFormat),
        data: card.cardNumber,
        drawText: !isMatrix,
        color: AppTheme.ink,
        backgroundColor: Colors.white,
        errorBuilder: (context, error) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE45F7C)),
            const SizedBox(height: 6),
            const Text(
              'Ce format ne correspond pas au numéro saisi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.ink, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isMatrix(String format) =>
      const ['qrCode', 'microQrCode', 'dataMatrix', 'aztec'].contains(format);

  static barcode_widget.Barcode _barcode(String format) {
    return switch (format) {
      'qrCode' || 'microQrCode' => barcode_widget.Barcode.qrCode(),
      'ean13' => barcode_widget.Barcode.ean13(),
      'ean8' => barcode_widget.Barcode.ean8(),
      'upcA' => barcode_widget.Barcode.upcA(),
      'upcE' => barcode_widget.Barcode.upcE(),
      'code39' => barcode_widget.Barcode.code39(),
      'code93' => barcode_widget.Barcode.code93(),
      'codabar' => barcode_widget.Barcode.codabar(),
      'dataMatrix' => barcode_widget.Barcode.dataMatrix(),
      'pdf417' => barcode_widget.Barcode.pdf417(),
      'aztec' => barcode_widget.Barcode.aztec(),
      'itf14' => barcode_widget.Barcode.itf14(),
      'itf2of5' || 'itf2of5WithChecksum' => barcode_widget.Barcode.itf(),
      _ => barcode_widget.Barcode.code128(),
    };
  }
}

class CompactCardCodeWidget extends StatelessWidget {
  const CompactCardCodeWidget({super.key, required this.card});

  final StoreLoyaltyCard card;

  @override
  Widget build(BuildContext context) {
    final isMatrix = CardCodeWidget._isMatrix(card.codeFormat);
    return Semantics(
      label: 'Code scannable de la carte ${card.storeName}',
      image: true,
      child: Container(
        height: 66,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isMatrix ? 7 : 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final codeWidth = isMatrix
                ? 52.0
                : availableWidth.clamp(0, 240).toDouble();
            return Center(
              child: SizedBox(
                key: ValueKey(
                  isMatrix ? 'compact-matrix-code' : 'compact-linear-code',
                ),
                width: codeWidth,
                height: 52,
                child: barcode_widget.BarcodeWidget(
                  barcode: CardCodeWidget._barcode(card.codeFormat),
                  data: card.cardNumber,
                  drawText: false,
                  color: AppTheme.ink,
                  backgroundColor: Colors.white,
                  errorBuilder: (context, error) => Center(
                    child: Text(
                      card.cardNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
