import 'package:intl/intl.dart';
import '../Models/appstate.dart';

class DateHelper {
static String _convertPhpFormatToIcu(String format) {
  switch (format) {
    case 'd-M-Y':
      return 'dd-MMM-yyyy';

    case 'd/m/Y':
      return 'dd/MM/yyyy';

    case 'm/d/Y':
      return 'MM/dd/yyyy';

    case 'Y-m-d':
      return 'yyyy-MM-dd';

    default:
      return format
          .replaceAll(RegExp(r'(?<!y)Y(?!y)'), 'yyyy')
          .replaceAll(RegExp(r'(?<!y)y(?!y)'), 'yy')
          .replaceAll('F', 'MMMM')
          .replaceAll(RegExp(r'(?<!M)M(?!M)'), 'MMM')
          .replaceAll('m', 'MM')
          .replaceAll('n', 'M')
          .replaceAll(RegExp(r'(?<!d)d(?!d)'), 'dd')
          .replaceAll('j', 'd');
  }
}

static String displayDate(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) return '';

  DateTime? parsed;

  try {
    parsed = DateFormat('dd-MMM-yy').parseStrict(rawDate);
  } catch (_) {
    parsed = _tryParse(rawDate);
  }

  if (parsed == null) return rawDate;

  final phpFormat = AppState().dateFormat ?? 'd-M-Y';
  final icuFormat = _convertPhpFormatToIcu(phpFormat);

  return DateFormat(icuFormat).format(parsed);
}
 static String displayFromDateTime(DateTime date) {
  final phpFormat = AppState().dateFormat ?? 'd-M-Y';
  final icuFormat = _convertPhpFormatToIcu(phpFormat);

  try {
    return DateFormat(icuFormat).format(date);
  } catch (_) {
    return DateFormat('dd-MMM-yyyy').format(date);
  }
}

  static String apiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime? _tryParse(String rawDate) {
    try {
      return DateTime.parse(rawDate);
    } catch (_) {}

    const formats = [
  'dd-MM-yyyy',
  'dd-MMM-yyyy',
  'dd-MMM-yy', 
  'MM-dd-yyyy',
  'dd/MM/yyyy',
  'MM/dd/yyyy',
  'yyyy/MM/dd',
];
    for (final f in formats) {
      try {
        return DateFormat(f).parseStrict(rawDate);
      } catch (_) {}
    }
    return null;
  }
}