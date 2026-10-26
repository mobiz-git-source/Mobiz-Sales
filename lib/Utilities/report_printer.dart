// Utilities/report_printer.dart
//
// One call to print any report on either printer, reusing what you already have
// in cpcl_helper.dart (isZebraPrinter, sendCpcl, kLabelWidthDots).
//
// Put this file and image_report_printer.dart in the same Utilities folder.
//
// Example - converting a report:
//
//   final logo = await loadLogo(companyLogoUrl);      // cached after first load
//
//   await printReport(printer, selectedDevice, (b) {
//     if (logo != null) b.image(logo, width: 248);
//     b.text('شركة المثال للتجارة', size: 30, bold: true, align: PAlign.center);
//     b.text('TAX INVOICE', size: 26, bold: true, align: PAlign.center);
//     b.divider();
//     b.row([Col('Invoice No'), Col(inv.number, align: PAlign.right)]);
//     b.row([Col('Date'), Col(inv.date, align: PAlign.right)]);
//     b.row([Col('Customer'), Col(inv.customerName, flex: 2, align: PAlign.right)]);
//     b.divider(dashed: true);
//     b.row([Col('Item', flex: 3), Col('Qty', align: PAlign.center),
//            Col('Amount', flex: 2, align: PAlign.right)], bold: true);
//     for (final it in inv.items) {
//       b.row([Col(it.name, flex: 3), Col('${it.qty}', align: PAlign.center),
//              Col(it.amount.toStringAsFixed(2), flex: 2, align: PAlign.right)]);
//     }
//     b.divider();
//     b.row([Col('الإجمالي / Total', flex: 3, bold: true),
//            Col(inv.total.toStringAsFixed(2), flex: 2, align: PAlign.right, bold: true)]);
//     b.qrcode(inv.qrData, size: 200);
//     b.feed(20);
//   });
//
// Mapping from your current CpclBuilder:
//   text(...) / boldText(...)   ->  b.text(..., bold: true/false)
//   centerText(...)             ->  b.text(..., align: PAlign.center)
//   twoColumn(left, right)      ->  b.row([Col(left), Col(right, align: PAlign.right)])
//   hLine()                     ->  b.divider()
//   feed(dots)                  ->  b.feed(dots)
//   addLogo(...)                ->  b.image(await loadLogo(url))

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:http/http.dart' as http;

import 'cpcl_helper.dart';
import 'image_report_printer.dart';

export 'image_report_printer.dart' show ImageReportBuilder, Col, PAlign;

/// Font family registered in pubspec.yaml with Arabic glyphs
/// (the same one your invoice screen already uses).
const String? kReportFontFamily = 'NotoNaskhArabic';

/// Printable width of the Sewoo LK-P41 (4" printer) in dots.
/// Your current Sewoo layout fits ~70 characters per line, which matches 832.
/// The Zebra uses kLabelWidthDots (576) from cpcl_helper.dart for 3" paper.
const int kZebraWidthDots = 832;
const int kSewooWidthDots = 832;
const int kReportMarginDots = 20;

/// Draws the report once and prints it on whichever printer is connected.
/// Reports can check b.widthDots to use a wider layout on 4" paper.
Future<void> printReport(
  BlueThermalPrinter printer,
  BluetoothDevice? device,
  void Function(ImageReportBuilder b) draw, {
 int? widthDots,
int copies = 1,
int marginDots = kReportMarginDots,
}) async {
  final connected = await printer.isConnected;
  if (connected != true) {
    throw Exception('Printer not connected via Bluetooth');
  }

  final zebra = isZebraPrinter(device);
 final width = widthDots ?? (zebra ? kZebraWidthDots : kSewooWidthDots);

 final b = ImageReportBuilder(
  widthDots: width,
  fontFamily: kReportFontFamily,
  marginDots: marginDots,
);
  draw(b);
  final bytes = await b.buildFor(zebra ? PrinterType.zebraCpcl : PrinterType.escPos);

  for (int i = 0; i < copies; i++) {
    if (zebra) {
      // Paced sender (chunk size and delay are set in cpcl_helper.dart).
      await sendCpcl(printer, bytes);
      if (i < copies - 1) {
        await Future.delayed(const Duration(seconds: 2)); // gap between copies
      }
    } else {
      await sendInChunks((chunk) async {
        await printer.writeBytes(chunk);
      }, bytes);
    }
  }
}

final Map<String, ui.Image> _logoCache = {};

/// Downloads a logo once per app session and keeps it for later prints.
Future<ui.Image?> loadLogo(String url) async {
  if (url.isEmpty) return null;
  final cached = _logoCache[url];
  if (cached != null) return cached;
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(response.bodyBytes));
    final frame = await codec.getNextFrame();
    _logoCache[url] = frame.image;
    return frame.image;
  } catch (e) {
    print('Logo load error: $e');
    return null;
  }
}
