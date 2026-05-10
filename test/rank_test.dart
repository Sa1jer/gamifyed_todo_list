import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/utils.dart';

void main() {
  group('profile ranks', () {
    test('map levels to expected profile rank tiers', () {
      expect(profileRankForLevel(1).label, 'E-rank');
      expect(profileRankForLevel(3).label, 'D-rank');
      expect(profileRankForLevel(5).label, 'C-rank');
      expect(profileRankForLevel(7).label, 'B-rank');
      expect(profileRankForLevel(9).label, 'A-rank');
      expect(profileRankForLevel(11).label, 'S-rank');
    });

    test('expose next profile rank correctly', () {
      expect(nextProfileRankForLevel(1)?.label, 'D-rank');
      expect(nextProfileRankForLevel(8)?.label, 'A-rank');
      expect(nextProfileRankForLevel(11), isNull);
    });
  });

  group('skill ranks', () {
    test('map levels to expected skill rank tiers', () {
      expect(skillRankForLevel(1).label, 'Новичок');
      expect(skillRankForLevel(3).label, 'Ученик');
      expect(skillRankForLevel(5).label, 'Практик');
      expect(skillRankForLevel(7).label, 'Специалист');
      expect(skillRankForLevel(9).label, 'Мастер');
      expect(skillRankForLevel(11).label, 'Легенда');
    });

    test('expose next skill rank correctly', () {
      expect(nextSkillRankForLevel(2)?.label, 'Ученик');
      expect(nextSkillRankForLevel(8)?.label, 'Мастер');
      expect(nextSkillRankForLevel(11), isNull);
    });
  });
}
