# Plan d'Implémentation - COREX

## Vue d'Ensemble

Ce plan d'implémentation transforme la conception COREX en tâches de développement concrètes. L'approche priorise le développement incrémental avec une architecture Flutter + Firebase + GetX. Chaque tâche est conçue pour être exécutée de manière autonome tout en s'intégrant parfaitement aux étapes précédentes.

Le projet est divisé en phases correspondant aux modules fonctionnels principaux, permettant une livraison progressive et des tests continus.

## Tâches d'Implémentation

### Phase 0 - Configuration et Infrastructure

- [x] 0.1 Configuration de l'environnement de développement
  - Initialiser les projets Flutter (desktop, mobile, shared)
  - Configurer GetX pour state management et navigation
  - Mettre en place la structure de dossiers selon l'architecture
  - Configurer Firebase (Authentication, Realtime Database)
  - _Exigences: 20.1, 20.2, 20.3_

- [x] 0.2 Création des modèles de données de base
  - Créer UserModel avec tous les champs et méthodes
  - Créer AgenceModel pour les agences COREX
  - Créer ColisModel avec historique de statuts
  - Créer LivraisonModel pour les livraisons
  - Créer TransactionModel pour la gestion financière
  - _Exigences: 1.1, 2.1, 3.1, 8.1, 10.1_

- [x] 0.3 Implémentation des services Firebase de base
  - Créer FirebaseService avec configuration de persistance
  - Créer AuthService avec connexion, déconnexion, création utilisateur
  - Créer ColisService avec CRUD et recherche
  - Configurer les règles de sécurité Firebase
  - _Exigences: 1.1, 1.2, 17.1, 17.2_

- [x] 0.4 Configuration du thème et des composants UI
  - Créer CorexTheme avec les couleurs (Vert, Noir, Blanc)
  - Développer les widgets réutilisables (boutons, champs, cartes)
  - Configurer GetMaterialApp avec routes et bindings
  - Créer les layouts de base (AppBar, Drawer, BottomNav)
  - _Exigences: 19.1, 19.2_

### Phase 1 - Authentification et Gestion des Utilisateurs ✅

- [x] 1.1 Développer le module d'authentification
  - Créer AuthController avec GetX (observables, méthodes)
  - Développer l'écran de connexion avec validation
  - Implémenter la logique de connexion avec Firebase Auth
  - Ajouter la gestion des erreurs et feedback utilisateur
  - Implémenter la déconnexion automatique après 30 min d'inactivité
  - _Exigences: 1.1, 1.2, 1.5_

- [x] 1.2 Créer l'interface de gestion des utilisateurs (Admin)
  - Développer UserController pour la gestion CRUD
  - Créer l'écran de liste des utilisateurs avec recherche
  - Développer le formulaire de création/modification d'utilisateur
  - Implémenter l'activation/désactivation des comptes
  - Ajouter la réinitialisation de mot de passe
  - _Exigences: 1.3, 1.4_

- [x] 1.3 Implémenter le système de rôles et permissions
  - Créer RoleMiddleware pour GetX routes
  - Implémenter la vérification des permissions dans les controllers
  - Ajouter les guards sur les écrans selon les rôles
  - Développer la logique de filtrage des données par rôle
  - _Exigences: 1.2, 17.2, 17.4_

### Phase 2 - Gestion des Agences et Configuration ✅

- [x] 2.1 Développer le module de gestion des agences
  - Créer AgenceController avec GetX
  - Développer l'écran de liste des agences
  - Créer le formulaire de création/modification d'agence
  - Implémenter l'activation/désactivation des agences
  - Ajouter la liste des utilisateurs par agence
  - _Exigences: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 2.2 Créer le module de gestion des zones de livraison
  - Créer ZoneController avec GetX
  - Développer l'écran de gestion des zones
  - Implémenter l'ajout de quartiers par zone
  - Ajouter la configuration des tarifs par zone
  - _Exigences: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 2.3 Développer le module des agences de transport partenaires
  - Créer AgenceTransportController avec GetX
  - Développer l'écran de gestion des agences transport
  - Implémenter la configuration des villes desservies
  - Ajouter la grille tarifaire par destination
  - _Exigences: 6.1, 6.2, 6.3, 6.4, 6.5_

### Phase 3 - Module Expédition de Colis (Commercial)

- [ ] 3.1 Développer l'interface de collecte de colis
  - Créer ColisController avec GetX et observables
  - Développer le formulaire de saisie expéditeur
  - Créer le formulaire de saisie destinataire
  - Implémenter la saisie des détails du colis (contenu, poids, dimensions)
  - Ajouter la validation en temps réel des formulaires
  - _Exigences: 3.1, 3.2, 19.5_

- [ ] 3.2 Implémenter le calcul de tarif et modes de livraison
  - Développer l'interface de saisie du tarif
  - Créer la sélection du mode de livraison (domicile, bureau, agence transport)
  - Implémenter la sélection d'agence transport avec tarifs
  - Ajouter la sélection de zone pour livraison à domicile
  - _Exigences: 3.3, 3.4, 3.5_

- [ ] 3.3 Développer l'enregistrement du paiement
  - Créer l'interface de saisie du paiement
  - Implémenter la validation du paiement avec date
  - Ajouter la création automatique de transaction financière
  - Développer la sauvegarde du colis avec statut "collecte"
  - _Exigences: 3.6, 3.8_

- [ ] 3.4 Implémenter le mode hors ligne pour la collecte
  - Configurer la persistance Firebase pour les colis
  - Ajouter l'indicateur de mode hors ligne dans l'UI
  - Implémenter la synchronisation automatique au retour de connexion
  - Tester la collecte complète hors ligne
  - _Exigences: 3.7, 15.1, 15.2, 15.3, 15.5_

### Phase 4 - Module Enregistrement de Colis (Agent)

- [ ] 4.1 Développer l'interface d'enregistrement
  - Créer l'écran de liste des colis en statut "collecte"
  - Implémenter le filtrage et la recherche des colis
  - Développer l'écran de détails du colis pour vérification
  - Ajouter la validation des informations avant enregistrement
  - _Exigences: 4.1, 4.2_

- [ ] 4.2 Implémenter la génération du numéro de suivi
  - Développer la logique de génération (COL-2025-XXXXXX)
  - Implémenter le compteur auto-incrémenté dans Firebase
  - Ajouter la mise à jour du statut en "enregistre"
  - Enregistrer la date d'enregistrement et l'historique
  - _Exigences: 4.3, 4.4, 4.7_

- [ ] 4.3 Développer la génération de documents PDF
  - Créer PdfService avec génération de reçu de collecte
  - Implémenter la génération du bordereau d'expédition
  - Ajouter le logo et les couleurs COREX dans les PDF
  - Implémenter l'impression et l'export des documents
  - _Exigences: 4.5, 4.6, 18.6_

### Phase 5 - Module Suivi et Gestion des Statuts

- [ ] 5.1 Développer l'interface de recherche de colis
  - Créer l'écran de recherche multi-critères
  - Implémenter la recherche par numéro de suivi
  - Ajouter la recherche par nom expéditeur/destinataire
  - Implémenter la recherche par téléphone
  - _Exigences: 5.1, 5.7_

- [ ] 5.2 Créer l'interface de détails et historique
  - Développer l'écran de détails complets du colis
  - Implémenter l'affichage de l'historique des statuts
  - Ajouter la timeline visuelle des statuts
  - Afficher les informations de chaque changement (date, utilisateur, commentaire)
  - _Exigences: 5.2, 5.4_

- [ ] 5.3 Implémenter la mise à jour des statuts
  - Créer l'interface de changement de statut
  - Implémenter la validation du workflow des statuts
  - Ajouter la saisie de commentaire optionnel
  - Développer l'enregistrement automatique dans l'historique
  - _Exigences: 5.3, 5.4, 5.6_

- [ ] 5.4 Développer les filtres et vues par statut
  - Créer les filtres par statut dans la liste des colis
  - Implémenter les filtres par agence, commercial, coursier
  - Ajouter les filtres par date (période)
  - Développer les vues spécialisées (colis en attente, en transit, etc.)
  - _Exigences: 5.7_

### Phase 6 - Module Livraison à Domicile (Gestionnaire)

- [ ] 6.1 Développer l'interface d'attribution des livraisons
  - Créer LivraisonController avec GetX
  - Développer l'écran de liste des colis à livrer (statut "arriveDestination")
  - Implémenter le filtrage par zone géographique
  - Créer l'interface de sélection du coursier
  - _Exigences: 8.1, 8.2, 8.3_

- [ ] 6.2 Implémenter la création de fiches de livraison
  - Développer la logique de création de livraison
  - Implémenter la mise à jour du statut du colis en "enCoursLivraison"
  - Ajouter l'attribution du coursier au colis
  - Créer la notification au coursier
  - _Exigences: 8.4, 8.5_

- [ ] 6.3 Créer l'interface de suivi des livraisons
  - Développer l'écran de liste des livraisons par statut
  - Implémenter le filtrage par coursier
  - Ajouter la vue des livraisons en cours par coursier
  - Créer le tableau de bord des livraisons
  - _Exigences: 8.5, 8.6_

### Phase 7 - Module Interface Coursier

- [ ] 7.1 Développer l'interface coursier pour les livraisons
  - Créer l'écran de liste des livraisons assignées
  - Implémenter le filtrage par statut (enAttente, enCours)
  - Développer l'écran de détails de la livraison
  - Ajouter l'affichage des informations du destinataire
  - _Exigences: 9.1_

- [ ] 7.2 Implémenter l'enregistrement de la tournée
  - Créer l'interface d'enregistrement de l'heure de départ
  - Développer l'interface de confirmation de livraison
  - Implémenter la capture de signature ou photo
  - Ajouter l'enregistrement de l'heure de retour
  - _Exigences: 9.2, 9.3, 9.6_

- [ ] 7.3 Développer la gestion des échecs de livraison
  - Créer l'interface de déclaration d'échec
  - Implémenter la saisie du motif d'échec
  - Ajouter la capture de photo justificative
  - Développer la mise à jour du statut de livraison
  - _Exigences: 9.5_

- [ ] 7.4 Implémenter le mode hors ligne pour coursiers
  - Configurer la persistance pour les livraisons
  - Ajouter la synchronisation automatique des confirmations
  - Implémenter la gestion des conflits de données
  - Tester le workflow complet hors ligne
  - _Exigences: 9.4, 9.7, 15.1, 15.2, 15.3_

### Phase 8 - Module Gestion Financière (Caisse)

- [ ] 8.1 Développer l'interface de gestion de caisse
  - Créer TransactionController avec GetX
  - Développer le tableau de bord de la caisse
  - Implémenter l'affichage du solde en temps réel
  - Créer les graphiques d'évolution (recettes/dépenses)
  - _Exigences: 10.1_

- [ ] 8.2 Implémenter l'enregistrement des recettes
  - Créer le formulaire de saisie de recette
  - Implémenter la sélection de catégorie (expedition, livraison, etc.)
  - Ajouter l'upload de justificatif (photo/PDF)
  - Développer la validation et l'enregistrement
  - _Exigences: 10.2, 10.4_

- [ ] 8.3 Implémenter l'enregistrement des dépenses
  - Créer le formulaire de saisie de dépense
  - Implémenter la sélection de catégorie (transport, salaires, etc.)
  - Ajouter l'upload de justificatif obligatoire
  - Développer la validation et l'enregistrement
  - _Exigences: 10.3, 10.4_

- [ ] 8.4 Développer l'historique et le rapprochement
  - Créer l'écran d'historique des transactions
  - Implémenter les filtres par date, type et catégorie
  - Développer l'interface de rapprochement de caisse
  - Ajouter le calcul du solde théorique vs réel
  - _Exigences: 10.5, 10.7_

- [ ] 8.5 Implémenter l'enregistrement automatique des recettes
  - Développer la création automatique de recette lors du paiement d'un colis
  - Implémenter la création automatique pour les livraisons payées
  - Ajouter la création automatique pour les services (courses, stockage)
  - _Exigences: 10.6_

### Phase 9 - Module Rapports et Tableaux de Bord (PDG)

- [ ] 9.1 Développer le dashboard global (Mobile)
  - Créer DashboardController avec GetX
  - Développer l'écran de vue d'ensemble avec KPI
  - Implémenter l'affichage du CA global
  - Ajouter les statistiques de colis (nombre, statuts)
  - Créer les graphiques d'évolution
  - _Exigences: 11.1, 11.6_

- [ ] 9.2 Implémenter les rapports financiers consolidés
  - Créer l'écran de bilan consolidé toutes agences
  - Développer la sélection de période (jour, mois, année)
  - Implémenter le calcul des totaux par agence
  - Ajouter les graphiques comparatifs
  - _Exigences: 11.2, 11.3_

- [ ] 9.3 Développer les rapports par agence
  - Créer l'écran de sélection d'agence
  - Implémenter l'affichage des performances détaillées
  - Ajouter les statistiques par commercial et coursier
  - Développer les graphiques spécifiques à l'agence
  - _Exigences: 11.4, 11.7_

- [ ] 9.4 Implémenter l'export des rapports
  - Développer l'export en PDF des rapports
  - Implémenter l'export en Excel des données
  - Ajouter l'envoi par email des rapports
  - Créer les templates de rapports professionnels
  - _Exigences: 11.5_

### Phase 10 - Module Stockage de Marchandises

- [ ] 10.1 Développer la gestion des clients stockeurs
  - Créer StockageController avec GetX
  - Développer l'écran de liste des clients stockeurs
  - Créer le formulaire de création/modification de client
  - Implémenter la recherche et le filtrage
  - _Exigences: 12.1_

- [ ] 10.2 Implémenter l'enregistrement des dépôts
  - Créer le formulaire de dépôt de marchandises
  - Implémenter l'ajout de plusieurs produits avec quantités
  - Ajouter la saisie de l'emplacement de stockage
  - Développer la définition du tarif mensuel
  - _Exigences: 12.2, 12.3_

- [ ] 10.3 Développer la gestion de l'inventaire
  - Créer l'écran d'inventaire par client
  - Implémenter l'affichage des produits stockés
  - Développer l'interface de retrait de produits
  - Ajouter la mise à jour automatique des quantités
  - _Exigences: 12.4, 12.5_

- [ ] 10.4 Implémenter la facturation mensuelle
  - Développer la génération automatique des factures
  - Créer le template de facture PDF
  - Implémenter l'envoi automatique par email
  - Ajouter l'historique des factures et paiements
  - _Exigences: 12.6, 12.7_

### Phase 11 - Module Service de Courses

- [ ] 11.1 Développer l'interface de création de courses
  - Créer CourseController avec GetX
  - Développer le formulaire de demande de course
  - Implémenter la saisie des instructions détaillées
  - Ajouter le calcul automatique de la commission
  - _Exigences: 13.1, 13.2_

- [ ] 11.2 Implémenter l'attribution et le suivi
  - Créer l'interface d'attribution au coursier
  - Développer l'écran de suivi des courses
  - Implémenter les filtres par statut et coursier
  - Ajouter les notifications au coursier
  - _Exigences: 13.4, 13.7_

- [ ] 11.3 Développer l'interface coursier pour les courses
  - Créer l'écran de liste des courses assignées
  - Implémenter l'interface d'exécution de course
  - Ajouter l'upload des justificatifs de dépenses
  - Développer la confirmation de fin de course
  - _Exigences: 13.5, 13.6_

- [ ] 11.4 Implémenter la gestion des paiements
  - Créer l'interface d'enregistrement du paiement
  - Développer la création automatique de transaction financière
  - Implémenter la validation du montant vs justificatifs
  - _Exigences: 13.3_

### Phase 12 - Module Retour de Colis

- [ ] 12.1 Développer l'interface de création de retours
  - Créer RetourController avec GetX
  - Développer l'écran de sélection du colis initial
  - Implémenter la génération du numéro de suivi retour
  - Ajouter le lien entre retour et colis initial
  - _Exigences: 14.1, 14.2, 14.3_

- [ ] 12.2 Implémenter le workflow de retour
  - Développer l'attribution du retour à un coursier
  - Créer l'interface de suivi du retour
  - Implémenter la mise à jour du statut du colis initial
  - Ajouter l'affichage du retour dans les détails du colis
  - _Exigences: 14.4, 14.5, 14.6_

### Phase 13 - Notifications et Emails

- [ ] 13.1 Implémenter le service d'envoi d'emails
  - Créer EmailService avec configuration SMTP
  - Développer les templates d'emails (HTML)
  - Implémenter l'envoi asynchrone d'emails
  - Ajouter la gestion des erreurs d'envoi
  - _Exigences: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6_

- [ ] 13.2 Développer les notifications automatiques
  - Implémenter les notifications de changement de statut
  - Ajouter les notifications d'arrivée à destination
  - Développer les notifications d'attribution de livraison
  - Implémenter les notifications de facturation
  - _Exigences: 16.1, 16.2, 16.3, 16.4_

- [ ] 13.3 Créer le système d'alertes
  - Développer les alertes de seuil (stock, crédit, etc.)
  - Implémenter les notifications push pour mobile
  - Ajouter les alertes dans l'interface utilisateur
  - _Exigences: 16.5_

### Phase 14 - Sécurité et Traçabilité

- [ ] 14.1 Implémenter le système de logging
  - Créer LogService pour enregistrer les actions
  - Développer l'enregistrement automatique dans l'historique
  - Implémenter le logging des modifications sensibles
  - Ajouter le logging des tentatives d'accès non autorisées
  - _Exigences: 17.1, 17.3, 17.4, 17.5_

- [ ] 14.2 Renforcer la sécurité Firebase
  - Réviser et optimiser les règles de sécurité
  - Implémenter la validation côté serveur avec Cloud Functions
  - Ajouter la détection d'anomalies
  - Développer les tests de sécurité
  - _Exigences: 17.2, 17.4, 17.6_

- [ ] 14.3 Créer l'interface d'audit (Admin)
  - Développer l'écran de consultation des logs
  - Implémenter les filtres par utilisateur, date, action
  - Ajouter l'export des logs pour audit
  - Créer les rapports d'activité
  - _Exigences: 17.5_

### Phase 15 - Optimisation et Performance

- [ ] 15.1 Optimiser les performances de l'application
  - Implémenter la pagination pour les grandes listes
  - Ajouter le lazy loading des images et documents
  - Optimiser les requêtes Firebase avec index
  - Développer le cache intelligent des données
  - _Exigences: 18.1, 18.2, 18.5_

- [ ] 15.2 Améliorer l'expérience utilisateur
  - Ajouter les indicateurs de chargement partout
  - Implémenter les états vides avec messages explicites
  - Développer les animations de transition
  - Ajouter les tooltips et aide contextuelle
  - _Exigences: 19.3, 19.4_

- [ ] 15.3 Optimiser le mode hors ligne
  - Configurer la taille du cache Firebase
  - Implémenter la priorisation des données à synchroniser
  - Ajouter la gestion intelligente des conflits
  - Développer les indicateurs de synchronisation
  - _Exigences: 15.4, 15.6, 18.4_

### Phase 16 - Tests et Validation

- [ ] 16.1 Développer les tests unitaires
  - Créer les tests pour tous les controllers GetX
  - Implémenter les tests pour tous les services
  - Développer les tests pour les modèles de données
  - Ajouter les tests de validation
  - _Exigences: Toutes_

- [ ] 16.2 Développer les tests d'intégration
  - Créer les tests de flux utilisateur complets
  - Implémenter les tests de navigation
  - Développer les tests de synchronisation Firebase
  - Ajouter les tests du mode hors ligne
  - _Exigences: Toutes_

- [ ] 16.3 Effectuer les tests utilisateurs
  - Organiser des sessions de test avec les utilisateurs finaux
  - Collecter les retours et suggestions
  - Identifier les bugs et problèmes d'ergonomie
  - Prioriser les corrections et améliorations
  - _Exigences: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6_

### Phase 17 - Documentation et Déploiement

- [ ] 17.1 Créer la documentation utilisateur
  - Rédiger le guide utilisateur pour chaque rôle
  - Créer les tutoriels vidéo
  - Développer la FAQ
  - Ajouter l'aide contextuelle dans l'application
  - _Exigences: Toutes_

- [ ] 17.2 Créer la documentation technique
  - Documenter l'architecture et les choix techniques
  - Rédiger le guide de maintenance
  - Créer le guide de déploiement
  - Documenter les API et services
  - _Exigences: Toutes_

- [ ] 17.3 Préparer le déploiement
  - Configurer l'environnement de production Firebase
  - Créer les builds de production (Windows, Android)
  - Tester les builds sur différents environnements
  - Préparer les packages d'installation
  - _Exigences: 20.1, 20.2_

- [ ] 17.4 Former les utilisateurs
  - Organiser les sessions de formation par rôle
  - Créer les supports de formation
  - Effectuer les démonstrations pratiques
  - Assurer le support post-déploiement
  - _Exigences: Toutes_

## Estimation et Planification

### Durée Estimée par Phase

- **Phase 0** : 1 semaine (Terminée)
- **Phase 1** : 1 semaine
- **Phase 2** : 1 semaine
- **Phase 3** : 2 semaines
- **Phase 4** : 1 semaine
- **Phase 5** : 1 semaine
- **Phase 6** : 1 semaine
- **Phase 7** : 1.5 semaines
- **Phase 8** : 2 semaines
- **Phase 9** : 1.5 semaines
- **Phase 10** : 1.5 semaines
- **Phase 11** : 1 semaine
- **Phase 12** : 0.5 semaine
- **Phase 13** : 1 semaine
- **Phase 14** : 1 semaine
- **Phase 15** : 1 semaine
- **Phase 16** : 2 semaines
- **Phase 17** : 1 semaine

**Durée Totale Estimée** : 20 semaines (5 mois)

### Priorités

**Priorité Haute (MVP)** :
- Phases 0, 1, 2, 3, 4, 5, 6, 7, 8

**Priorité Moyenne** :
- Phases 9, 13, 14, 15

**Priorité Basse (Extensions)** :
- Phases 10, 11, 12

**Transversal** :
- Phases 16, 17

## Notes Importantes

1. **Tests continus** : Tester chaque fonctionnalité avant de passer à la suivante
2. **Commits réguliers** : Faire des commits après chaque tâche complétée
3. **Documentation** : Documenter le code au fur et à mesure
4. **Feedback utilisateur** : Valider avec les utilisateurs finaux à chaque phase
5. **Mode hors ligne** : Tester systématiquement le mode hors ligne pour les fonctionnalités critiques
6. **Performance** : Surveiller les performances et optimiser si nécessaire
7. **Sécurité** : Vérifier les règles Firebase et les permissions à chaque étape
