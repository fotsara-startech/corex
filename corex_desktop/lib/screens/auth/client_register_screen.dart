import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

class ClientRegisterScreen extends StatefulWidget {
  const ClientRegisterScreen({super.key});

  @override
  State<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();

  late final AuthService _authService;
  final RxBool _isLoading = false.obs;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    // Initialiser AuthService de manière sécurisée
    try {
      _authService = Get.find<AuthService>();
    } catch (e) {
      print('⚠️ [CLIENT REGISTER] AuthService non trouvé, création: $e');
      _authService = Get.put(AuthService());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      _isLoading.value = true;

      try {
        print('📝 [CLIENT REGISTER] Inscription client: ${_emailController.text}');

        // Créer le compte client
        final user = await _authService.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          role: 'client', // Rôle spécifique client
        );

        print('✅ [CLIENT REGISTER] Inscription réussie pour ${user.nomComplet}');

        Get.snackbar(
          'Inscription réussie',
          'Bienvenue ${user.prenom} ! Votre compte client a été créé avec succès.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4CAF50),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        // Rediriger vers la page de connexion
        Get.offAllNamed('/login');
      } catch (e) {
        print('❌ [CLIENT REGISTER] Erreur inscription: $e');
        Get.snackbar(
          'Erreur d\'inscription',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } finally {
        _isLoading.value = false;
      }
    }
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Déterminer la largeur et le padding selon l'écran
          double cardWidth;
          double padding;
          bool isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // Mobile
            cardWidth = constraints.maxWidth * 0.9;
            padding = 16.0;
          } else if (constraints.maxWidth < 900) {
            // Tablette
            cardWidth = 600;
            padding = 24.0;
          } else {
            // Desktop
            cardWidth = 500;
            padding = 32.0;
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF4CAF50),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo responsive
                            Container(
                              width: isMobile ? 60 : 80,
                              height: isMobile ? 60 : 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(isMobile ? 30 : 40),
                              ),
                              child: Center(
                                child: Text(
                                  'COREX',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Titre responsive
                            Text(
                              'Inscription Client',
                              style: TextStyle(
                                fontSize: isMobile ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Créez votre compte pour accéder aux services COREX',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Prénom et Nom - Layout responsive
                            if (isMobile) ...[
                              // Mobile : Layout vertical
                              TextFormField(
                                controller: _prenomController,
                                decoration: const InputDecoration(
                                  labelText: 'Prénom',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Prénom requis';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nomController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nom requis';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              // Desktop/Tablette : Layout horizontal
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _prenomController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prénom',
                                        prefixIcon: Icon(Icons.person),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Prénom requis';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nomController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nom',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Nom requis';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 16),

                            // Téléphone
                            TextFormField(
                              controller: _telephoneController,
                              decoration: const InputDecoration(
                                labelText: 'Téléphone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Téléphone requis';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Mot de passe
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 16),

                            // Confirmation mot de passe
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirmer le mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              obscureText: _obscureConfirmPassword,
                              validator: _validateConfirmPassword,
                            ),
                            const SizedBox(height: 24),

                            // Bouton d'inscription
                            Obx(() => SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading.value ? null : _handleRegister,
                                    child: _isLoading.value
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'Créer mon compte',
                                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                                          ),
                                  ),
                                )),
                            const SizedBox(height: 16),

                            // Lien vers connexion - Responsive
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  'Déjà un compte ? ',
                                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                                ),
                                TextButton(
                                  onPressed: () => Get.offAllNamed('/login'),
                                  child: Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      color: const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
