import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    this.name = 'Traveller',
    this.motto = '',
    this.avatarPath,
    required this.joinedAt,
  });

  final String name;
  final String motto;

  /// Absolute path to a copy of the picked image inside app documents.
  final String? avatarPath;

  final DateTime joinedAt;

  String get initials {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'T';
    if (parts.length == 1) return parts.first.characters(2);
    return '${parts.first.characters(1)}${parts.last.characters(1)}';
  }

  UserProfile copyWith({
    String? name,
    String? motto,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      motto: motto ?? this.motto,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'motto': motto,
        'avatarPath': avatarPath,
        'joinedAt': joinedAt.toIso8601String(),
      };

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Traveller',
        motto: json['motto'] as String? ?? '',
        avatarPath: json['avatarPath'] as String?,
        joinedAt:
            DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

extension on String {
  String characters(int count) =>
      length <= count ? toUpperCase() : substring(0, count).toUpperCase();
}
