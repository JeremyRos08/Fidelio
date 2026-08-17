import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/loyalty_models.dart';
import '../widgets/card_code_widget.dart';

class CheckoutModeScreen extends StatefulWidget {
  const CheckoutModeScreen({super.key, required this.card});

  final StoreLoyaltyCard card;

  @override
  State<CheckoutModeScreen> createState() => _CheckoutModeScreenState();
}

class _CheckoutModeScreenState extends State<CheckoutModeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final codeHeight = math.min(310.0, constraints.maxHeight * .48);
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              card.storeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF17151E),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Fermer le mode caisse',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_fullscreen_rounded),
                          ),
                        ],
                      ),
                      const Spacer(),
                      CardCodeWidget(card: card, height: codeHeight),
                      const SizedBox(height: 20),
                      SelectableText(
                        card.cardNumber,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF17151E),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: card.cardNumber),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Numéro de carte copié.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copier le numéro'),
                      ),
                      const Spacer(),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.light_mode_outlined,
                            color: Color(0xFF68636F),
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Écran clair et code agrandi pour faciliter le passage en caisse',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF68636F),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
