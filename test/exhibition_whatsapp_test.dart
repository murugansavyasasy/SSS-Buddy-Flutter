import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';
import 'package:sssbuddy/auth/model/ManagementVideosModel.dart';
import 'package:sssbuddy/components/open_in_browser.dart';

Managementvideosmodel _v(String name, String url) =>
    Managementvideosmodel(videoName: name, videoURL: url, videoType: 'youtube');

void main() {
  group('pickDemoVideoLinks', () {
    test('English, Tamil, Hindi, Kannada in that order, first match each', () {
      final links = pickDemoVideoLinks([
        _v('Parent App Hindi', 'https://youtu.be/hi'),
        _v('SSS Score - English', 'https://youtu.be/en'),
        _v('Product intro (Kanada)', 'https://youtu.be/kn'),
        _v('Management overview', 'https://youtu.be/x'),
        _v('TAMIL demo', 'https://youtu.be/ta'),
        _v('Tamil demo 2', 'https://youtu.be/ta2'),
      ]);
      expect(links.map((l) => l.label), ['English', 'Tamil', 'Hindi', 'Kannada']);
      expect(links.map((l) => l.url), [
        'https://youtu.be/en',
        'https://youtu.be/ta',
        'https://youtu.be/hi',
        'https://youtu.be/kn',
      ]);
    });

    test('missing languages and empty URLs are skipped', () {
      final links = pickDemoVideoLinks([
        _v('English', ''),
        _v('Hindi video', 'https://youtu.be/hi'),
      ]);
      expect(links, [(label: 'Hindi', url: 'https://youtu.be/hi')]);
      expect(pickDemoVideoLinks(const []), isEmpty);
    });

    test('fixed English link wins over Management Videos, others still picked', () {
      const en = 'https://www.youtube.com/watch?v=fzYarCgUUgw';
      final links = pickDemoVideoLinks([
        _v('SSS Score - English', 'https://youtu.be/en'),
        _v('TAMIL demo', 'https://youtu.be/ta'),
      ], fixed: {'English': en});
      expect(links, [(label: 'English', url: en), (label: 'Tamil', url: 'https://youtu.be/ta')]);
      // Videos didn't load: English is still sent.
      expect(pickDemoVideoLinks(const [], fixed: {'English': en}), [(label: 'English', url: en)]);
      // Empty fixed link falls back to Management Videos.
      expect(pickDemoVideoLinks([_v('English', 'https://youtu.be/en')], fixed: {'English': ''}).single.url,
          'https://youtu.be/en');
    });
  });

  group('demoVideoWhatsAppUri', () {
    test('Dear + name, exhibition and one line per language', () {
      final uri = demoVideoWhatsAppUri(
        number: '+91 98765 43210',
        videos: const [
          (label: 'Tamil', url: 'https://youtu.be/ta'),
          (label: 'English', url: 'https://youtu.be/en'),
        ],
        visitorName: 'Ravi',
        exhibitionName: 'Chennai Edu Expo',
      );
      expect(uri.scheme, 'whatsapp');
      expect(uri.host, 'send');
      expect(uri.queryParameters['phone'], '919876543210');
      expect(
        uri.queryParameters['text'],
        'Dear Ravi,Thank You for visiting us at Chennai Edu Expo.\n'
        'Watch our demo videos:\n'
        'Tamil: https://youtu.be/ta\n'
        'English: https://youtu.be/en',
      );
    });

    test('single fallback link without a name', () {
      final uri = demoVideoWhatsAppUri(
        number: '09876543210',
        videos: const [(label: '', url: ' https://youtu.be/abc ')],
      );
      expect(uri.queryParameters['phone'], '919876543210');
      expect(
        uri.queryParameters['text'],
        'Dear Sir/Madam,Thank You for visiting us.\nWatch our demo video: https://youtu.be/abc',
      );
    });

    test('encodes spaces as %20, not +', () {
      final uri = demoVideoWhatsAppUri(
        number: '9876543210',
        videos: const [(label: '', url: 'https://youtu.be/a')],
      );
      expect(uri.toString(), isNot(contains('+')));
      expect(uri.toString(), contains('%20'));
    });

    test('WhatsApp Web link when the app is not installed', () {
      final uri = demoVideoWhatsAppUri(
        number: '9876543210',
        videos: const [(label: '', url: 'https://youtu.be/a')],
        web: true,
      );
      expect(uri.scheme, 'https');
      expect(uri.host, 'web.whatsapp.com');
      expect(uri.path, '/send');
      expect(uri.queryParameters['phone'], '919876543210');
      expect(uri.queryParameters['text'], contains('https://youtu.be/a'));
    });
  });

  test('WhatsApp Web opens in Safari first on iOS, then Chrome, then default', () {
    final web = Uri.parse('https://web.whatsapp.com/send?phone=919876543210&text=Hi%20there');
    expect(browserCandidates(web, isIOS: true).map((u) => u.toString()), [
      'x-safari-https://web.whatsapp.com/send?phone=919876543210&text=Hi%20there',
      'googlechromes://web.whatsapp.com/send?phone=919876543210&text=Hi%20there',
      web.toString(),
    ]);
    expect(browserCandidates(web, isIOS: false), [web]);
  });
}
