import 'dart:developer';

import 'package:dingpay_flutter/dingpay_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

const config = DingPayConfig(
  apiKey: '-Oh0NXXHUamk8V7Iv9nr',
  callbackScheme: 'com.dingpaytestapp.app',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DingPay Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A1A1A)),
      ),
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

  void _handlePay() {
    final amount = num.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    FocusScope.of(context).unfocus();

    DingPay.pay(
      context,
      config: config,
      options: PayOptions(
        amount: amount,
        metadata: {'orderId': 'order_12345'},
        onSuccess: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment successful')));
          _amountController.clear();
        },
        onFailure: (message) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Payment failed: $message')));
        },
        onCancel: () {
          log('User cancelled');
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
                'Chowdeck',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is any random app. It could be Chowdeck, Uber Nigeria, Bolt etc.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Enter amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handlePay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Pay NGN ${_amountController.text.isNotEmpty ? num.tryParse(_amountController.text) ?? 0 : 0}',
                    style: const TextStyle(
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
