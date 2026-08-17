import 'package:flutter/material.dart';

import '../../models/loyalty_models.dart';
import '../../services/barcode_scan_service.dart';
import '../../services/brand_directory_service.dart';
import '../../state/loyalty_controller.dart';
import '../screens/brand_picker_screen.dart';
import '../screens/scanner_screen.dart';

const walletCardColorChoices = <WalletCardColorChoice>[
  WalletCardColorChoice('Violet', Color(0xFF5B46E8)),
  WalletCardColorChoice('Indigo', Color(0xFF3949AB)),
  WalletCardColorChoice('Bleu royal', Color(0xFF1565C0)),
  WalletCardColorChoice('Bleu nuit', Color(0xFF173F5F)),
  WalletCardColorChoice('Turquoise', Color(0xFF007F86)),
  WalletCardColorChoice('Émeraude', Color(0xFF087F5B)),
  WalletCardColorChoice('Vert', Color(0xFF198754)),
  WalletCardColorChoice('Vert sapin', Color(0xFF2E6B3C)),
  WalletCardColorChoice('Olive', Color(0xFF667A2E)),
  WalletCardColorChoice('Orange', Color(0xFFD96424)),
  WalletCardColorChoice('Terracotta', Color(0xFFB8543E)),
  WalletCardColorChoice('Rouge', Color(0xFFC43D4F)),
  WalletCardColorChoice('Framboise', Color(0xFFC43F70)),
  WalletCardColorChoice('Rose', Color(0xFFE45F7C)),
  WalletCardColorChoice('Prune', Color(0xFF7B3F8C)),
  WalletCardColorChoice('Marron', Color(0xFF795548)),
  WalletCardColorChoice('Ardoise', Color(0xFF455A64)),
  WalletCardColorChoice('Anthracite', Color(0xFF26223E)),
];

class WalletCardColorChoice {
  const WalletCardColorChoice(this.label, this.color);

  final String label;
  final Color color;
}

Future<void> showCardEditor(
  BuildContext context, {
  required LoyaltyController controller,
  StoreLoyaltyCard? card,
  String? scannedValue,
  String? scannedFormat,
  String? suggestedStoreName,
}) async {
  final formKey = GlobalKey<FormState>();
  final storeController = TextEditingController(
    text: card?.storeName ?? suggestedStoreName,
  );
  final numberController = TextEditingController(
    text: card?.cardNumber ?? scannedValue,
  );
  final notesController = TextEditingController(text: card?.notes);
  var selectedColor = card?.color ?? Theme.of(context).colorScheme.primary;
  var selectedFormat = card?.codeFormat ?? _supportedFormat(scannedFormat);
  var wasScanned = scannedValue != null;
  var proposedStoreName = suggestedStoreName;

  Future<void> scanCardNumber(
    BuildContext scanContext,
    StateSetter setSheetState,
  ) async {
    final result = await Navigator.push<ScanResult>(
      scanContext,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result == null || !scanContext.mounted) return;
    final detectedStore = BrandDirectoryService.detectBrand(
      result.value,
      controller.cards,
    );
    setSheetState(() {
      numberController.text = result.value;
      selectedFormat = _supportedFormat(result.format);
      wasScanned = true;
      proposedStoreName = detectedStore;
      if (storeController.text.trim().isEmpty && detectedStore != null) {
        storeController.text = detectedStore;
      }
    });
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          12,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    card == null ? 'Nouvelle carte' : 'Modifier la carte',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (wasScanned) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF15906F),
                          size: 19,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${BarcodeScanService.formatLabel(selectedFormat)} détecté et vérifié',
                          style: const TextStyle(
                            color: Color(0xFF15906F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (proposedStoreName != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15906F).withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF15906F),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enseigne proposée : $proposedStoreName',
                              style: const TextStyle(
                                color: Color(0xFF15906F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: storeController,
                    autofocus: scannedValue != null,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l’enseigne',
                      hintText: 'Ex. Ma pharmacie',
                      prefixIcon: Icon(Icons.storefront_outlined),
                      helperText:
                          'Saisissez un nom ou choisissez dans la liste',
                      border: OutlineInputBorder(),
                    ),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Indiquez le nom de l’enseigne'
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BrandPickerScreen(
                              initialQuery: storeController.text,
                            ),
                          ),
                        );
                        if (selected != null) storeController.text = selected;
                      },
                      icon: const Icon(Icons.list_alt_rounded),
                      label: const Text('Choisir une enseigne'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: numberController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Numéro ou contenu du code',
                      helperText: 'Saisissez le numéro ou scannez la carte',
                      prefixIcon: const Icon(Icons.numbers_rounded),
                      suffixIcon: IconButton(
                        tooltip: 'Scanner le numéro',
                        onPressed: () => scanCardNumber(context, setSheetState),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Saisissez au moins 3 caractères';
                      }
                      if (controller.containsCard(
                        storeController.text,
                        value,
                        exceptId: card?.id,
                      )) {
                        return 'Cette carte existe déjà';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFormat,
                    decoration: const InputDecoration(
                      labelText: 'Type de code',
                      prefixIcon: Icon(Icons.qr_code_2_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: BarcodeScanService.supportedFormats
                        .map(
                          (format) => DropdownMenuItem(
                            value: format,
                            child: Text(BarcodeScanService.formatLabel(format)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedFormat = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (facultatif)',
                      hintText: 'Ex. Carte de Jérémy',
                      prefixIcon: Icon(Icons.notes_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Couleur de la carte',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        _walletColorLabel(selectedColor),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: walletCardColorChoices.map((choice) {
                      final selected = selectedColor == choice.color;
                      return Tooltip(
                        message: choice.label,
                        child: Semantics(
                          label: 'Couleur ${choice.label}',
                          selected: selected,
                          button: true,
                          child: InkWell(
                            onTap: () => setSheetState(
                              () => selectedColor = choice.color,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: choice.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        if (card == null) {
                          controller.addCard(
                            storeName: storeController.text,
                            cardNumber: numberController.text,
                            color: selectedColor,
                            codeFormat: selectedFormat,
                            notes: notesController.text,
                          );
                        } else {
                          controller.updateCard(
                            card.copyWith(
                              storeName: storeController.text.trim(),
                              cardNumber: numberController.text.trim(),
                              colorValue: selectedColor.toARGB32(),
                              codeFormat: selectedFormat,
                              notes: notesController.text.trim(),
                            ),
                          );
                        }
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              card == null
                                  ? 'Carte enregistrée sur cet appareil.'
                                  : 'Carte mise à jour.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        card == null ? 'Enregistrer la carte' : 'Enregistrer',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

String _supportedFormat(String? format) {
  return BarcodeScanService.supportedFormat(format) ?? 'code128';
}

String _walletColorLabel(Color color) {
  for (final choice in walletCardColorChoices) {
    if (choice.color == color) return choice.label;
  }
  return 'Personnalisée';
}
