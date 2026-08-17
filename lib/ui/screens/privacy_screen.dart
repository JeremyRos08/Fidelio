import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.secondary.withValues(alpha: .9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Row(
                  children: [
                    _HeroIcon(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vos cartes vous appartiennent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Fidelio fonctionne sans compte et conserve vos informations sensibles sur votre appareil.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _PrivacyPoint(
                icon: Icons.phone_android_rounded,
                title: 'Stockage local',
                description:
                    'Le nom du profil, les numéros de carte, notes, couleurs et favoris sont enregistrés uniquement dans Fidelio sur cet appareil.',
              ),
              const _PrivacyPoint(
                icon: Icons.cloud_off_rounded,
                title: 'Aucun compte Fidelio',
                description:
                    'Aucune inscription, aucun profil publicitaire et aucune synchronisation de vos numéros de carte ne sont nécessaires.',
              ),
              const _PrivacyPoint(
                icon: Icons.visibility_off_outlined,
                title: 'Affichage discret',
                description:
                    'Vous pouvez masquer les codes et numéros dans la liste des cartes. Ils ne sont alors visibles qu’après l’ouverture volontaire d’une carte.',
              ),
              const _PrivacyPoint(
                icon: Icons.public_rounded,
                title: 'Connexion Internet limitée',
                description:
                    'Internet sert à charger les enseignes, leurs logos, les pages officielles demandées et les recherches de produits. Les numéros de carte, vos notes et votre profil ne sont jamais envoyés à ces pages.',
              ),
              const _PrivacyPoint(
                icon: Icons.manage_search_rounded,
                title: 'Comparaison de produits',
                description:
                    'Lors d’un scan produit, le code-barres est envoyé aux services ouverts d’identification et de relevés de prix. Lorsque vous choisissez un comparateur ou une boutique, Fidelio lui transmet uniquement la recherche composée du code et, s’ils sont connus, du nom et de la marque.',
              ),
              const _PrivacyPoint(
                icon: Icons.image_search_rounded,
                title: 'Recherche par photo',
                description:
                    'Lorsque vous choisissez une photo ou utilisez l’appareil photo dans Google Lens, l’image est envoyée à Google uniquement après votre action. Fidelio n’en conserve aucune copie.',
              ),
              const _PrivacyPoint(
                icon: Icons.history_rounded,
                title: 'Historique des prix local',
                description:
                    'Les prix, enseignes et dates que vous saisissez dans Comparer sont conservés uniquement sur cet appareil. Fidelio ne les synchronise avec aucun compte.',
              ),
              const _PrivacyPoint(
                icon: Icons.language_rounded,
                title: 'Pages officielles des enseignes',
                description:
                    'Le bouton d’accès aux offres affiche le site associé à l’enseigne dans Fidelio. Si aucune adresse n’est connue, Fidelio en propose une en .fr puis en .com à partir du nom de la carte. Le site ouvert peut utiliser ses propres cookies et afficher son propre formulaire de consentement. Fidelio ne lit pas son contenu et ne lui transmet ni le numéro de la carte, ni les notes, ni le profil.',
              ),
              const _PrivacyPoint(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Caméra',
                description:
                    'La caméra est activée uniquement lorsque vous ouvrez un scanner ou choisissez de photographier un produit. Une photo de produit n’est envoyée qu’après votre confirmation et Fidelio n’en conserve aucune copie.',
              ),
              const _PrivacyPoint(
                icon: Icons.backup_outlined,
                title: 'Sauvegarde sous votre contrôle',
                description:
                    'Le fichier exporté contient les cartes et les notes. Il quitte Fidelio uniquement lorsque vous choisissez de le partager : conservez-le dans un endroit sûr.',
              ),
              const _PrivacyPoint(
                icon: Icons.delete_outline_rounded,
                title: 'Suppression immédiate',
                description:
                    'Une carte peut être supprimée individuellement. La commande « Supprimer toutes les cartes » efface votre portefeuille local.',
              ),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Cette page décrit le fonctionnement actuel de Fidelio. Les fonctionnalités peuvent évoluer dans le futur, mais la confidentialité restera une priorité.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 29),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
