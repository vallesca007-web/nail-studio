class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  String displayName = 'Invitada';
  String email = '';
  String? photoUrl;
  bool isGoogleUser = false;

  void setEmailUser(String emailAddress) {
    email = emailAddress.trim();
    displayName = email.split('@').first;
    photoUrl = null;
    isGoogleUser = false;
  }

  void setGuest() {
    displayName = 'Invitada';
    email = '';
    photoUrl = null;
    isGoogleUser = false;
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
