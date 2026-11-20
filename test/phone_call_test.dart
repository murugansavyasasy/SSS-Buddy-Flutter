import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/components/phone_call.dart';

/// Rapid taps on a phone number open the dialer only once (no stacked
/// "Call …?" popups).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('second tap while busy / within cooldown is ignored', () async {
    var launches = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        if (call.method == 'launch' || call.method == 'launchUrl') launches++;
        return true;
      },
    );
    final first = PhoneCall.dial('9876543210');
    final second = PhoneCall.dial('9876543210'); // tapped again immediately
    expect(await second, isFalse);
    await first;
    expect(await PhoneCall.dial('9876543210'), isFalse); // still in cooldown
    expect(launches, lessThanOrEqualTo(1));
  });
}
