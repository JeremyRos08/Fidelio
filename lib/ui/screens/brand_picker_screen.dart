import 'package:flutter/material.dart';

import '../../services/brand_directory_service.dart';

class BrandPickerScreen extends StatefulWidget {
  const BrandPickerScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<BrandPickerScreen> createState() => _BrandPickerScreenState();
}

class _BrandPickerScreenState extends State<BrandPickerScreen> {
  late final TextEditingController searchController;
  List<String> brands = BrandDirectoryService.popularBrands;
  bool isLoading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    query = widget.initialQuery;
    searchController = TextEditingController(text: query);
    _loadBrands();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    final result = await BrandDirectoryService.instance.loadBrands();
    if (!mounted) return;
    setState(() {
      brands = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final matches = brands
        .where((brand) {
          return normalizedQuery.isEmpty ||
              brand.toLowerCase().contains(normalizedQuery);
        })
        .take(80)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir une enseigne')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SearchBar(
                controller: searchController,
                hintText: 'Ex. Carrefour, Decathlon…',
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (query.isNotEmpty)
                    IconButton(
                      tooltip: 'Effacer',
                      onPressed: () {
                        searchController.clear();
                        setState(() => query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            if (isLoading) const LinearProgressIndicator(minHeight: 2),
            if (query.trim().isNotEmpty &&
                !brands.any(
                  (brand) => brand.toLowerCase() == query.trim().toLowerCase(),
                ))
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                title: Text('Utiliser « ${query.trim()} »'),
                subtitle: const Text('Ajouter une enseigne personnalisée'),
                onTap: () => Navigator.pop(context, query.trim()),
              ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune enseigne trouvée',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 67),
                      itemBuilder: (context, index) {
                        final brand = matches[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .1),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            brand,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(context, brand),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
