# dingpay_flutter

Accept payments in your Flutter app with DingPay. Users set up once in the Ding Wallet app, then pay anywhere with one tap. Secured with biometric authentication (Face ID / Touch ID / Fingerprint).

## How it works

1. User enables "In-App Checkout" in their Ding Wallet app
2. Your app calls `DingPay.pay()` with an amount
3. DingPay shows a bottom sheet with the user's saved payment methods (cards, bank accounts, wallet)
4. User taps Pay, confirms with Face ID or fingerprint
5. Your app receives a success or failure callback

No sign-up flow. No card entry. No OTP. The user's payment methods are already in their Ding Wallet.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dingpay_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Platform setup

DingPay uses a callback scheme to complete authentication. Choose a unique scheme for your app and configure it on both platforms.

#### iOS

Add your callback scheme and Face ID usage description to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourapp.dingpay</string>
        </array>
    </dict>
</array>

<key>NSFaceIDUsageDescription</key>
<string>Confirm your payment</string>
```

#### Android
Update your `MainActivity` to extend `FlutterFragmentActivity`. In `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
```



Add the callback activity for `flutter_web_auth_2` to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<activity
    android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
    android:exported="true">
    <intent-filter android:label="flutter_web_auth_2">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="com.yourapp.dingpay" />
    </intent-filter>
</activity>
```

Replace `com.yourapp.dingpay` with your own unique scheme on both platforms.

## Quick start

```dart
import 'package:dingpay_flutter/dingpay_flutter.dart';

final config = DingPayConfig(
  apiKey: 'your_merchant_api_key',
  callbackScheme: 'com.yourapp.dingpay',
);

DingPay.pay(
  context,
  config: config,
  options: PayOptions(
    amount: 5000,
    onSuccess: () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful')),
      );
    },
    onFailure: (message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $message')),
      );
    },
  ),
);
```

## API

### `DingPay.pay()`

Opens the DingPay payment sheet.

```dart
static Future<void> pay(
  BuildContext context, {
  required DingPayConfig config,
  required PayOptions options,
})
```

### `DingPayConfig`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `apiKey` | `String` | Yes | Your merchant API key from the DingPay dashboard |
| `callbackScheme` | `String` | Yes | A unique URL scheme for your app (must match the scheme in `Info.plist` and `AndroidManifest.xml`) |

### `PayOptions`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `amount` | `num` | Yes | Amount in Naira (e.g. `5000` for N5,000) |
| `metadata` | `Map<String, dynamic>?` | No | Additional data to attach to the transaction |
| `onSuccess` | `VoidCallback?` | No | Called when payment succeeds |
| `onFailure` | `void Function(String)?` | No | Called when payment fails, with an error message |
| `onCancel` | `VoidCallback?` | No | Called when the user dismisses the payment sheet |

### `DingPay.clearSession()`

Clears the locally cached session. Call this when the user logs out of your app.

```dart
await DingPay.clearSession();
```

## Full example

```dart
import 'package:flutter/material.dart';
import 'package:dingpay_flutter/dingpay_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CheckoutScreen(),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _amountController = TextEditingController();

  static const _config = DingPayConfig(
    apiKey: 'pk_live_xxxxxxxxxxxx',
    callbackScheme: 'com.myapp.dingpay',
  );

  void _handlePay() {
    final amount = num.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    DingPay.pay(
      context,
      config: _config,
      options: PayOptions(
        amount: amount,
        metadata: {
          'orderId': 'order_12345',
          'customerEmail': 'customer@example.com',
        },
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful')),
          );
          _amountController.clear();
        },
        onFailure: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: $message')),
          );
        },
        onCancel: () {
          print('User cancelled');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Checkout',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (NGN)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handlePay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: const Text(
                    'Pay with DingPay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
```

## Security

DingPay is built with multiple layers of security:

- **Biometric authentication**: Every payment requires Face ID, Touch ID, or fingerprint confirmation before processing.
- **One-time sessions**: Each checkout page creates a unique session that is burned after a single use. Intercepted session IDs cannot be replayed.
- **Server-side rendering**: Payment assets and charge logic are handled entirely on the server. No sensitive data (card details, authorization codes) is ever exposed to the client.
- **Encrypted signatures**: The user's payment session is encrypted and validated server-side on every request.
- **API key validation**: Every SSO and checkout request is validated against your merchant API key.
- **No card entry**: Users never enter card details in your app. Payment methods are managed securely in the Ding Wallet app.

## Payment methods supported

- **Cards**: Visa, Mastercard, Verve cards saved in Ding Wallet
- **Bank accounts**: Direct debit mandates from Nigerian banks
- **Wallet**: Ding Wallet balance

## Requirements

- Flutter 3.0+
- iOS 12+ / Android 5+
- User must have the Ding Wallet app with "In-App Checkout" enabled

## Troubleshooting

### "In-app payments not enabled"
The user has not set up In-App Checkout in their Ding Wallet app. They need to open Ding Wallet and enable it in settings.

### "Session expired. Please try again."
The cached session was invalidated. The SDK automatically clears it. The next payment attempt will re-authenticate.

### Biometric prompt not showing
On iOS, ensure `NSFaceIDUsageDescription` is set in `Info.plist`. On devices without biometrics, payment proceeds without the prompt.

### Android: SSO redirect not working
Ensure you added the `CallbackActivity` with your scheme to `AndroidManifest.xml` inside the `<application>` tag (not inside the main `<activity>`).

### iOS: SSO redirect not working
Ensure you added your `callbackScheme` to the `CFBundleURLSchemes` array in `Info.plist`. The scheme must exactly match the `callbackScheme` passed to `DingPayConfig`.

## License

MIT
