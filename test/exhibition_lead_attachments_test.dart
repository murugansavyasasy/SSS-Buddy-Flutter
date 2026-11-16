import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';

void main() {
  test('lead attachments parse from strings or objects', () {
    final a = ExhibitionLead.fromJson({
      'id': '1',
      'schoolName': 'GV School',
      'attachments': ['https://s3/a.jpg', '', {'url': 'https://s3/b.pdf'}],
    });
    expect(a.attachments, ['https://s3/a.jpg', 'https://s3/b.pdf']);

    final b = ExhibitionLead.fromJson({'id': '2', 'schoolName': 'X'});
    expect(b.attachments, isEmpty);
  });

  test('capture lead request sends attachments; contact fields optional', () {
    const req = CaptureLeadRequest(
      schoolName: 'GV School',
      city: 'Chennai',
      attachments: ['https://s3/a.jpg'],
    );
    final json = req.toJson();
    expect(json['attachments'], ['https://s3/a.jpg']);
    expect(json['contactNumber'], '');
    expect(json['contactEmail'], '');
  });
}
