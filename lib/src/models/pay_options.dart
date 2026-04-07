import 'package:flutter/foundation.dart';

class PayOptions {
  final num amount;
  final Map<String, dynamic>? metadata;
  final VoidCallback? onSuccess;
  final void Function(String message)? onFailure;
  final VoidCallback? onCancel;

  const PayOptions({
    required this.amount,
    this.metadata,
    this.onSuccess,
    this.onFailure,
    this.onCancel,
  });
}
