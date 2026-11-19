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

  test('lead mediaUrl (current API) becomes the attachment', () {
    final l = ExhibitionLead.fromJson({
      'id': 9,
      'schoolName': 'ABC',
      'mediaUrl': 'https://s3/lead-photo.jpg',
    });
    expect(l.attachments, ['https://s3/lead-photo.jpg']);
  });

  test('capture lead request sends mediaUrl; contact fields optional', () {
    const req = CaptureLeadRequest(
      schoolName: 'GV School',
      city: 'Chennai',
      attachments: ['https://s3/a.jpg'],
    );
    final json = req.toJson();
    expect(json['mediaUrl'], 'https://s3/a.jpg');
    expect(json['contactNumber'], '');
    expect(json['contactEmail'], '');
    expect(const CaptureLeadRequest(schoolName: 'X').toJson()['mediaUrl'], '');
  });

  test('demo detail recipients and voice template scope parse', () {
    final d = ExhibitionDemo.fromJson({
      'id': 51,
      'visitorName': 'Mr. Kumar',
      'recipients': [
        {'id': 120, 'mobile': '9811112222', 'recipientType': 'visitor',
         'recipientName': 'Mr. Kumar', 'callStatus': 'queued', 'error': null},
        {'id': 121, 'mobile': '9876543210', 'recipientType': 'team',
         'recipientName': 'Ravi', 'callStatus': 'failed', 'error': 'Busy'},
      ],
    });
    expect(d.recipients.length, 2);
    expect(d.recipients[1].isTeam, isTrue);
    expect(d.recipients[1].name, 'Ravi');
    expect(d.recipients[1].status, CallStatus.failed);
    expect(d.recipients[1].error, 'Busy');
    expect(d.recipients[0].error, '');

    final t = DemoTemplate.fromJson({'id': 1, 'exhibitionId': null, 'name': 'Intro',
        'audioUrl': 'https://x/a.wav', 'scope': 'common'});
    expect(t.title, 'Intro');
    expect(t.isCommon, isTrue);
    expect(DemoTemplate.fromJson({'id': 8, 'name': 'Offer', 'scope': 'exhibition'}).isCommon,
        isFalse);
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

  test('Initiate Again: list row takes the numbers from the demo detail', () {
    const row = ExhibitionDemo(
        id: '51', visitorName: 'Mr. Kumar', recipientCount: 2, audioUrl: 'https://x/a.wav');
    final detail = ExhibitionDemo.fromJson({
      'id': 51,
      'recipients': [
        {'mobile': '9811112222', 'recipientType': 'visitor'},
        {'mobile': '9876543210', 'recipientType': 'team'},
      ],
    });
    final m = row.mergedWith(detail);
    expect(m.visitorName, 'Mr. Kumar');
    expect(m.audioUrl, 'https://x/a.wav');
    expect(m.recipients.map((r) => r.number), ['9811112222', '9876543210']);
    expect(m.firstVisitorNumber, '9811112222');
  });
}
