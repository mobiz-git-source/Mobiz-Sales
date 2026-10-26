// Reports/sale_invoice_report.dart
//
// The sales invoice, drawn once for every printer (Sewoo and Zebra).
// Replaces _printZebra() and _printSewoo() in SaleInvoiceScrreen.
//
// - Arabic works everywhere: company name, customer name/address, product names.
// - On 4" paper (Sewoo, 832 dots) it uses the one-line table like your old Sewoo print.
// - On 3" paper (Zebra, 576 dots) it uses the two-line table like your old Zebra print.
// - Long text (names, addresses, amount in words) wraps by itself; no manual splitting.
//
// Adjust the import paths below if your folders differ.

import 'dart:ui' as ui;

import 'package:number_to_words/number_to_words.dart';

import '../Models/appstate.dart';
import '../Models/invoicedata.dart' as Invoice;
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

const String kStoreLogoBaseUrl = 'https://erpadmin.mobiz.ae/uploads/store/';

void drawSaleInvoice(ImageReportBuilder b, Invoice.InvoiceData invoice,
    {ui.Image? logo}) {
  final d = invoice.data!;
  final store = d.store![0];
  final cust = d.customer![0];
  final dec = AppState().noOfDecimals ?? 2;
  String money(num? v) => (v ?? 0).toStringAsFixed(dec);

  final bool wide = b.widthDots >= 800; // 4" paper
  final double normal = wide ? 24 : 22;
  final double large = wide ? 32 : 28;

  // ---- 1. Logo and company header ----
  if (logo != null) b.image(logo, width: wide ? 300 : 248);

  final companyName = store.invoice_company_name ?? '';
  if (companyName.isNotEmpty) {
    b.text(companyName, size: large, bold: true, align: PAlign.center);
  }
  final companyNameAr = store.name_ar ?? '';
  if (companyNameAr.trim().isNotEmpty) {
    b.text(companyNameAr, size: large - 2, bold: true, align: PAlign.center);
  }
  final companyAddress = store.address ?? '';
  if (companyAddress.isNotEmpty) {
    b.text(companyAddress, size: normal, align: PAlign.center);
  }
  final companyMail = store.email ?? '';
  if (companyMail.isNotEmpty) {
    b.text(companyMail, size: normal, align: PAlign.center);
  }
  if ((store.trn ?? '').isNotEmpty) {
    b.text('TRN: ${store.trn}', size: normal, align: PAlign.center);
  }

  b.divider();
  final heading = (store.invoice_heading ?? '').isNotEmpty
      ? store.invoice_heading!
      : 'TAX INVOICE';
  b.text(heading, size: large - 2, bold: true, align: PAlign.center);
  b.divider();

  // ---- 2. Invoice info ----
  b.row([
    Col('Invoice No: ${d.invoiceNo ?? ''}', flex: 3),
    Col('Date: ${DateHelper.displayDate(d.inDate)}', flex: 2, align: PAlign.right),
  ], size: normal);
  b.row([
    Col('', flex: 3),
    Col('Time: ${d.inTime ?? ''}', flex: 2, align: PAlign.right),
  ], size: normal);
  final remarks = d.remarks;
  if (remarks != null && remarks.toString().isNotEmpty) {
    b.text('Remarks: $remarks', size: normal);
  }
  b.feed(6);

  // ---- 3. Customer block (label and value in separate columns, so Arabic
  //         names and addresses shape and align correctly) ----
  void labelValue(String label, String? value) {
    if (value == null || value.trim().isEmpty || value == 'null') return;
    b.row([Col(label, flex: 2), Col(value, flex: wide ? 9 : 5)], size: normal);
  }

  labelValue('Customer:', cust.name);
  labelValue('Address:', cust.address);
  labelValue('Contact No:', cust.contactNumber);
  labelValue('${store.vat_label ?? 'TRN'}:', cust.trn);
  labelValue('Bill Type:', d.cashCard);
  b.divider();

  // ---- 4. Item table ----
  final items = d.detail ?? [];
  if (wide) {
    // One line per item (old Sewoo layout)
    b.row([
    Col('#', flex: 2),
Col('Product', flex: 7),
Col('', flex: 1),
Col('Unit', flex: 2),
      Col('Qty', flex: 2, align: PAlign.right),
      Col('Rate', flex: 3, align: PAlign.right),
      Col('Amount', flex: 3, align: PAlign.right),
     Col(AppState().taxLabel, flex: 3, align: PAlign.right),
      Col('Total', flex: 3, align: PAlign.right),
    ], size: normal - 2, bold: true);
    b.divider(thickness: 1, spacing: 2);
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      b.row([
       Col('${i + 1}', flex: 2),
Col(it.name ?? '', flex: 7),
Col('', flex: 1),
Col(it.unit ?? '', flex: 2),
        Col('${it.quantity ?? 0}', flex: 2, align: PAlign.right),
        Col(money(it.mrp), flex: 3, align: PAlign.right),
        Col(money(it.taxable), flex: 3, align: PAlign.right),
        Col(money(it.taxAmt), flex: 3, align: PAlign.right),
        Col(money(it.amount), flex: 3, align: PAlign.right),
      ], size: normal - 2);
    }
  } else {
    // Two lines per item (old Zebra layout): name, then code / qty / rate / total
    b.row([Col('#', flex: 1), Col('Product', flex: 12)], size: normal, bold: true);
    b.row([
      Col('', flex: 1),
      Col('Code', flex: 3),
      Col('Qty', flex: 3, align: PAlign.right),
      Col('Rate', flex: 3, align: PAlign.right),
      Col('Total', flex: 3, align: PAlign.right),
    ], size: normal, bold: true);
    b.divider(thickness: 1, spacing: 2);
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      b.row([
        Col('${i + 1}', flex: 1),
        Col((it.name ?? '').toUpperCase(), flex: 12),
      ], size: normal, bold: true);
      b.row([
        Col('', flex: 1),
        Col(it.code ?? '', flex: 3),
        Col('${it.quantity ?? 0} ${it.unit ?? ''}'.trim(), flex: 3, align: PAlign.right),
        Col(money(it.mrp), flex: 3, align: PAlign.right),
        Col(money(it.amount), flex: 3, align: PAlign.right),
      ], size: normal);
      b.feed(4);
    }
  }
  b.divider();

  // ---- 5. Totals ----
  final double total = (d.total ?? 0).toDouble();
   final double disc = d.effectiveDiscount.toDouble();
  final double subTotal = total - disc;
  final van = d.van?.firstOrNull?.name ?? 'N/A';
  final salesman = d.user?.firstOrNull?.name ?? 'N/A';

  void leftRight(String left, String right, {bool bold = false, double? size}) {
    b.row([Col(left, flex: 3), Col(right, flex: 2, align: PAlign.right)],
        size: size ?? normal, bold: bold);
  }

  leftRight('Van: $van', 'Total: ${money(total)}');
   leftRight('Salesman: $salesman',
      disc > 0 ? '${d.discountLabel}: ${money(disc)}' : '');
  leftRight('', 'Sub Total: ${money(subTotal)}');
leftRight('', '${AppState().taxLabel}: ${money(d.totalTax)}');
  leftRight('', 'Grand Total: ${money(d.grandTotal)}', bold: true, size: normal + 4);
   b.feed(48);// one blank line, same height as a text line

  // ---- 6. Amount in words and footer ----
 final num amount = d.grandTotal ?? 0;
final amountParts = amount.toStringAsFixed(dec).split('.');
final wholePart = int.parse(amountParts[0]);
final minorPart =
    dec > 0 && amountParts.length > 1 ? int.parse(amountParts[1]) : 0;

var words = 'Amount in Words: ${AppState().code} '
    '${NumberToWord().convert('en-in', wholePart).toUpperCase()}';

if (minorPart > 0) {
  words += ' AND ${NumberToWord().convert('en-in', minorPart).toUpperCase()} '
      '${AppState().minor}';
}
  words += ' ONLY';
  b.text(words, size: normal);

  final footer = store.invoice_footer ?? '';
  if (footer.trim().isNotEmpty) {
    b.feed(6);
    b.text(footer, size: normal - 2, align: PAlign.center);
  }
  b.feed(30);
}

// ---------------------------------------------------------------------------
// In SaleInvoiceScrreen (_SaleInvoiceScrreenState), replace _print() with this.
// _printZebra() and _printSewoo() are then no longer called and can be deleted
// once you're happy with the new prints.
//
// Add imports at the top of the screen:
//   import '../Utilities/report_printer.dart';
//   import '../Reports/sale_invoice_report.dart';
// ---------------------------------------------------------------------------
//
// Future<void> _print(Invoice.InvoiceData invoice, bool isPrint) async {
//   if (!_connected) await _connect();
//   if (!_connected) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Printer not connected')),
//     );
//     return;
//   }
//
//   try {
//     final logoFile = invoice.data?.store?.firstOrNull?.logo;
//     final logo = (logoFile != null && logoFile.isNotEmpty)
//         ? await loadLogo('$kStoreLogoBaseUrl$logoFile')
//         : null;
//
//     await printReport(printer, _selectedDevice,
//         (b) => drawSaleInvoice(b, invoice, logo: logo));
//   } catch (e, st) {
//     print('Print error: $e\n$st');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Print failed: $e')),
//       );
//     }
//   }
// }
