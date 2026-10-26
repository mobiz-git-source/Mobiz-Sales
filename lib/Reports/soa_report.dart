// Reports/soa_report.dart
//
// Statement of Accounts report, drawn once for every printer.
// Replaces _printZebraSOA() / _printSewooSOA() in SOA screen.

import 'dart:ui' as ui;
import '../Models/appstate.dart';
import '../Models/Store_model.dart';
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

const String kSoaStoreLogoBaseUrl = 'https://erpadmin.mobiz.ae/uploads/store/';
// If your Image_URL differs (RestDatasource().Image_URL), pass the built
// logo URL in from the caller instead — see _generateAndPrintSOA below.

void drawSoaReport(
  ImageReportBuilder b,
  StoreDetail store,
  List<List<dynamic>> data,
  double opening,
  double closing, {
  ui.Image? logo,
  String? customerCode,
  String? customerName,
  String? customerAddress,
  DateTime? fromDate,
  DateTime? toDate,
}) {
  final dec = AppState().noOfDecimals ?? 2;

  // ---- 1. Logo + company header ----
  if (logo != null) b.image(logo, width: 220);
  b.text(store.name, size: 30, bold: true, align: PAlign.center);
  if ((store.address ?? '').isNotEmpty) {
    b.text(store.address!, size: 22, align: PAlign.center);
  }
  if ((store.trn ?? '').isNotEmpty) {
    b.text('TRN: ${store.trn}', size: 22, align: PAlign.center);
  }
  b.divider();
  b.text('STATEMENT OF ACCOUNTS', size: 26, bold: true, align: PAlign.center);
  b.divider();

  // ---- 2. Customer + date range ----
  b.text('Customer: ${customerCode ?? ''} | ${customerName ?? ''}');
  if ((customerAddress ?? '').isNotEmpty) {
    b.text('Address: $customerAddress');
  }
  b.row([
    Col('From: ${fromDate != null ? DateHelper.displayFromDateTime(fromDate) : '-'}'),
    Col('To: ${toDate != null ? DateHelper.displayFromDateTime(toDate) : '-'}', align: PAlign.right),
  ]);
  b.divider();

  // ---- 3. Table header ----
  b.row([
    Col('Date', flex: 3),
    Col('Reference', flex: 4),
    Col('Debit', flex: 3, align: PAlign.right),
    Col('Credit', flex: 3, align: PAlign.right),
    Col('Balance', flex: 3, align: PAlign.right),
  ], bold: true);
  b.divider(thickness: 1, spacing: 2);

  // ---- 4. Opening balance ----
  b.row([
    Col('', flex: 10),
    Col('Opening Balance: ${opening.toStringAsFixed(dec)}', flex: 6, align: PAlign.right, bold: true),
  ]);

  // ---- 5. Transaction rows ----
  for (var row in data) {
    final date = DateHelper.displayDate(row[0]?.toString());
    final ref = row[1]?.toString() ?? '';
    final debit = row[2] != null ? double.parse(row[2].toString()).abs() : 0.0;
    final credit = row[3] != null ? double.parse(row[3].toString()).abs() : 0.0;
    final balance = row[4] != null ? double.parse(row[4].toString()) : 0.0;

    b.row([
      Col(date, flex: 3),
      Col(ref, flex: 4),
      Col(debit > 0 ? debit.toStringAsFixed(dec) : '', flex: 3, align: PAlign.right),
      Col(credit > 0 ? credit.toStringAsFixed(dec) : '', flex: 3, align: PAlign.right),
      Col(balance.toStringAsFixed(dec), flex: 3, align: PAlign.right),
    ]);
  }
  b.divider();

  // ---- 6. Closing balance ----
    // ---- 6. Closing balance ----
  b.row([
    Col('', flex: 10),
    Col('Closing Balance: ${closing.toStringAsFixed(dec)}', flex: 6, align: PAlign.right, bold: true),
  ], size: 26);
  b.feed(10);
  b.text('--- THANK YOU ---', align: PAlign.center);
  b.feed(30);
}