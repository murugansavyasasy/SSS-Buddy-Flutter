import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';

void main() {
  group('ExhibitionDemo.matches', () {
    const demo = ExhibitionDemo(
      id: 'd1',
      visitorName: 'Ravi Kumar',
      createdBy: 'Murugan',
      recipients: [DemoRecipient(number: '9876543210', isTeam: false, name: 'Principal')],
    );

    test('empty query matches', () => expect(demo.matches(''), isTrue));
    test('visitor name, case-insensitive', () => expect(demo.matches('ravi'), isTrue));
    test('every word must match', () {
      expect(demo.matches('ravi murugan'), isTrue);
      expect(demo.matches('ravi suresh'), isFalse);
    });
    test('number, with +91 or dashes', () {
      expect(demo.matches('98765'), isTrue);
      expect(demo.matches('+919876543210'), isTrue);
      expect(demo.matches('98765-43210'), isTrue);
    });
  });

  group('ExhibitionLead.matches', () {
    const lead = ExhibitionLead(
      id: 'l1',
      schoolName: 'St. Mary School',
      city: 'Chennai',
      contactName: 'Anitha',
      contactNumber: '9123456780',
    );

    test('school / city / contact', () {
      expect(lead.matches('mary'), isTrue);
      expect(lead.matches('CHENNAI'), isTrue);
      expect(lead.matches('anitha chennai'), isTrue);
      expect(lead.matches('madurai'), isFalse);
    });
    test('number', () => expect(lead.matches('3456'), isTrue));
  });
}
