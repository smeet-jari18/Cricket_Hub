import 'package:cloud_firestore/cloud_firestore.dart';

/// Signed-in account profile and server-computed career statistics.
class AppUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String avatarUrl;
  final String role;
  final String battingStyle;
  final String bowlingStyle;
  final Map<String, dynamic> careerStats;

  const AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    this.avatarUrl = '',
    this.role = 'player',
    this.battingStyle = '',
    this.bowlingStyle = '',
    this.careerStats = const {},
  });

  bool get isProfileComplete => displayName.trim().isNotEmpty;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final rawStats = map['career_stats'];
    return AppUser(
      uid: uid,
      phoneNumber: (map['phone_number'] ?? '') as String,
      displayName: (map['display_name'] ?? '') as String,
      avatarUrl: (map['avatar_url'] ?? '') as String,
      role: (map['role'] ?? 'player') as String,
      battingStyle: (map['batting_style'] ?? '') as String,
      bowlingStyle: (map['bowling_style'] ?? '') as String,
      careerStats: rawStats is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawStats)
          : rawStats is Map
              ? Map<String, dynamic>.from(rawStats)
              : const {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone_number': phoneNumber,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role,
      'batting_style': battingStyle,
      'bowling_style': bowlingStyle,
      'career_stats': careerStats,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
