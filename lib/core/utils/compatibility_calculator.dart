import '../../features/auth/models/user_profile.dart';

/// Calculates compatibility score (65% - 99%) between two users
class CompatibilityCalculator {
  static int calculate(UserProfile? userA, UserProfile userB) {
    if (userA == null) return 78;
    if (userA.uid == userB.uid) return 100;

    int score = 60;

    // 1. Interests Overlap (Up to 25 points)
    if (userA.interests.isNotEmpty && userB.interests.isNotEmpty) {
      final setA = userA.interests.map((e) => e.toLowerCase().trim()).toSet();
      final setB = userB.interests.map((e) => e.toLowerCase().trim()).toSet();
      final common = setA.intersection(setB);
      if (common.isNotEmpty) {
        score += (common.length * 8).clamp(0, 25);
      }
    } else {
      score += 10;
    }

    // 2. Relationship Goal Match (Up to 15 points)
    if (userA.relationshipGoal != null && userB.relationshipGoal != null) {
      if (userA.relationshipGoal == userB.relationshipGoal) {
        score += 15;
      } else {
        score += 5;
      }
    } else {
      score += 8;
    }

    // 3. Age Proximity (Up to 10 points)
    if (userA.birthDate != null && userB.birthDate != null) {
      final ageA = DateTime.now().year - userA.birthDate!.year;
      final ageB = DateTime.now().year - userB.birthDate!.year;
      final diff = (ageA - ageB).abs();
      if (diff <= 3) {
        score += 10;
      } else if (diff <= 7) {
        score += 6;
      } else {
        score += 2;
      }
    } else {
      score += 5;
    }

    // Hash adjustment for deterministic consistency
    final hashOffset = (userA.uid.hashCode ^ userB.uid.hashCode).abs() % 6;
    score += hashOffset;

    return score.clamp(65, 99);
  }
}
