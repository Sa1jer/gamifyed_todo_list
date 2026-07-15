import 'dart:typed_data';

import 'xp_owner.dart';

enum Gender { male, female, nonBinary }

const genderLabel = {
  Gender.male: 'Мужской',
  Gender.female: 'Женский',
  Gender.nonBinary: 'Многофункциональный',
};

class UserProfile with XPOwner {
  String name;
  @override
  int level, xp;

  /// Cumulative credited XP, adjusted when a completion is undone.
  int totalXpEarned;

  int? age;
  Gender? gender;

  /// Raw bytes of the user's chosen avatar image (PNG/JPG)
  Uint8List? avatarBytes;

  /// Raw bytes of the profile banner image (PNG/JPG)
  Uint8List? bannerBytes;

  int streakProtectionCharges;
  DateTime? streakProtectionRefilledAt;
  DateTime? lastStreakProtectionUsedAt;
  String? lastStreakProtectionTaskTitle;

  UserProfile({
    required this.name,
    this.level = 1,
    this.xp = 0,
    this.totalXpEarned = 0,
    this.age,
    this.gender,
    this.avatarBytes,
    this.bannerBytes,
    this.streakProtectionCharges = 1,
    this.streakProtectionRefilledAt,
    this.lastStreakProtectionUsedAt,
    this.lastStreakProtectionTaskTitle,
  });

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
