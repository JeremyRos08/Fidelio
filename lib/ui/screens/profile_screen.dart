import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../services/profile_image_service.dart';
import '../../state/loyalty_controller.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final LoyaltyController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil et compte')),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final displayName = controller.profileName.isEmpty
                ? 'Mon profil'
                : controller.profileName;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _ProfileHeader(
                      displayName: displayName,
                      email: controller.profileEmail,
                      imageBytes: controller.profileImageBytes,
                      onEdit: () => _editProfile(context),
                      onEditImage: () => _editImage(context),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Votre portefeuille',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.credit_card_rounded,
                            value: '${controller.cards.length}',
                            label: controller.cards.length > 1
                                ? 'Cartes'
                                : 'Carte',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_rounded,
                            value: '${controller.favoriteCount}',
                            label: 'Favoris',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Compte Fidelio',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    const _AccountCard(),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const _ProfileIcon(Icons.shield_outlined),
                        title: const Text('Vos données restent privées'),
                        subtitle: const Text(
                          'La photo, l’identité, l’e-mail et les cartes sont conservés localement sur cet appareil.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final result = await showDialog<_ProfileDetails>(
      context: context,
      builder: (context) => _ProfileEditorDialog(
        firstName: controller.profileFirstName,
        lastName: controller.profileLastName,
        email: controller.profileEmail,
      ),
    );
    if (result == null) return;
    await controller.setProfile(
      firstName: result.firstName,
      lastName: result.lastName,
      email: result.email,
    );
  }

  Future<void> _editImage(BuildContext context) async {
    if (controller.profileImageBytes != null) {
      final action = await showModalBottomSheet<_ImageAction>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choisir une autre photo'),
                onTap: () => Navigator.pop(context, _ImageAction.choose),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.danger,
                ),
                title: const Text(
                  'Supprimer la photo',
                  style: TextStyle(color: AppTheme.danger),
                ),
                onTap: () => Navigator.pop(context, _ImageAction.remove),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (action == _ImageAction.remove) {
        await controller.setProfileImage(null);
        return;
      }
      if (action != _ImageAction.choose) return;
    }

    try {
      const images = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        uniformTypeIdentifiers: ['public.image'],
        webWildCards: ['image/*'],
      );
      final file = await openFile(acceptedTypeGroups: const [images]);
      if (file == null) return;
      final prepared = await ProfileImageService.prepare(
        await file.readAsBytes(),
      );
      await controller.setProfileImage(prepared);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil enregistrée.')),
      );
    } on ProfileImageException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de sélectionner la photo.')),
      );
    }
  }
}

enum _ImageAction { choose, remove }

class _ProfileDetails {
  const _ProfileDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String email;
}

class _ProfileEditorDialog extends StatefulWidget {
  const _ProfileEditorDialog({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String email;

  @override
  State<_ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<_ProfileEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.firstName);
    lastNameController = TextEditingController(text: widget.lastName);
    emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.person_outline_rounded),
      title: const Text('Modifier le profil'),
      content: SizedBox(
        width: 430,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  autofocus: true,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: lastNameController,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  maxLength: 100,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'nom@exemple.fr',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                  onFieldSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    return isValid ? null : 'Saisissez une adresse e-mail valide.';
  }

  void _save() {
    if (formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      _ProfileDetails(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.imageBytes,
    required this.onEdit,
    required this.onEditImage,
  });

  final String displayName;
  final String email;
  final Uint8List? imageBytes;
  final VoidCallback onEdit;
  final VoidCallback onEditImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Tooltip(
            message: 'Modifier la photo',
            child: GestureDetector(
              onTap: onEditImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withValues(alpha: .18),
                    foregroundImage: imageBytes == null
                        ? null
                        : MemoryImage(imageBytes!),
                    child: imageBytes == null
                        ? Text(
                            displayName.trim().substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 6),
                const _LocalBadge(),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Modifier le profil',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'PROFIL LOCAL',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 23),
            const SizedBox(height: 7),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                _ProfileIcon(Icons.cloud_off_rounded),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aucun compte connecté',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text('Fidelio fonctionne entièrement sans compte.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.construction_rounded, color: AppTheme.primary),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Cet espace est prêt à accueillir plus tard la connexion et la synchronisation entre appareils.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 22),
    );
  }
}
