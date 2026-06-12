/// Model User — sesuai payload `user` dari AuthApiController & userProfile.
class User {
  final int id;
  final String name;
  final String? email; // hanya tersedia untuk user yang login
  final String? bio;
  final String? photo;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.bio,
    this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: (json['name'] ?? 'Unknown') as String,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      photo: json['photo'] as String?,
    );
  }
}
