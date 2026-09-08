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
