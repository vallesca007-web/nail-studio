class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  String displayName = 'Invitada';
  String email = '';
  String? photoUrl;
  bool isGoogleUser = false;
  String authToken = '';

  void setAuthenticatedUser({
    required String emailAddress,
    required String token,
  }) {
    email = emailAddress.trim();
    displayName = email.split('@').first;
    photoUrl = null;
    isGoogleUser = false;
    authToken = token;
  }

  void setEmailUser(String emailAddress) {
    email = emailAddress.trim();
    displayName = email.split('@').first;
    photoUrl = null;
    isGoogleUser = false;
    authToken = '';
  }

  void setGuest() {
    displayName = 'Invitada';
    email = '';
    photoUrl = null;
    isGoogleUser = false;
    authToken = '';
  }

  void setGoogleUser({
    required String name,
    required String emailAddress,
    String? imageUrl,
  }) {
    displayName = name;
    email = emailAddress;
    photoUrl = imageUrl;
    isGoogleUser = true;
  }
}
