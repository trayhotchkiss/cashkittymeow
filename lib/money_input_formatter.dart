import 'package:flutter/services.dart';

class MoneyInputFormatter extends TextInputFormatter {
  final bool allowNegative;

  MoneyInputFormatter({this.allowNegative = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final pattern = allowNegative
        ? RegExp(r'^-?\d*(?:\.\d{0,2})?$')
        : RegExp(r'^\d*(?:\.\d{0,2})?$');
    if (pattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
