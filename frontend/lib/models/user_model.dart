class UserModel {
  final String id;
  final String username;
  final String email;
  final bool emailVerified;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.emailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      emailVerified: json['emailVerified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'emailVerified': emailVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    bool? emailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
