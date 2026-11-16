import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';
import 'package:sssbuddy/core/aws/s3_upload_service.dart';

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

  test('S3 names are score_<timestamp> with the file\'s own type', () {
    expect(S3UploadService.scoreFileName('/tmp/a/exhibition_demo_1.m4a'),
        matches(RegExp(r'^score_\d+\.m4a$')));
    expect(S3UploadService.scoreFileName('/tmp/IMG_1.HEIC'), matches(RegExp(r'^score_\d+\.heic$')));
    expect(S3UploadService.scoreFileName('/tmp/noext'), matches(RegExp(r'^score_\d+$')));
    expect(S3UploadService.contentTypeFor('x.wav'), 'audio/wav');
    expect(S3UploadService.contentTypeFor('x.pdf'), 'application/pdf');
    expect(S3UploadService.contentTypeFor('x.jpeg'), 'image/jpeg');
    expect(S3UploadService.contentTypeFor('x.bin'), 'application/octet-stream');
  });
}
