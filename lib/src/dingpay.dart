import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'helpers/constants.dart';
import 'models/dingpay_config.dart';
import 'models/pay_options.dart';
import 'services/biometrics_service.dart';
import 'services/session_service.dart';
import 'services/sso_service.dart';

class DingPay {
  static Future<void> pay(
    BuildContext context, {
    required DingPayConfig config,
    required PayOptions options,
  }) async {
    String? signature = await SessionService.getSignature();

    if (signature == null) {
      signature = await SsoService.getSignature(config);
      if (signature == null) {
        options.onFailure?.call(
          'In-app payments not enabled. Set it up in your Ding Wallet app.',
        );
        return;
      }
      await SessionService.saveSignature(signature);
    }

    if (!context.mounted) return;

    final params = {
      'signature': signature,
      'apiKey': config.apiKey,
      'amount': options.amount.toString(),
      if (options.metadata != null) 'metadata': jsonEncode(options.metadata),
    };

    final uri = Uri.parse(checkoutUrl).replace(queryParameters: params);

    _showCheckoutSheet(
      context,
      url: uri.toString(),
      config: config,
      options: options,
    );
  }

  static Future<void> clearSession() async {
    await SessionService.clearSession();
  }

  static String _lastResponse = "";

  static void _showCheckoutSheet(
    BuildContext context, {
    required String url,
    required DingPayConfig config,
    required PayOptions options,
  }) {
    double sheetHeight = 400;
    bool isLoading = true;
    _lastResponse = "";
    late WebViewController webViewController;
    late StateSetter setSheetState;

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF9F9F9))
      ..addJavaScriptChannel(
        'DingPay',
        onMessageReceived: (message) {
          try {
            final data = jsonDecode(message.message);
            final type = data['type'];

            if (_lastResponse == message.message) {
              return;
            }
            _lastResponse = message.message;

            switch (type) {
              case 'resize':
                final height = data['height'];
                if (height is num) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final target = (height + 20).clamp(0.0, screenHeight * 0.85);
                  setSheetState(() {
                    sheetHeight = target.toDouble();
                  });
                }
                break;

              case 'auth_request':
                _handleBiometricAuth(webViewController);
                break;

              case 'error':
                Navigator.pop(context);
                if (data['archived'] == true) {
                  SessionService.clearSession();
                  options.onFailure?.call('Session expired. Please try again.');
                } else {
                  options.onFailure?.call(data['message'] ?? 'Payment error');
                }
                break;

              case 'close':
                Navigator.pop(context);
                options.onCancel?.call();
                break;

              case 'result':
                Navigator.pop(context);
                if (data['status'] == 'success') {
                  options.onSuccess?.call();
                } else if (data['status'] == 'archived') {
                  SessionService.clearSession();
                  options.onFailure?.call('Session expired. Please try again.');
                } else {
                  options.onFailure?.call(data['message'] ?? 'Payment failed');
                }
                break;
            }
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setSheetState(() {
              isLoading = true;
            });
          },
          onPageFinished: (_) {
            setSheetState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            setSheetState = setState;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: sheetHeight,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  WebViewWidget(controller: webViewController),
                  if (isLoading)
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A1A1A),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _handleBiometricAuth(WebViewController controller) async {
    print("received auth request");
    final success = await BiometricsService.authenticate();
    if (success) {
      await controller.runJavaScript('completePayment()');
    } else {
      await controller.runJavaScript('cancelPayment()');
    }
  }
}
