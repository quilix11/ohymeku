class GoogleIdentity {
  final String? idToken;
  final Map<String, dynamic>? session;
  const GoogleIdentity.token(this.idToken) : session = null;
  const GoogleIdentity.session(this.session) : idToken = null;
}
