import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _continue({required bool guest}) {
    if (!guest && !_formKey.currentState!.validate()) return;
    if (guest) {
      AppSession.instance.setGuest();
    } else {
      AppSession.instance.setEmailUser(_email.text);
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.heroPink, AppTheme.softPink],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset('assets/images/logo.png'),
                        ),
                        const SizedBox(height: 14),
                        Text('STUDIO DE MANICURA', style: AppTheme.labelStyle),
                        const SizedBox(height: 5),
                        Text(
                          'Anne Nails',
                          style: AppTheme.titleStyle.copyWith(fontSize: 34),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Cuidado sofisticado, indulgencia y diseño de autor para tus manos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.muted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('BIENVENIDA', style: AppTheme.labelStyle),
                  const SizedBox(height: 5),
                  Text(
                    'Iniciar sesión',
                    style: AppTheme.titleStyle.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Accede a tu agenda exclusiva y citas personalizadas.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.text.withValues(alpha: 0.045),
                          blurRadius: 22,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Correo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Ingresar correo',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty || !email.contains('@')) {
                                return 'Ingresa un correo válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Contraseña',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _password,
                            obscureText: _hidePassword,
                            decoration: InputDecoration(
                              hintText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() {
                                  _hidePassword = !_hidePassword;
                                }),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                ? 'Ingresa tu contraseña'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Contacta con el estudio para recuperar tu acceso.',
                                      ),
                                    ),
                                  ),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          PillButton(
                            label: 'Entrar',
                            onPressed: () => _continue(guest: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: _PromoTile(
                          title: 'Nail Art Couture',
                          imageUrl: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=700&q=80',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _PromoTile(
                          title: 'Atención Privada',
                          imageUrl: 'https://images.unsplash.com/photo-1600948836101-f9ffda59d250?auto=format&fit=crop&w=700&q=80',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La creación de cuentas estará disponible pronto.',
                              ),
                            ),
                          ),
                      child: const Text('Crear cuenta'),
                    ),
                  ),
                  SecondaryPill(
                    label: 'Continuar como invitada',
                    onPressed: () => _continue(guest: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppTheme.softPink,
              child: Icon(Icons.spa_outlined, color: AppTheme.accent),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppTheme.button],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
