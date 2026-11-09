import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class CargandoScreen extends StatefulWidget {
  const CargandoScreen({super.key});

  @override
  State<CargandoScreen> createState() => _CargandoScreenState();
}

class _CargandoScreenState extends State<CargandoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: const ShapeDecoration(
                  color: AppTheme.surface,
                  shape: StadiumBorder(),
                ),
                child: Text(
                  'HAUTE MANICURE STUDIO',
                  style: AppTheme.labelStyle,
                ),
              ),
              const SizedBox(height: 34),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.rotate(
                  angle: _controller.value * 6.283,
                  child: child,
                ),
                child: SizedBox(
                  width: 204,
                  height: 204,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 194,
                        height: 194,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.softPink,
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 166,
                        height: 166,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.heroPink,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 142,
                        height: 142,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accent,
                        ),
                      ),
                      Container(
                        width: 112,
                        height: 112,
                        padding: const EdgeInsets.all(21),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'PREPARANDO EL SANTUARIO\nDE BELLEZA',
                textAlign: TextAlign.center,
                style: AppTheme.labelStyle.copyWith(height: 1.8),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.softPink,
                ),
              ),
              const Spacer(),
              Text(
                'ANNE NAILS • STUDIO\nCUIDADO • ESTILO • PRECISIÓN',
                textAlign: TextAlign.center,
                style: AppTheme.labelStyle.copyWith(
                  color: AppTheme.muted,
                  height: 1.8,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
