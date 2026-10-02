import 'package:cloud_firestore/cloud_firestore.dart';

/// Team = one document in the `teams` collection.
/// Matches CricketHub_Backend_Schema.md -> Collection: teams
class Team {
  final String id;
  final String teamName;
  final String city;
  final String adminUid; // creator - only admin can edit (security rules)
  final String logoUrl;
  final List<String> roster; // player names for Phase 1 (UIDs later)

  Team({
    required this.id,
    required this.teamName,
    required this.city,
    required this.adminUid,
    this.logoUrl = '',
    this.roster = const [],
  });

  factory Team.fromFirestore(String id, Map<String, dynamic> map) {
    return Team(
      id: id,
      teamName: (map['team_name'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      adminUid: (map['admin_uid'] ?? '') as String,
      logoUrl: (map['logo_url'] ?? '') as String,
      roster: List<String>.from(map['roster'] ?? const <String>[]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'team_name': teamName,
      'city': city,
      'admin_uid': adminUid,
      'logo_url': logoUrl,
      'roster': roster,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
