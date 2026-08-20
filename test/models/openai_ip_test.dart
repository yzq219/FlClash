import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cloudflare trace OpenAI egress response', () {
    test('parses IPv4 and normalizes the country code', () {
      expect(
        IpInfo.fromCloudflareTrace(
          'fl=123\nh=chatgpt.com\nip=203.0.113.8\nloc=us\ntls=TLSv1.3\n',
        ),
        const IpInfo(ip: '203.0.113.8', countryCode: 'US'),
      );
    });

    test('parses IPv6', () {
      expect(
        IpInfo.fromCloudflareTrace('ip=2001:db8::1\nloc=JP\n'),
        const IpInfo(ip: '2001:db8::1', countryCode: 'JP'),
      );
    });

    test('rejects invalid or incomplete responses', () {
      expect(
        () => IpInfo.fromCloudflareTrace('ip=invalid\nloc=US\n'),
        throwsFormatException,
      );
      expect(
        () => IpInfo.fromCloudflareTrace('ip=1.1.1.1\n'),
        throwsFormatException,
      );
    });
  });
}
