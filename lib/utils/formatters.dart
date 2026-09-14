import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatRupiah(num value) {
  return _currencyFormatter.format(value);
}

final _dateFormatter = DateFormat('d MMM yyyy', 'id_ID');
final _dateFormatterFull = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

String formatDate(DateTime date) {
  return _dateFormatter.format(date);
}

String formatDateFull(DateTime date) {
  return _dateFormatterFull.format(date);
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(cleanText);
    final formatter = NumberFormat.decimalPattern('id_ID');
    String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}