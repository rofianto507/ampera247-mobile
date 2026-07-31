class User {
  final int id;
  final String name;
  final String login;
  final String? imageUrl;
  final bool isPatroli;

  const User({
    required this.id,
    required this.name,
    required this.login,
    this.imageUrl,
    this.isPatroli = false,
  });
}
