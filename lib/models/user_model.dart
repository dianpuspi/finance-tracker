class User {
  String id;
  String name;
  String username;
  String password;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
  });

  // Konversi ke Map untuk penyimpanan SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id == '0' ? null : int.parse(id), // null untuk auto-increment
      'name': name,
      'username': username,
      'password': password,
    };
  }

  // Membuat objek User dari data SQLite
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '0', // Konversi ke string
      name: map['name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
    );
  }

  // Untuk serialisasi JSON
  Map<String, dynamic> toJson() => toMap();

  // Untuk deserialisasi JSON
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  // Membuat salinan dengan perubahan opsional
  User copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}