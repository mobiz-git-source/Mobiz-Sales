// Reports/sales_order_report.dart
import 'dart:ui' as ui;

import 'package:number_to_words/number_to_words.dart';

import '../Models/appstate.dart';
import '../Models/invoicedata.dart' as Invoice;
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

const String kOrderLogoBaseUrl = 'https://erpadmin.mobiz.ae/uploads/store/';

void drawSalesOrder(ImageReportBuilder b, Invoice.InvoiceData invoice,
    {ui.Image? logo}) {
  final d = invoice.data!;
  final store = d.store![0];
  final cust = d.customer![0];
  final dec = AppState().noOfDecimals ?? 2;
  String money(num? v) => (v ?? 0).toStringAsFixed(dec);

  final bool wide = b.widthDots >= 800;
  final double normal = wide ? 24 : 22;
  final double large = wide ? 32 : 28;

  // ---- 1. Logo + company header ----
  if (logo != null) b.image(logo, width: wide ? 300 : 248);

  final companyName = store.invoice_company_name ?? store.name ?? '';
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
    b.text('${store.vat_label ?? 'TRN'}: ${store.trn}',
        size: normal, align: PAlign.center);
  }

  b.divider();
  b.text('SALES ORDER', size: large - 2, bold: true, align: PAlign.center);
  b.divider();

  // ---- 2. Order info ----
  b.row([
    Col('Order No: ${d.invoiceNo ?? ''}', flex: 3),
    Col('Date: ${DateHelper.displayDate(d.inDate)}',
        flex: 2, align: PAlign.right),
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

  // ---- 3. Customer ----
  void labelValue(String label, String? value) {
    if (value == null || value.trim().isEmpty || value == 'null') return;
    b.row([Col(label, flex: 2), Col(value, flex: wide ? 9 : 5)], size: normal);
  }

  labelValue('Customer:', cust.name);
  labelValue('Address:', cust.address?.toString());
  labelValue('Contact No:', cust.contactNumber);
  labelValue('${store.vat_label ?? 'TRN'}:', cust.trn);
  b.divider();

  // ---- 4. Items ----
  final items = d.detail ?? [];
  if (wide) {
    b.row([
      Col('#', flex: 2),
      Col('Product', flex: 7),
      Col('Unit', flex: 2),
      Col('Qty', flex: 2, align: PAlign.right),
      Col('Rate', flex: 3, align: PAlign.right),
      Col(AppState().taxLabel, flex: 3, align: PAlign.right),
      Col('Amount', flex: 3, align: PAlign.right),
    ], size: normal - 2, bold: true);
    b.divider(thickness: 1, spacing: 2);
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      b.row([
        Col('${i + 1}', flex: 2),
        Col(it.name ?? '', flex: 7),
        Col(it.unit ?? '', flex: 2),
        Col('${it.quantity ?? 0}', flex: 2, align: PAlign.right),
        Col(money(it.mrp), flex: 3, align: PAlign.right),
        Col(money(it.taxAmt), flex: 3, align: PAlign.right),
        Col(money(it.amount), flex: 3, align: PAlign.right),
      ], size: normal - 2);
    }
  } else {
    b.row([Col('#', flex: 1), Col('Product', flex: 12)],
        size: normal, bold: true);
    b.row([
      Col('', flex: 1),
      Col('Qty', flex: 3, align: PAlign.right),
      Col('Rate', flex: 3, align: PAlign.right),
      Col(AppState().taxLabel, flex: 3, align: PAlign.right),
      Col('Amount', flex: 3, align: PAlign.right),
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
        Col('${it.quantity ?? 0} ${it.unit ?? ''}'.trim(),
            flex: 3, align: PAlign.right),
        Col(money(it.mrp), flex: 3, align: PAlign.right),
        Col(money(it.taxAmt), flex: 3, align: PAlign.right),
        Col(money(it.amount), flex: 3, align: PAlign.right),
      ], size: normal);
      b.feed(4);
    }
  }
  b.divider();

  // ---- 5. Totals ----
  final double total = (d.total ?? 0).toDouble();

  // Discount AMOUNT: discounted_amount undenkil athu, illenkil discount
  final double disc = d.effectiveDiscount.toDouble();

  final double subTotal = total - disc;
  final double roundOff = double.tryParse('${d.roundOff ?? 0}') ?? 0;
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
  if (roundOff != 0) {
    leftRight('', 'Round Off: ${money(roundOff)}');
  }
  leftRight('', 'Grand Total: ${money(d.grandTotal)}',
      bold: true, size: normal + 4);
  b.feed(48);

  // ---- 6. Amount in words ----
  final num amount = d.grandTotal ?? 0;
  final parts = amount.toStringAsFixed(dec).split('.');
  final whole = int.parse(parts[0]);
  final minor = dec > 0 && parts.length > 1 ? int.parse(parts[1]) : 0;

  var words = 'Amount in Words: ${AppState().code} '
      '${NumberToWord().convert('en-in', whole).toUpperCase()}';
  if (minor > 0) {
    words += ' AND ${NumberToWord().convert('en-in', minor).toUpperCase()} '
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