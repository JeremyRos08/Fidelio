class ValidatedBarcodeScan {
  const ValidatedBarcodeScan({required this.value, required this.format});

  final String value;
  final String format;

  String get formatLabel => BarcodeScanService.formatLabel(format);
}

class BarcodeScanService {
  BarcodeScanService._();

  static const supportedFormats = <String>[
    'code128',
    'code39',
    'code93',
    'codabar',
    'ean13',
    'ean8',
    'upcA',
    'upcE',
    'itf2of5',
    'itf2of5WithChecksum',
    'itf14',
    'qrCode',
    'microQrCode',
    'dataMatrix',
    'pdf417',
    'aztec',
  ];

  static ValidatedBarcodeScan? validate({
    required String rawValue,
    required String rawFormat,
  }) {
    var value = rawValue.trim();
    final format = supportedFormat(rawFormat);
    if (value.isEmpty || format == null) return null;

    if (_numericFormats.contains(format)) {
      value = value.replaceAll(RegExp(r'[\s-]'), '');
      if (!RegExp(r'^\d+$').hasMatch(value)) return null;
    }

    final valid = switch (format) {
      'ean13' => value.length == 13 && hasValidGtinCheckDigit(value),
      'ean8' => value.length == 8 && hasValidGtinCheckDigit(value),
      'upcA' => value.length == 12 && hasValidGtinCheckDigit(value),
      'upcE' => value.length >= 6 && value.length <= 8,
      'itf14' => value.length == 14 && hasValidGtinCheckDigit(value),
      'itf2of5' || 'itf2of5WithChecksum' => value.length.isEven,
      'code39' => RegExp(r'^[0-9A-Z. $/+%-]+$').hasMatch(value.toUpperCase()),
      _ => true,
    };
    if (!valid) return null;
    if (format == 'code39') value = value.toUpperCase();
    return ValidatedBarcodeScan(value: value, format: format);
  }

  static String? supportedFormat(String? format) {
    if (format == null) return null;
    if (supportedFormats.contains(format)) return format;
    if (format == 'itf') return 'itf14';
    return null;
  }

  static bool isMatrixFormat(String format) => const {
    'qrCode',
    'microQrCode',
    'dataMatrix',
    'pdf417',
    'aztec',
  }.contains(format);

  static int requiredConfirmations(String format) =>
      isMatrixFormat(format) ? 2 : 5;

  static Duration requiredStableDuration(String format) =>
      isMatrixFormat(format)
      ? const Duration(milliseconds: 450)
      : const Duration(milliseconds: 950);

  static String formatLabel(String format) => switch (format) {
    'code128' => 'Code 128',
    'code39' => 'Code 39',
    'code93' => 'Code 93',
    'codabar' => 'Codabar',
    'ean13' => 'EAN-13',
    'ean8' => 'EAN-8',
    'upcA' => 'UPC-A',
    'upcE' => 'UPC-E',
    'itf2of5' => 'ITF',
    'itf2of5WithChecksum' => 'ITF avec contrôle',
    'itf14' => 'ITF-14',
    'qrCode' => 'QR code',
    'microQrCode' => 'Micro QR',
    'dataMatrix' => 'Data Matrix',
    'pdf417' => 'PDF417',
    'aztec' => 'Aztec',
    _ => 'Code-barres',
  };

  static bool hasValidGtinCheckDigit(String value) {
    if (value.length < 2 || !RegExp(r'^\d+$').hasMatch(value)) return false;
    var sum = 0;
    var weight = 3;
    for (var index = value.length - 2; index >= 0; index--) {
      sum += int.parse(value[index]) * weight;
      weight = weight == 3 ? 1 : 3;
    }
    final expected = (10 - (sum % 10)) % 10;
    return expected == int.parse(value[value.length - 1]);
  }

  static const _numericFormats = {
    'ean13',
    'ean8',
    'upcA',
    'upcE',
    'itf2of5',
    'itf2of5WithChecksum',
    'itf14',
  };
}
