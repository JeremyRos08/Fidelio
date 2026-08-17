import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../theme/app_theme.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _iconAsset = 'assets/icon/fidelio_app_icon_v2.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos de Fidelio')),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(_iconAsset, width: 92, height: 92),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fidelio',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Toutes vos cartes de fidélité, simplement.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final info = snapshot.data;
                          final displayVersion = info?.version == '1.0.0'
                              ? '1.0'
                              : info?.version;
                          final value = info == null
                              ? 'Version…'
                              : 'Version $displayVersion (${info.buildNumber})';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              value,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Fidelio, c’est quoi ?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Fidelio remplace votre collection de cartes physiques par un portefeuille organisé en grille. Ajoutez une carte en la scannant ou manuellement, affichez son code en caisse, recherchez un produit par code-barres ou par photo et consultez les relevés de prix disponibles.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pourquoi Fidelio ?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.offline_bolt_rounded,
                        title: 'Toujours disponible',
                        subtitle:
                            'Vos cartes restent accessibles hors connexion.',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.person_off_rounded,
                        title: 'Sans compte',
                        subtitle:
                            'Aucune inscription pour utiliser votre portefeuille.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Informations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const _AboutIcon(Icons.help_outline_rounded),
                        title: const Text('Aide et mode d’emploi'),
                        subtitle: const Text(
                          'Cartes, scanner et comparaison de produits',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        ),
                      ),
                      const Divider(height: 1, indent: 68),
                      ListTile(
                        leading: const _AboutIcon(Icons.privacy_tip_outlined),
                        title: const Text('Confidentialité'),
                        subtitle: const Text(
                          'Comment Fidelio utilise vos données',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Questions fréquentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Card(
                  child: Column(
                    children: [
                      _FaqItem(
                        question: 'Comment comparer un produit ?',
                        answer:
                            'Ouvrez l’onglet Comparer et scannez le code EAN ou UPC. Fidelio tente d’identifier le produit et affiche jusqu’à trois relevés de prix avec leur enseigne, leur ville et leur date. Vous pouvez ensuite choisir un comparateur ou une boutique. La saisie manuelle accepte aussi les références courtes comme 45888 et les références contenant des lettres.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Comment rechercher avec une photo ?',
                        answer:
                            'Dans l’onglet Comparer, touchez « Rechercher avec une photo », puis prenez une photo ou choisissez-en une dans la galerie. Google Lens affiche les résultats dans Fidelio. L’image est envoyée à Google après votre choix et Fidelio n’en conserve pas de copie.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question:
                            'Quelle différence entre Google Web et Google Shopping ?',
                        answer:
                            'Google Web effectue une recherche classique plus large avec le nom, la marque principale et le code-barres. Google Shopping se limite davantage aux produits transmis par les marchands. Essayez Google Web lorsqu’un produit précis est absent de Shopping.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Comment fonctionne la recherche Idealo ?',
                        answer:
                            'Fidelio ouvre directement la page de résultats Idealo dans sa WebView. La recherche utilise le nom, la marque principale et le code du produit lorsqu’ils sont disponibles. La page et ses résultats restent entièrement fournis par Idealo.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question:
                            'Pourquoi certains produits n’ont pas de nom ?',
                        answer:
                            'L’identification automatique utilise une base ouverte principalement alimentaire. Si le produit est absent, Fidelio conserve son code et permet quand même de le rechercher chez les comparateurs et commerçants.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Les prix affichés sont-ils garantis ?',
                        answer:
                            'Non. Après un scan, Fidelio peut afficher des relevés collaboratifs avec leur enseigne, leur ville et leur date. Ils ne représentent pas forcément le tarif actuel de votre magasin. Les prix des sites ouverts dans la WebView peuvent également changer : vérifiez toujours le prix final avant un achat.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Pourquoi aucun prix n’est-il affiché ?',
                        answer:
                            'Tous les codes-barres ne possèdent pas encore de relevé public. Fidelio affiche uniquement les prix disponibles avec une enseigne et une date fiables. Vous pouvez utiliser « Enregistrer le prix vu » pour conserver votre propre relevé sur le téléphone.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Où sont conservés les prix que je note ?',
                        answer:
                            'L’historique des prix constatés est enregistré uniquement sur votre appareil. Il permet de retrouver le produit, l’enseigne, le prix et la date.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Comment ajouter une carte ?',
                        answer:
                            'Depuis l’onglet Cartes, utilisez Scanner pour lire son code ou Manuel pour saisir les informations vous-même.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question:
                            'Mes cartes fonctionnent-elles hors connexion ?',
                        answer:
                            'Oui. Les cartes et leurs codes restent disponibles sans Internet. Les logos déjà chargés sont également conservés sur l’appareil.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Comment retrouver rapidement une carte ?',
                        answer:
                            'Les cartes sont organisées automatiquement en grille, avec deux cartes par ligne sur mobile. Utilisez la recherche par enseigne, numéro ou note, placez vos cartes importantes en favoris ou choisissez le tri « Utilisées récemment ».',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'À quoi sert le mode caisse ?',
                        answer:
                            'Il affiche le code en grand sur un fond clair pour faciliter sa lecture en caisse. Ouvrez une carte puis choisissez « Afficher en grand », ou maintenez directement la carte appuyée dans le portefeuille.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Puis-je masquer les codes dans la liste ?',
                        answer:
                            'Oui. Activez « Masquer les codes dans la liste » dans Réglages. Le code complet restera disponible après ouverture de la carte.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Où voir les offres de mon enseigne ?',
                        answer:
                            'Ouvrez une carte enregistrée. Fidelio ouvre directement la page des promotions lorsqu’elle est connue. Si cette page a changé ou ne répond plus, utilisez « Ouvrir le site de l’enseigne ». Pour les autres cartes, Fidelio ouvre le site associé ou recherche une adresse en .fr puis en .com à partir du nom. Aucune offre n’est copiée ni stockée par l’application.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Pourquoi un site demande-t-il des cookies ?',
                        answer:
                            'Les pages des enseignes et comparateurs restent fournies par leurs propriétaires et peuvent afficher leur propre choix de cookies. Les boutons placés en bas sont conservés au-dessus de la barre système pour rester accessibles. Fidelio ne transmet jamais votre numéro de carte à ces pages.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Que faire si le scanner lit mal le code ?',
                        answer:
                            'Gardez le code stable et bien éclairé dans le cadre. Vous pouvez toujours corriger ou saisir le numéro manuellement.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question: 'Puis-je personnaliser l’apparence ?',
                        answer:
                            'Oui. Dans Réglages, choisissez la couleur de l’interface, la taille du texte et le mode clair ou sombre. Vos choix sont mémorisés.',
                      ),
                      Divider(height: 1, indent: 18, endIndent: 18),
                      _FaqItem(
                        question:
                            'Puis-je transférer mes cartes sur un autre téléphone ?',
                        answer:
                            'Oui. Dans Réglages, utilisez « Exporter mes cartes », conservez le fichier en lieu sûr, puis choisissez « Importer une sauvegarde » sur le nouvel appareil. Aucun compte n’est nécessaire.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Rossignol Jérémy © 2026 Fidelio.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutIcon(icon),
            const SizedBox(height: 13),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      iconColor: AppTheme.primary,
      collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(answer, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _AboutIcon extends StatelessWidget {
  const _AboutIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 22),
    );
  }
}
