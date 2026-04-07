import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../helpers/constants.dart';
import '../models/dingpay_config.dart';

class SsoService {
  static Future<String?> getSignature(DingPayConfig config) async {
    try {
      final url =
          '$ssoUrl?scheme=${config.callbackScheme}&apiKey=${config.apiKey}';

      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: config.callbackScheme,
      );

      final uri = Uri.parse(result);
      final status = uri.queryParameters['status'];

      if (status == 'ok') {
        return uri.queryParameters['signature'];
      }
    } catch (_) {}
    return null;
  }
}
