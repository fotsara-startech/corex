# Améliorations - Formulaire de Collecte Complet

## Fonctionnalités Ajoutées

### 1. Saisie du Montant de Collecte

**Avant**: Le tarif était calculé automatiquement (1000 + 500 * poids)

**Après**: L'agent saisit manuellement le montant

```dart
TextFormField(
  controller: _tarifController,
  decoration: InputDecoration(
    labelText: 'Montant (FCFA) *',
    prefixIcon: const Icon(Icons.attach_money),
  ),
  keyboardType: TextInputType.number,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Montant requis';
    if (double.tryParse(value!) == null) return 'Montant invalide';
    return null;
  },
)
```

### 2. Choix de la Zone de Livraison (Domicile)

Quand le mode de livraison est "domicile", l'agent doit sélectionner une zone:

```dart
if (_modeLivraison == 'domicile') ...[
  DropdownButtonFormField<String>(
    value: _selectedZoneId,
    decoration: InputDecoration(
      labelText: 'Zone de livraison *',
      prefixIcon: const Icon(Icons.map),
    ),
    items: _zonesList.map((zone) => DropdownMenuItem(
      value: zone.id,
      child: Text('${zone.nom} - ${zone.tarifLivraison.toStringAsFixed(0)} FCFA'),
    )).toList(),
    validator: (value) {
      if (_modeLivraison == 'domicile' && value == null) {
        return 'Veuillez sélectionner une zone';
      }
      return null;
    },
  ),
]
```

**Avantages**:
- Affiche le tarif de livraison de chaque zone
- Validation obligatoire pour livraison à domicile
- Permet de calculer les coûts de livraison

### 3. Choix de l'Agence de Transport

Quand le mode de livraison est "agenceTransport", l'agent sélectionne l'agence:

```dart
if (_modeLivraison == 'agenceTransport') ...[
  DropdownButtonFormField<String>(
    value: _selectedAgenceTransportId,
    decoration: InputDecoration(
      labelText: 'Agence de transport *',
      prefixIcon: const Icon(Icons.business),
    ),
    items: _agencesTransportList.map((agence) => DropdownMenuItem(
      value: agence.id,
      child: Text(agence.nom),
    )).toList(),
  ),
  
  // Affichage du tarif vers la ville de destination
  if (_selectedAgenceTransportId != null)
    Card(
      color: Colors.blue.shade50,
      child: Text(
        'Tarif vers $ville: ${tarif.toStringAsFixed(0)} FCFA'
      ),
    ),
]
```

**Avantages**:
- Liste des agences actives uniquement
- Affichage du tarif vers la ville de destination
- Stockage du nom et tarif de l'agence dans le colis

### 4. Modes de Livraison Mis à Jour

**Avant**: 
- domicile
- bureau
- agence_transport

**Après**:
- domicile (avec sélection de zone)
- bureauCorex (retrait au bureau COREX)
- agenceTransport (avec sélection d'agence)

### 5. Chargement Dynamique des Données

Au démarrage du formulaire:

```dart
@override
void initState() {
  super.initState();
  // ...
  _loadZones();
  _loadAgencesTransport();
}

Future<void> _loadZones() async {
  final zoneService = Get.find<ZoneService>();
  final zones = await zoneService.getAllZones();
  _zonesList.value = zones;
}

Future<void> _loadAgencesTransport() async {
  final agenceTransportService = Get.find<AgenceTransportService>();
  final agences = await agenceTransportService.getAllAgencesTransport();
  _agencesTransportList.value = agences.where((a) => a.isActive).toList();
}
```

### 6. Informations Complètes dans le Colis

Le colis créé contient maintenant:

```dart
ColisModel(
  // ... informations de base ...
  
  // Nouvelles informations
  zoneId: _selectedZoneId,                    // ID de la zone de livraison
  agenceTransportId: _selectedAgenceTransportId,  // ID de l'agence transport
  agenceTransportNom: agenceTransportNom,     // Nom de l'agence
  tarifAgenceTransport: tarifAgenceTransport, // Tarif de l'agence
  montantTarif: double.parse(_tarifController.text), // Montant saisi
  
  // Historique
  historique: [
    HistoriqueStatut(
      statut: 'collecte',
      date: DateTime.now(),
      userId: userId,
      commentaire: 'Colis collecté',
    ),
  ],
)
```

### 7. Validation Conditionnelle

La validation s'adapte au mode de livraison:

- **Domicile**: Zone obligatoire
- **AgenceTransport**: Agence obligatoire
- **BureauCorex**: Aucune sélection supplémentaire

### 8. Information de Paiement

Carte informative affichant:
- Message: "Le paiement sera géré lors de l'enregistrement"
- Montant à collecter en temps réel

```dart
Card(
  color: Colors.blue.shade50,
  child: Column(
    children: [
      Text('Information Paiement'),
      Text('Le paiement sera géré lors de l\'enregistrement du colis.'),
      Text('Montant à collecter: ${_tarifController.text} FCFA'),
    ],
  ),
)
```

## Structure des Données

### Variables Ajoutées

```dart
final _tarifController = TextEditingController();
String? _selectedZoneId;
String? _selectedAgenceTransportId;
final RxList<ZoneModel> _zonesList = <ZoneModel>[].obs;
final RxList<AgenceTransportModel> _agencesTransportList = <AgenceTransportModel>[].obs;
```

### Méthodes Ajoutées

- `_loadZones()`: Charge toutes les zones
- `_loadAgencesTransport()`: Charge les agences actives

## Workflow Complet

1. **Étape 1 - Expéditeur**
   - Recherche ou saisie manuelle
   - Création automatique si n'existe pas

2. **Étape 2 - Destinataire**
   - Recherche ou saisie manuelle
   - Création automatique si n'existe pas
   - La ville est importante pour le tarif agence transport

3. **Étape 3 - Détails du Colis**
   - Contenu, poids, dimensions
   - **Mode de livraison**
     - Si domicile → Sélection zone obligatoire
     - Si agenceTransport → Sélection agence obligatoire + affichage tarif
     - Si bureauCorex → Aucune sélection
   - **Montant**: Saisie manuelle obligatoire
   - **Info paiement**: Rappel que le paiement se fera à l'enregistrement

4. **Validation**
   - Création des clients (si nouveaux)
   - Création du colis avec toutes les informations
   - Message de succès avec récapitulatif

## Avantages de la Solution

✅ **Flexibilité**: L'agent peut ajuster le tarif selon la négociation
✅ **Traçabilité**: Zone et agence transport enregistrées
✅ **Calcul automatique**: Affichage des tarifs zones/agences
✅ **Validation intelligente**: Champs obligatoires selon le mode
✅ **UX améliorée**: Informations contextuelles (tarifs, paiement)
✅ **Compatibilité**: Fonctionne avec l'ancien système

## Tests Recommandés

1. ✅ Créer un colis avec livraison à domicile (sélectionner une zone)
2. ✅ Créer un colis avec agence de transport (sélectionner une agence)
3. ✅ Créer un colis avec retrait au bureau COREX
4. ✅ Vérifier que les tarifs s'affichent correctement
5. ✅ Vérifier la validation des champs obligatoires
6. ✅ Vérifier que le montant saisi est bien enregistré
7. ✅ Vérifier que les informations zone/agence sont dans le colis
