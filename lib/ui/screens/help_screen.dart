import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aide et mode d’emploi')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
              children: const [
                _HelpIntro(),
                SizedBox(height: 24),
                _HelpTitle('Mes cartes'),
                SizedBox(height: 10),
                _HelpCard(
                  icon: Icons.add_card_rounded,
                  title: 'Ajouter une carte',
                  steps: [
                    'Ouvrez Cartes puis choisissez Scanner ou Manuel.',
                    'Scannez le code-barres de la carte, ou saisissez son numéro.',
                    'Choisissez l’enseigne, la couleur et enregistrez la carte.',
                  ],
                ),
                SizedBox(height: 10),
                _HelpCard(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Présenter une carte en caisse',
                  steps: [
                    'Touchez une carte pour ouvrir sa fiche.',
                    'Choisissez Afficher en grand pour le mode caisse.',
                    'Augmentez la luminosité si le lecteur a du mal à lire le code.',
                  ],
                ),
                SizedBox(height: 10),
                _HelpCard(
                  icon: Icons.tune_rounded,
                  title: 'Retrouver et organiser vos cartes',
                  steps: [
                    'Les cartes sont rangées automatiquement en grille : deux par ligne sur mobile, puis davantage sur les écrans plus larges.',
                    'Utilisez la recherche, les favoris et le tri par utilisation récente.',
                    'Maintenez une carte appuyée pour l’afficher directement en grand.',
                    'Dans Réglages, vous pouvez masquer les codes dans la liste.',
                  ],
                ),
                SizedBox(height: 24),
                _HelpTitle('Comparer un produit'),
                SizedBox(height: 10),
                _HelpCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scanner et rechercher',
                  steps: [
                    'Ouvrez Comparer puis scannez le code EAN, UPC ou GTIN du produit.',
                    'Avec Saisir, vous pouvez aussi utiliser une référence courte ou alphanumérique qui n’est pas un EAN officiel.',
                    'Fidelio tente d’identifier son nom, sa marque et son image.',
                    'Lorsque des relevés existent, Fidelio affiche leur prix, l’enseigne, la ville et la date. Vérifiez toujours le tarif actuel en magasin.',
                    'Essayez Google Web pour une recherche large, Google Shopping pour les annonces de marchands, ou Idealo pour ouvrir ses suggestions directement dans Fidelio.',
                  ],
                ),
                SizedBox(height: 10),
                _HelpCard(
                  icon: Icons.image_search_rounded,
                  title: 'Rechercher avec une photo',
                  steps: [
                    'Touchez Rechercher avec une photo dans l’onglet Comparer.',
                    'Choisissez de prendre une photo ou une image de la galerie.',
                    'Cadrez surtout le produit, son emballage ou son étiquette pour obtenir de meilleurs résultats.',
                    'Vérifiez l’aperçu puis touchez Envoyer. Google Lens affiche ensuite les images similaires, les sites et les produits qu’il reconnaît.',
                  ],
                ),
                SizedBox(height: 10),
                _HelpCard(
                  icon: Icons.history_rounded,
                  title: 'Noter un prix vu en magasin',
                  steps: [
                    'Après le scan, touchez Enregistrer le prix vu.',
                    'Indiquez l’enseigne et le prix constaté.',
                    'Retrouvez ensuite cette observation dans l’historique local.',
                  ],
                ),
                SizedBox(height: 24),
                _HelpTitle('Sites et pages intégrées'),
                SizedBox(height: 10),
                _HelpCard(
                  icon: Icons.language_rounded,
                  title: 'Naviguer sans quitter Fidelio',
                  steps: [
                    'Les sites des enseignes, comparateurs et résultats de recherche s’ouvrent dans une page intégrée.',
                    'Utilisez les flèches en haut pour revenir en arrière ou avancer, et le bouton Actualiser si la page reste vide.',
                    'Chaque site peut demander d’accepter ou de refuser ses cookies. Les boutons placés en bas restent au-dessus de la barre système du téléphone.',
                    'Fidelio n’envoie jamais le numéro de votre carte de fidélité au site affiché.',
                  ],
                ),
                SizedBox(height: 24),
                _HelpTitle('À savoir'),
                SizedBox(height: 10),
                _NoticeCard(),
                SizedBox(height: 24),
                _HelpTitle('En cas de problème'),
                SizedBox(height: 10),
                _TroubleshootingCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpIntro extends StatelessWidget {
  const _HelpIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Les gestes essentiels pour utiliser Fidelio rapidement et en toute confiance.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTitle extends StatelessWidget {
  const _HelpTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleLarge);
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < steps.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == steps.length - 1 ? 0 : 9,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[index])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NoticeLine(
              icon: Icons.inventory_2_outlined,
              text:
                  'L’identification automatique couvre surtout les produits alimentaires. Un produit inconnu peut quand même être recherché avec son code.',
            ),
            SizedBox(height: 14),
            _NoticeLine(
              icon: Icons.price_check_outlined,
              text:
                  'Les prix automatiques sont des relevés collaboratifs datés. Les prix, vendeurs, stocks et frais des sites externes peuvent aussi varier et ne sont pas garantis.',
            ),
            SizedBox(height: 14),
            _NoticeLine(
              icon: Icons.phonelink_lock_outlined,
              text:
                  'Vos cartes et les prix que vous notez sont conservés localement sur votre appareil.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeLine extends StatelessWidget {
  const _NoticeLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppTheme.primary, size: 22),
      const SizedBox(width: 11),
      Expanded(child: Text(text)),
    ],
  );
}

class _TroubleshootingCard extends StatelessWidget {
  const _TroubleshootingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          ExpansionTile(
            title: Text('Le scanner ne reconnaît pas le code'),
            childrenPadding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Text(
                'Placez tout le code dans le cadre, évitez les reflets, gardez le téléphone stable et vérifiez que l’objectif est propre. La saisie manuelle reste disponible.',
              ),
            ],
          ),
          Divider(height: 1, indent: 18, endIndent: 18),
          ExpansionTile(
            title: Text('Une recherche ne s’affiche pas'),
            childrenPadding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Text(
                'Vérifiez la connexion Internet, actualisez la page puis réessayez. Certains sites peuvent modifier leur page, demander des cookies ou bloquer temporairement une vue intégrée. Les boutons de cookies sont accessibles au-dessus de la barre système.',
              ),
            ],
          ),
          Divider(height: 1, indent: 18, endIndent: 18),
          ExpansionTile(
            title: Text('Je change de téléphone'),
            childrenPadding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Text(
                'Avant le changement, ouvrez Réglages puis Exporter mes cartes. Importez ensuite le fichier de sauvegarde sur le nouvel appareil.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
