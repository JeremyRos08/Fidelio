import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/card_backup_service.dart';
import '../../state/loyalty_controller.dart';
import '../../theme/app_theme.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.primaryColor,
    required this.textScale,
    required this.onThemeChanged,
    required this.onPrimaryColorChanged,
    required this.onTextScaleChanged,
  });

  final LoyaltyController controller;
  final bool isDarkMode;
  final Color primaryColor;
  final double textScale;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<Color> onPrimaryColorChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              const _SettingsHeader(),
              const SizedBox(height: 22),
              _WalletSummary(controller: controller),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const _SettingsIcon(
                    icon: Icons.account_circle_outlined,
                  ),
                  title: const Text('Profil et compte'),
                  subtitle: Text(
                    controller.profileName.isEmpty
                        ? 'Profil local et futur compte Fidelio'
                        : controller.profileName,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(controller: controller),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              _SectionTitle('Préférences'),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const _SettingsIcon(
                        icon: Icons.visibility_off_outlined,
                      ),
                      title: const Text('Masquer les codes dans la liste'),
                      subtitle: const Text(
                        'Afficher les informations seulement après ouverture',
                      ),
                      value: controller.hideCardPreviews,
                      onChanged: controller.setHideCardPreviews,
                    ),
                    const Divider(height: 1, indent: 68),
                    SwitchListTile(
                      secondary: const _SettingsIcon(
                        icon: Icons.dark_mode_outlined,
                      ),
                      title: const Text('Mode sombre'),
                      subtitle: const Text('Plus confortable dans la pénombre'),
                      value: isDarkMode,
                      onChanged: onThemeChanged,
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      leading: const _SettingsIcon(
                        icon: Icons.palette_outlined,
                      ),
                      title: const Text('Couleur de l’interface'),
                      subtitle: Text(_colorLabel(primaryColor)),
                      trailing: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                      ),
                      onTap: () => _chooseColor(context),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      leading: const _SettingsIcon(
                        icon: Icons.format_size_rounded,
                      ),
                      title: const Text('Taille du texte'),
                      subtitle: Text(_textScaleLabel(textScale)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _chooseTextScale(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _SectionTitle('Données et confidentialité'),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const _SettingsIcon(icon: Icons.shield_outlined),
                      title: const Text('Confidentialité'),
                      subtitle: const Text(
                        'Stockage local et autorisations utilisées',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      leading: const _SettingsIcon(
                        icon: Icons.ios_share_rounded,
                      ),
                      title: const Text('Exporter mes cartes'),
                      subtitle: const Text(
                        'Créer une sauvegarde à conserver ou à transférer',
                      ),
                      enabled: controller.cards.isNotEmpty,
                      onTap: () => _exportCards(context),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      leading: const _SettingsIcon(
                        icon: Icons.settings_backup_restore_rounded,
                      ),
                      title: const Text('Importer une sauvegarde'),
                      subtitle: const Text(
                        'Ajouter des cartes sans remplacer les cartes actuelles',
                      ),
                      onTap: () => _importCards(context),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      leading: const _SettingsIcon(
                        icon: Icons.delete_sweep_outlined,
                        danger: true,
                      ),
                      title: const Text(
                        'Supprimer toutes les cartes',
                        style: TextStyle(color: AppTheme.danger),
                      ),
                      subtitle: const Text(
                        'Effacer le portefeuille de cet appareil',
                      ),
                      enabled: controller.cards.isNotEmpty,
                      onTap: () => _clearCards(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              _SectionTitle('Application'),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const _SettingsIcon(
                        icon: Icons.help_outline_rounded,
                      ),
                      title: const Text('Aide et mode d’emploi'),
                      subtitle: const Text(
                        'Bien utiliser toutes les fonctions',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      leading: const _SettingsIcon(
                        icon: Icons.info_outline_rounded,
                      ),
                      title: const Text('À propos de Fidelio'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
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

  Future<void> _chooseColor(BuildContext context) async {
    final selected = await showModalBottomSheet<Color>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Couleur de l’interface',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            for (final choice in AppTheme.colorChoices)
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: choice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(choice.label),
                trailing: choice.color == primaryColor
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, choice.color),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onPrimaryColorChanged(selected);
  }

  Future<void> _chooseTextScale(BuildContext context) async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Taille du texte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final option in const [
              (label: 'Petite', value: .9, icon: Icons.text_decrease_rounded),
              (label: 'Normale', value: 1.0, icon: Icons.text_fields_rounded),
              (label: 'Grande', value: 1.15, icon: Icons.text_increase_rounded),
            ])
              ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                trailing: option.value == textScale
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, option.value),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onTextScaleChanged(selected);
  }

  String _colorLabel(Color color) =>
      AppTheme.colorChoices
          .where((choice) => choice.color == color)
          .map((choice) => choice.label)
          .firstOrNull ??
      'Personnalisée';

  String _textScaleLabel(double scale) => switch (scale) {
    .9 => 'Petite',
    1.15 => 'Grande',
    _ => 'Normale',
  };

  Future<void> _exportCards(BuildContext context) async {
    try {
      final bytes = CardBackupService.createFile(controller.cards);
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: 'Sauvegarder mes cartes Fidelio',
          subject: 'Sauvegarde Fidelio',
          text: 'Sauvegarde de mes cartes Fidelio',
          files: [XFile.fromData(bytes, mimeType: 'application/json')],
          fileNameOverrides: [CardBackupService.fileName(DateTime.now())],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de créer la sauvegarde pour le moment.'),
        ),
      );
    }
  }

  Future<void> _importCards(BuildContext context) async {
    try {
      const backupType = XTypeGroup(
        label: 'Sauvegarde Fidelio',
        extensions: ['json'],
        mimeTypes: ['application/json'],
        uniformTypeIdentifiers: ['public.json'],
        webWildCards: ['application/json'],
      );
      final file = await openFile(acceptedTypeGroups: const [backupType]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final cards = CardBackupService.readFile(bytes);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.settings_backup_restore_rounded),
          title: const Text('Importer cette sauvegarde ?'),
          content: Text(
            '${cards.length} carte${cards.length > 1 ? 's' : ''} détectée${cards.length > 1 ? 's' : ''}. '
            'Elles seront ajoutées sans remplacer vos cartes actuelles.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Importer'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final added = await controller.importCards(cards);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Aucune nouvelle carte : les doublons ont été ignorés.'
                : '$added carte${added > 1 ? 's' : ''} importée${added > 1 ? 's' : ''}.',
          ),
        ),
      );
    } on CardBackupException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’importer cette sauvegarde.'),
        ),
      );
    }
  }

  Future<void> _clearCards(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_outlined, color: AppTheme.danger),
        title: const Text('Tout supprimer ?'),
        content: const Text(
          'Toutes les cartes seront supprimées de cet appareil. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.clearAll();
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/icon/fidelio_app_icon_v2.png',
            width: 52,
            height: 52,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Réglages',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Personnalisez votre expérience Fidelio',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletSummary extends StatelessWidget {
  const _WalletSummary({required this.controller});

  final LoyaltyController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: .13),
            AppTheme.secondary.withValues(alpha: .07),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          const _SettingsIcon(icon: Icons.lock_rounded),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Portefeuille protégé et local',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${controller.cards.length} carte${controller.cards.length > 1 ? 's' : ''} enregistrée${controller.cards.length > 1 ? 's' : ''} sur cet appareil',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'LOCAL',
              style: TextStyle(
                color: Color(0xFF248A50),
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppTheme.danger
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
