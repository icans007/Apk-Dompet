import 'package:hive/hive.dart';

part 'user_model.g.dart';

/// Model data pengguna DompetKu
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String email;

  @HiveField(3)
  late String passwordHash; // Simpan hash password, bukan plaintext

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  String? photoUrl;

  @HiveField(6)
  String currency; // Mata uang default: IDR

  @HiveField(7)
  bool isDarkMode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.photoUrl,
    this.currency = 'IDR',
    this.isDarkMode = false,
  });

  /// Salin model dengan perubahan tertentu
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    String? photoUrl,
    String? currency,
    bool? isDarkMode,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  /// Konversi ke Map untuk serialisasi
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
      'currency': currency,
      'isDarkMode': isDarkMode,
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email)';
  }
}
