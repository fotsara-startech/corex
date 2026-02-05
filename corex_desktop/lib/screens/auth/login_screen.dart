import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController _authController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Initialiser le controller de manière sécurisée
    try {
      _authController = Get.find<AuthController>();
    } catch (e) {
      print('⚠️ [LOGIN] AuthController non trouvé, création d\'une instance: $e');
      _authController = Get.put(AuthController());
    }

    // Vérifier si l'utilisateur est déjà connecté après que l'interface soit prête
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfAlreadyAuthenticated();
    });
  }

  void _checkIfAlreadyAuthenticated() {
    // Si l'utilisateur est déjà authentifié, rediriger vers l'accueil
    if (_authController.isAuthenticated.value && _authController.currentUser.value != null) {
      print('🔄 [LOGIN] Utilisateur déjà connecté, redirection vers /home');
      Get.offAllNamed('/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await _authController.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // La redirection est maintenant gérée automatiquement par AuthController
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Déterminer la largeur de la carte selon l'écran
          double cardWidth;
          double padding;

          if (constraints.maxWidth < 600) {
            // Mobile
            cardWidth = constraints.maxWidth * 0.9;
            padding = 16.0;
          } else if (constraints.maxWidth < 900) {
            // Tablette
            cardWidth = 500;
            padding = 24.0;
          } else {
            // Desktop
            cardWidth = 450;
            padding = 32.0;
          }

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: cardWidth,
                  padding: EdgeInsets.all(padding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo responsive
                        Container(
                          width: constraints.maxWidth < 600 ? 80 : 100,
                          height: constraints.maxWidth < 600 ? 80 : 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(constraints.maxWidth < 600 ? 40 : 50),
                          ),
                          child: Center(
                            child: Text(
                              'COREX',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: constraints.maxWidth < 600 ? 20 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Titre responsive
                        Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: constraints.maxWidth < 600 ? 24 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Application COREX',
                          style: TextStyle(
                            fontSize: constraints.maxWidth < 600 ? 12 : 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),

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
                        const SizedBox(height: 24),

                        // Bouton de connexion
                        Obx(() => SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _authController.isLoading.value ? null : _handleLogin,
                                child: _authController.isLoading.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Se connecter',
                                        style: TextStyle(fontSize: constraints.maxWidth < 600 ? 14 : 16),
                                      ),
                              ),
                            )),
                        const SizedBox(height: 16),

                        // Lien vers inscription client - Responsive
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Client sans compte ? ',
                              style: TextStyle(fontSize: constraints.maxWidth < 600 ? 12 : 14),
                            ),
                            TextButton(
                              onPressed: () => Get.toNamed('/register'),
                              child: Text(
                                'Créer un compte client',
                                style: TextStyle(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: constraints.maxWidth < 600 ? 12 : 14,
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
          );
        },
      ),
    );
  }
}
