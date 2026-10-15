import 'package:expo_spot/core/json/json_readers.dart';

/// Mirrors `com.nawaf.meetingpoint.Model.User`.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String? email;
  final DateTime createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: JsonReaders.intValue(json['id']),
      name: JsonReaders.stringValue(json['name']),
      email: JsonReaders.stringOrNull(json['email']),
      createdAt: JsonReaders.dateTimeOrNull(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
