import 'package:cloud_firestore/cloud_firestore.dart';

/// AppUser = one document in the `users` collection.
/// Matches CricketHub_Backend_Schema.md -> Collection: users
class AppUser {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String avatarUrl;
  final String role; // "player", "organizer", "scorer"
  final String battingStyle; // e.g. "Right-hand"
  final String bowlingStyle; // e.g. "Leg-break"

  AppUser({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    this.avatarUrl = '',
    this.role = 'player',
    this.battingStyle = '',
    this.bowlingStyle = '',
  });

  bool get isProfileComplete => displayName.trim().isNotEmpty;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      phoneNumber: (map['phone_number'] ?? '') as String,
      displayName: (map['display_name'] ?? '') as String,
      avatarUrl: (map['avatar_url'] ?? '') as String,
      role: (map['role'] ?? 'player') as String,
      battingStyle: (map['batting_style'] ?? '') as String,
      bowlingStyle: (map['bowling_style'] ?? '') as String,
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
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
