import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/deeplink/app_deep_link.dart';
import 'package:musamimuk/routes/app_routes.dart';

void main() {
  const parser = AppDeepLinkParser();

  test('parses contest detail https link', () {
    final link = parser.parse(
      Uri.parse('https://srv1813447.hstgr.cloud/contest/42'),
    );
    expect(link, isNotNull);
    expect(link!.target, AppDeepLinkTarget.contestDetail);
    expect(link.contestId, 42);
    expect(link.routeName, AppRoutes.screenContesttwoScreen);
  });

  test('parses contest submission share path into feed', () {
    final link = parser.parse(
      Uri.parse(
        'https://srv1813447.hstgr.cloud/contest/7/submission/99',
      ),
    );
    expect(link!.target, AppDeepLinkTarget.contestFeed);
    expect(link.contestId, 7);
    expect(link.submissionId, 99);
  });

  test('parses short share links', () {
    final link = parser.parse(
      Uri.parse('https://srv1813447.hstgr.cloud/share/15'),
    );
    expect(link!.target, AppDeepLinkTarget.contestFeed);
    expect(link.submissionId, 15);
  });

  test('parses custom scheme module links', () {
    final link = parser.parse(Uri.parse('musamimuk://online-designs'));
    expect(link!.target, AppDeepLinkTarget.onlineDesigns);
    expect(link.routeName, AppRoutes.screen16OnlineDesignsScreen);
  });

  test('parses design open-by-id https and custom scheme links', () {
    final httpsLink = parser.parse(
      Uri.parse('https://srv1813447.hstgr.cloud/open/design/77'),
    );
    expect(httpsLink!.target, AppDeepLinkTarget.openDesign);
    expect(httpsLink.designId, 77);
    expect(httpsLink.routeName, AppRoutes.openDesignDeepLinkScreen);

    final shortLink = parser.parse(
      Uri.parse('https://srv1813447.hstgr.cloud/design/88'),
    );
    expect(shortLink!.target, AppDeepLinkTarget.openDesign);
    expect(shortLink.designId, 88);

    final custom = parser.parse(Uri.parse('musamimuk://design/91'));
    expect(custom!.target, AppDeepLinkTarget.openDesign);
    expect(custom.designId, 91);
  });

  test('plural designs path still opens my designs', () {
    final link = parser.parse(
      Uri.parse('https://srv1813447.hstgr.cloud/open/my-designs'),
    );
    expect(link!.target, AppDeepLinkTarget.myDesigns);
  });

  test('parses open-prefixed module paths', () {
    final link = parser.parse(
      Uri.parse('https://srv1813447.hstgr.cloud/open/remove-background'),
    );
    expect(link!.target, AppDeepLinkTarget.removeBackground);
  });

  test('ignores unknown https hosts', () {
    final link = parser.parse(Uri.parse('https://evil.example/contest/1'));
    expect(link, isNull);
  });
}
