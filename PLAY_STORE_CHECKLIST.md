# Publication de Fidelio sur Google Play

## Déjà préparé dans le projet

- Nom public : **Fidelio**
- Identifiant Android : `fr.fidelio.fidelio`
- Version publique : **1.0** — build **1** (`1.0.0+1` dans Flutter)
- Cible Android : API 36
- Icônes classique, adaptative et monochrome
- Caméra déclarée comme fonctionnalité facultative
- Sauvegarde système désactivée pour protéger les cartes locales
- Trafic HTTP non chiffré interdit
- Cartes, profil, réglages et prix saisis conservés localement
- Export et import local des cartes, sans compte Fidelio ni serveur applicatif
- Pages Aide, FAQ, Confidentialité et À propos intégrées
- Vues Web intégrées avec commandes de navigation et zone basse sécurisée pour les bandeaux de cookies

## À faire avant le premier envoi

1. Vérifier définitivement l’identifiant `fr.fidelio.fidelio`. Il ne pourra plus être changé après publication.
2. Créer une clé d’upload `.jks` dans Android Studio.
3. Copier `android/key.properties.example` vers `android/key.properties` et renseigner les quatre valeurs.
4. Construire le bundle avec `flutter build appbundle --release` ou `.\build_release.ps1`.
5. Héberger [PRIVACY_POLICY.md](PRIVACY_POLICY.md) sur une page publique et ajouter son adresse dans Play Console.
6. Compléter le formulaire **Sécurité des données** en décrivant précisément les échanges externes :
   - le code-barres d’un produit est envoyé aux services de recherche de produit et de relevés de prix lors d’une comparaison ;
   - une photo choisie ou prise par l’utilisateur est envoyée à Google Lens uniquement après confirmation ;
   - une requête est envoyée au site ou au comparateur choisi lors de son ouverture ;
   - les cartes de fidélité, leurs notes et le profil restent locaux et ne sont pas envoyés par Fidelio.
7. Vérifier les déclarations d’utilisation de la caméra, de la galerie et d’Internet.
8. Ajouter l’icône Play Store 512 px, une image de présentation 1024 × 500 et des captures d’écran de téléphone.
9. Tester d’abord le bundle sur la piste de test interne.

## Captures d’écran conseillées

- Grille des cartes avec plusieurs couleurs et logos.
- Ajout d’une carte par scan et saisie manuelle.
- Mode passage en caisse avec code-barres agrandi.
- Comparaison d’un produit avec les relevés de prix disponibles.
- Recherche par photo et écran de confirmation.
- Profil et réglages d’apparence.
- Aide, FAQ et confidentialité.

## Vérifications techniques

```powershell
flutter pub get
flutter analyze
flutter test
.\build_release.ps1
```

Après compilation, vérifier le numéro de version, installer l’APK sur un téléphone réel et tester la caméra, la galerie, les WebViews, le fonctionnement hors connexion et l’import/export.

## Fiche Play Store

- Expliquer que Fidelio est un portefeuille local indépendant des enseignes.
- Ne pas promettre que tous les produits disposent d’un prix : les relevés sont collaboratifs et peuvent être absents ou anciens.
- Préciser que les pages d’enseignes, Google Lens et les comparateurs sont fournis par des services tiers.
- Ajouter une adresse de support valide et l’URL publique de la politique de confidentialité.
