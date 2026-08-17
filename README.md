# Fidelio

Fidelio est un portefeuille de cartes de fidélité Flutter pensé pour fonctionner simplement, y compris hors connexion. Les cartes, le profil, les réglages et l’historique des prix saisis restent enregistrés localement sur le téléphone.

Version publique actuelle : **1.0** — build **1** (`1.0.0+1` dans Flutter).

## Fonctions principales

- Ajout d’une carte par scan ou saisie manuelle du numéro.
- Détection et validation des formats de codes-barres courants.
- Choix de l’enseigne, du logo, de la couleur et ajout de notes.
- Affichage des cartes dans une grille adaptative, avec favoris, recherche et tri.
- Mode passage en caisse : code-barres agrandi, luminosité renforcée et aperçu masquable.
- Conservation locale des cartes et des logos pour une utilisation hors connexion.
- Accès au site ou à la page promotionnelle de l’enseigne dans une vue intégrée.
- Scan ou saisie du code-barres d’un produit pour lancer une comparaison.
- Recherche par photo avec confirmation avant l’envoi de l’image.
- Affichage de relevés de prix collaboratifs récents lorsqu’ils sont disponibles.
- Liens de comparaison vers Google, Idealo, Amazon et Cdiscount.
- Historique local des prix observés par l’utilisateur.
- Profil local avec photo, nom, prénom et adresse e-mail.
- Export et import d’une sauvegarde des cartes.
- Réglages de thème, couleurs, taille du texte et confort d’affichage.
- Pages intégrées d’aide, FAQ, confidentialité et à propos.

## Confidentialité

Fidelio ne possède pas de compte en ligne ni de serveur applicatif. Les numéros de cartes de fidélité, les notes et le profil ne sont pas transmis aux enseignes ni aux comparateurs.

Une connexion est utilisée uniquement pour les fonctions demandées par l’utilisateur : téléchargement initial d’un logo, ouverture d’un site, recherche d’un produit, consultation de relevés de prix ou recherche par photo. Le code produit peut alors être envoyé aux services de recherche concernés. Une photo n’est envoyée à Google Lens qu’après confirmation explicite.

Les détails complets figurent dans [PRIVACY_POLICY.md](PRIVACY_POLICY.md) et dans la page **Confidentialité** de l’application.

## Développement

Prérequis : Flutter stable, Android Studio et un SDK Android configuré.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Pour produire les fichiers de publication sous Windows :

```powershell
.\build_release.ps1
```

Le script compile depuis un chemin temporaire sans accent afin d’éviter l’erreur AOT rencontrée avec certains chemins Windows. Les fichiers générés sont ensuite copiés dans les emplacements Flutter d’origine :

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

Pour construire uniquement un APK :

```powershell
flutter build apk --release
```

## Publication

La liste des vérifications avant envoi sur Google Play se trouve dans [PLAY_STORE_CHECKLIST.md](PLAY_STORE_CHECKLIST.md). Les changements récents sont résumés dans [CHANGELOG.md](CHANGELOG.md).
