import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';

void main() {
  group('demoVideoWhatsAppUri', () {
    const video = 'https://youtu.be/abc123';

    test('opens the visitor chat with +91 and the video link', () {
      final uri = demoVideoWhatsAppUri(
        number: '+91 98765 43210',
        videoUrl: video,
        visitorName: 'Ravi',
        exhibitionName: 'Chennai Edu Expo',
      );
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919876543210');
      expect(
        uri.queryParameters['text'],
        'Hi Ravi, thank you for visiting us at Chennai Edu Expo. Watch our demo video: $video',
      );
    });

    test('works without a visitor or exhibition name', () {
      final uri = demoVideoWhatsAppUri(number: '09876543210', videoUrl: ' $video ');
      expect(uri.path, '/919876543210');
      expect(uri.queryParameters['text'],
          'Hi, thank you for visiting us. Watch our demo video: $video');
    });

    test('encodes spaces as %20, not +', () {
      final uri = demoVideoWhatsAppUri(number: '9876543210', videoUrl: video);
      expect(uri.toString(), isNot(contains('+')));
      expect(uri.toString(), contains('%20'));
    });
  });
}
