// lib/models/user_profile.dart

class UserProfile {
  final int xp;
  final int hearts;
  final int streakDays;
  final DateTime lastPlayDate;

  const UserProfile({
    this.xp = 0,
    this.hearts = 5,
    this.streakDays = 0,
    required this.lastPlayDate,
  });

  UserProfile copyWith({
    int? xp,
    int? hearts,
    int? streakDays,
    DateTime? lastPlayDate,
  }) {
    return UserProfile(
      xp: xp ?? this.xp,
      hearts: hearts ?? this.hearts,
      streakDays: streakDays ?? this.streakDays,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
    );
  }
}
