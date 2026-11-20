import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';

void main() {
  group('Interest level', () {
    test('capture lead sends the on-screen label to the API', () {
      for (final (level, expected) in [
        (InterestLevel.excellent, 'Excellent'),
        (InterestLevel.good, 'Good'),
        (InterestLevel.average, 'Average'),
      ]) {
        final body = CaptureLeadRequest(schoolName: 'School', interestLevel: level).toJson();
        expect(body['interestLevel'], expected);
      }
    });

    test('reads the labels in any case; anything else is no level', () {
      expect(parseInterestLevel('Excellent'), InterestLevel.excellent);
      expect(parseInterestLevel('good'), InterestLevel.good);
      expect(parseInterestLevel(' AVERAGE '), InterestLevel.average);
      expect(parseInterestLevel('hot'), isNull);
      expect(parseInterestLevel(''), isNull);
    });
  });
}
