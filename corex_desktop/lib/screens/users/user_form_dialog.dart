import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

class UserFormDialog extends StatefulWidget {
  final UserModel? user;

  const UserFormDialog({super.key, this.user});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();

  String _selectedRole = 'agent';
  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get isEditMode => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _emailController.text = widget.user!.email;
      _nomController.text = widget.user!.nom;
      _prenomController.text = widget.user!.prenom;
      _telephoneController.text = widget.user!.telephone;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ [FORM] Validation échouée');
      return;
    }

    print('📝 [FORM] Début de la soumission...');
    setState(() => _isLoading = true);

    try {
      final userController = Get.find<UserController>();
      bool success;

      if (isEditMode) {
        print('✏️ [FORM] Mode édition');
        // Mise à jour
        success = await userController.updateUser(
          widget.user!.id,
          {
            'nom': _nomController.text.trim(),
            'prenom': _prenomController.text.trim(),
            'telephone': _telephoneController.text.trim(),
            'role': _selectedRole,
          },
        );
      } else {
        print('➕ [FORM] Mode création');
        // Création
        success = await userController.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          role: _selectedRole,
        );
      }

      print('✅ [FORM] Opération terminée: success=$success');

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success) {
        print('🚪 [FORM] Fermeture du dialog');
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        print('⚠️ [FORM] Échec de l\'opération, dialog reste ouvert');
      }
    } catch (e, stackTrace) {
      print('❌ [FORM] Erreur: $e');
      print('📍 [STACK] $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  isEditMode ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isEditMode, // Email non modifiable en édition
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),

                // Mot de passe (uniquement en création)
                if (!isEditMode) ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe *',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                ],

                // Prénom
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Le prénom'),
                ),
                const SizedBox(height: 16),

                // Nom
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Le nom'),
                ),
                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone *',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '6XXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),

                // Rôle
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rôle *',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                    DropdownMenuItem(value: 'gestionnaire', child: Text('Gestionnaire')),
                    DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                    DropdownMenuItem(value: 'coursier', child: Text('Coursier')),
                    DropdownMenuItem(value: 'agent', child: Text('Agent')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Get.back(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditMode ? 'Modifier' : 'Créer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
