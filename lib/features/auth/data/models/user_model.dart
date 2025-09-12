import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String username;
  final String phoneNumber;
  final String? profilePictureUrl;
  final String? bio;
  final String? location;
  final DateTime joinedAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.phoneNumber,
    this.profilePictureUrl,
    this.bio,
    this.location,
    required this.joinedAt,
    required this.isEmailVerified,
    required this.isPhoneVerified,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? phoneNumber,
    String? profilePictureUrl,
    String? bio,
    String? location,
    DateTime? joinedAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      joinedAt: joinedAt ?? this.joinedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'location': location,
      'joinedAt': joinedAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final joinedAtRaw = map['joinedAt'];
    final joinedAt = joinedAtRaw is Timestamp
        ? joinedAtRaw.toDate()
        : joinedAtRaw is String
        ? DateTime.tryParse(joinedAtRaw) ?? DateTime.now()
        : DateTime.now();

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      bio: map['bio'],
      location: map['location'],
      joinedAt:joinedAt,
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    phoneNumber,
    profilePictureUrl,
    bio,
    location,
    joinedAt,
    isEmailVerified,
    isPhoneVerified,
  ];
}