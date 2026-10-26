import 'dart:ui' as ui;

import 'package:number_to_words/number_to_words.dart';

import '../Models/appstate.dart';
import '../Models/invoicedata.dart' as Invoice;
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

const String kHomeReturnLogoBaseUrl =
    'https://erpadmin.mobiz.ae/uploads/store/';

void drawHomeReturnReport(
  ImageReportBuilder b,
  Invoice.InvoiceData invoice, {
  ui.Image? logo,
}) {
  final data = invoice.data;
  if (data == null) {
    throw StateError('Home return invoice data is missing.');
  }
  if (data.store == null || data.store!.isEmpty) {
    throw StateError('Store details are missing from the home return.');
  }
  if (data.customer == null || data.customer!.isEmpty) {
    throw StateError('Customer details are missing from the home return.');
  }

  final store = data.store!.first;
  final customer = data.customer!.first;
  final details = data.detail ?? [];
  final decimals = AppState().noOfDecimals ?? 2;

  String money(num? value) => (value ?? 0).toStringAsFixed(decimals);

  // Company header
  if (logo != null) {
    b.image(logo, width: 248);
  }

  final companyName = store.name ?? '';
  if (companyName.isNotEmpty) {
    b.text(companyName, size: 28, bold: true, align: PAlign.center);
  }

  final companyNameAr = store.name_ar ?? '';
  if (companyNameAr.trim().isNotEmpty) {
    b.text(companyNameAr, size: 26, bold: true, align: PAlign.center);
  }

  final address = store.address ?? '';
  if (address.isNotEmpty && address != 'N/A') {
    b.text(address, size: 20, align: PAlign.center);
  }

  final email = store.email ?? '';
  if (email.isNotEmpty && email != 'N/A') {
    b.text(email, size: 20, align: PAlign.center);
  }

  final storeTrn = store.trn ?? '';
  if (storeTrn.isNotEmpty && storeTrn != 'N/A') {
    b.text('TRN: $storeTrn', size: 20, align: PAlign.center);
  }

  b.divider();
  b.text('TAX CREDIT NOTE', size: 26, bold: true, align: PAlign.center);
  b.divider();

  // Customer and credit note details
  final customerName = customer.name ?? 'N/A';
  final invoiceNumber = data.invoiceNo ?? 'N/A';
  final invoiceDate = DateHelper.displayDate(data.inDate);

  b.row([
    Col('Customer: $customerName', flex: 3),
    Col('Ref: $invoiceNumber', flex: 2, align: PAlign.right),
  ], size: 20);

  b.row([
    Col('Contact: ${customer.contactNumber ?? 'N/A'}', flex: 3),
    Col('Date: $invoiceDate', flex: 2, align: PAlign.right),
  ], size: 20);

  final customerEmail = customer.email ?? '';
  if (customerEmail.isNotEmpty && customerEmail != 'N/A') {
    b.text('Email: $customerEmail', size: 20);
  }

  final customerTrn = customer.trn ?? '';
  if (customerTrn.isNotEmpty) {
    b.text('TRN: $customerTrn', size: 20);
  }

  b.divider();

  // Items
  b.row([
    Col('#', flex: 1),
    Col('Product', flex: 7),
    Col('Qty', flex: 2, align: PAlign.right),
    Col('Rate', flex: 2, align: PAlign.right),
    Col('Total', flex: 2, align: PAlign.right),
  ], size: 19, bold: true);
  b.divider(thickness: 1, spacing: 2);

  for (var i = 0; i < details.length; i++) {
    final item = details[i];

    b.row([
      Col('${i + 1}', flex: 1),
      Col((item.name ?? 'N/A').toUpperCase(), flex: 7),
      Col(
        '${item.quantity ?? 0} ${item.unit ?? ''}'.trim(),
        flex: 2,
        align: PAlign.right,
      ),
      Col(money(item.mrp), flex: 2, align: PAlign.right),
      Col(money(item.amount), flex: 2, align: PAlign.right),
    ], size: 19);

    final productType = item.productType ?? '';
    if (productType.isNotEmpty) {
      b.text('Type: $productType', size: 18);
    }
  }

  b.divider();

  // Totals
  final van = data.van != null && data.van!.isNotEmpty
      ? data.van!.first.name ?? 'N/A'
      : 'N/A';
  final salesman = data.user != null && data.user!.isNotEmpty
      ? data.user!.first.name ?? 'N/A'
      : 'N/A';

  b.row([
    Col('Van: $van', flex: 3),
    Col('Total: ${money(data.total)}', flex: 2, align: PAlign.right),
  ], size: 20);

  b.row([
    Col('Salesman: $salesman', flex: 3),
   Col('${AppState().taxLabel}: ${money(data.totalTax)}',
    flex: 2,
    align: PAlign.right),
  ], size: 20);

      final discount = data.effectiveDiscount.toDouble();
  if (discount > 0) {
    b.row([
      const Col('', flex: 3),
      Col('${data.discountLabel}: ${money(discount)}', flex: 2, align: PAlign.right),
    ], size: 20);
    b.row([
      const Col('', flex: 3),
      Col('Sub Total: ${money((data.total ?? 0) - discount)}',
          flex: 2, align: PAlign.right),
    ], size: 20);
  }

  final roundOff = double.tryParse('${data.roundOff ?? 0}') ?? 0;
  if (roundOff != 0) {
    b.row([
      const Col('', flex: 3),
      Col('Round Off: ${money(roundOff)}', flex: 2, align: PAlign.right),
    ], size: 20);
  }

  b.text(
    'Grand Total: ${money(data.grandTotal)}',
    size: 24,
    bold: true,
    align: PAlign.right,
  );

  // Amount in words
  // After
final amount = data.grandTotal ?? 0;
final amountParts = amount.toStringAsFixed(decimals).split('.');
final wholePart = int.parse(amountParts[0]);
final minorPart =
    decimals > 0 && amountParts.length > 1 ? int.parse(amountParts[1]) : 0;

var words = 'Amount in Words: ${AppState().code} '
    '${NumberToWord().convert('en-in', wholePart).toUpperCase()}';

if (minorPart > 0) {
  words += ' AND ${NumberToWord().convert('en-in', minorPart).toUpperCase()} '
      '${AppState().minor}';
}

words += ' ONLY';

  b.feed(32); // one blank line
  b.text(words, size: 18);
  b.feed(30);
}