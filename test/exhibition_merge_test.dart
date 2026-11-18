import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';

void main() {
  test('edit form data: detail fields win, list row fills the gaps', () {
    final listRow = Exhibition.fromJson({
      'id': 3, 'name': 'DIDAC India 2027', 'venue': 'Bombay Exhibition Centre',
      'city': 'Mumbai', 'startDate': '2027-09-10', 'endDate': '2027-09-12',
      'status': 'completed', 'attendeeCount': 2, 'demoCount': 12, 'leadCount': 5,
      'createdAt': '2026-11-11T10:00:00.000Z',
    });
    final detail = Exhibition.fromJson({
      'id': 3, 'name': 'DIDAC India 2027', 'city': '', 'status': 'completed',
      'notes': 'Hall 3, Stall 42',
      'attendees': [
        {'id': 11, 'name': 'Ravi', 'mobile': '9876543210'},
        {'id': 12, 'name': 'Priya', 'mobile': '9876500000'},
      ],
    });
    final ex = detail.mergedWith(listRow);
    expect(ex.venue, 'Bombay Exhibition Centre');
    expect(ex.city, 'Mumbai');
    expect(ex.startDate, isNotNull);
    expect(ex.endDate, isNotNull);
    expect(ex.notes, 'Hall 3, Stall 42');
    expect(ex.attendees.map((a) => a.name), ['Ravi', 'Priya']);
    expect(ex.status, ExhibitionStatus.completed);
    expect(ex.leadCount, 5);
  });
}
