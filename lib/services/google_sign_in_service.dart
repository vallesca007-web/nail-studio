import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'app_session.dart';

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
}

class GoogleSignInServiceException implements Exception {
  const GoogleSignInServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _initialization;
  GoogleSignInAccount? _account;

  Future<String> signInAndGetIdToken() async {
    if (AppConfig.googleServerClientId.contains('YOUR_GOOGLE')) {
      throw const GoogleSignInServiceException(
        'Google OAuth no está configurado todavía. Falta agregar los Client IDs.',
      );
    }
    try {
      await (_initialization ??= _googleSignIn.initialize(
        clientId: kIsWeb ? AppConfig.googleServerClientId : null,
        serverClientId: AppConfig.googleServerClientId,
      ));
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleSignInServiceException(
          'Google no devolvió un token de sesión. Revisa la configuración OAuth.',
        );
      }
      _account = account;
      AppSession.instance.setGoogleUser(
        name: account.displayName ?? account.email,
        emailAddress: account.email,
        imageUrl: account.photoUrl,
      );
      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelledException();
      }
      throw const GoogleSignInServiceException(
        'No se pudo iniciar sesión con Google. Verifica la configuración e inténtalo de nuevo.',
      );
    }
  }

  Future<void> signOut() async {
    if (_account != null) {
      await (_initialization ??= _googleSignIn.initialize(
        clientId: kIsWeb ? AppConfig.googleServerClientId : null,
        serverClientId: AppConfig.googleServerClientId,
      ));
      await _googleSignIn.signOut();
    }
    _account = null;
    AppSession.instance.setGuest();
  }
}
