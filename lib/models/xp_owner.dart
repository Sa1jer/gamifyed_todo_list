import '../utils.dart';

mixin XPOwner {
  int get level;
  set level(int v);
  int get xp;
  set xp(int v);

  int get xpNeeded => xpForLevel(level);
  double get progress => (xp / xpNeeded).clamp(0.0, 1.0);

  int addXP(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Use removeXP for negative XP',
      );
    }
    if (amount == 0) return 0;

    xp += amount;
    int gained = 0;
    while (xp >= xpNeeded) {
      xp -= xpForLevel(level);
      level++;
      gained++;
    }
    return gained;
  }

  void removeXP(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Use addXP');
    }
    xp -= amount;
    while (xp < 0 && level > 1) {
      level--;
      xp += xpForLevel(level);
    }
    if (xp < 0) xp = 0;
  }
}
