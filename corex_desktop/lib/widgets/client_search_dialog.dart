import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

class ClientSearchDialog extends StatefulWidget {
  final Function(ClientModel) onClientSelected;

  const ClientSearchDialog({
    super.key,
    required this.onClientSelected,
  });

  @override
  State<ClientSearchDialog> createState() => _ClientSearchDialogState();
}

class _ClientSearchDialogState extends State<ClientSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final RxList<ClientModel> _searchResults = <ClientModel>[].obs;
  final RxBool _isSearching = false.obs;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchResults.clear();
      return;
    }

    _isSearching.value = true;

    try {
      if (!Get.isRegistered<ClientController>()) {
        Get.put(ClientController());
      }

      final clientController = Get.find<ClientController>();
      final results = await clientController.searchMultiCriteria(query);
      _searchResults.value = results;
    } catch (e) {
      print('❌ [CLIENT_SEARCH] Erreur recherche: $e');
      Get.snackbar('Erreur', 'Erreur lors de la recherche');
    } finally {
      _isSearching.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                const Icon(Icons.search, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Rechercher un client',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Champ de recherche
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher par nom, téléphone ou email',
                prefixIcon: Icon(Icons.search),
                hintText: 'Tapez au moins 3 caractères...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.length >= 3) {
                  _performSearch();
                } else {
                  _searchResults.clear();
                }
              },
            ),
            const SizedBox(height: 20),

            // Résultats
            Expanded(
              child: Obx(() {
                if (_isSearching.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_searchResults.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun résultat.\nTapez au moins 3 caractères pour rechercher.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final client = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            client.nom.isNotEmpty ? client.nom[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          client.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(client.telephone),
                              ],
                            ),
                            if (client.email != null && client.email!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.email, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      client.email!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${client.ville} - ${client.adresse}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            widget.onClientSelected(client);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Sélectionner'),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}