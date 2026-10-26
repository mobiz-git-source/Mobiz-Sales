// Reports/receipt_report.dart
//
// The collection receipt, drawn once for every printer (Sewoo and Zebra).
// Replaces _printZebra() / _printSewoo() in ReceiptScreen.dart.

import 'dart:ui' as ui;

import '../Models/Store_model.dart';
import '../Models/receiptdatamodel.dart';
import '../Models/appstate.dart';
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

const String kStoreLogoBaseUrl = 'https://erpadmin.mobiz.ae/uploads/store/';

String _formatInvoiceType(String? t) {
  if (t == null) return 'N/A';
  switch (t.toLowerCase()) {
    case 'salesreturn':
      return 'Sales Return';
    case 'payment_voucher':
    case 'paymentvoucher':
      return 'Payment';
    default:
      return t.isNotEmpty ? t[0].toUpperCase() + t.substring(1).toLowerCase() : t;
  }
}

void drawReceipt(
  ImageReportBuilder b,
  ReportData data,
  StoreDetail store,
  String outstanding, {
  ui.Image? logo,
}) {
  final dec = AppState().noOfDecimals ?? 2;
  final bool wide = b.widthDots >= 800;
  final double normal = wide ? 24 : 22;
  final double large = wide ? 32 : 28;

  // ---- 1. Logo & company header ----
  if (logo != null) b.image(logo, width: wide ? 300 : 248);

  final companyName = store.name ?? '';
  if (companyName.isNotEmpty) {
    b.text(companyName, size: large, bold: true, align: PAlign.center);
  }
  final companyNameAr = store.name_ar ?? '';
  if (companyNameAr.trim().isNotEmpty) {
    b.text(companyNameAr, size: large - 2, bold: true, align: PAlign.center);
  }
  final address = store.address ?? '';
  if (address.isNotEmpty && address != 'N/A') {
    b.text(address, size: normal, align: PAlign.center);
  }
  if ((store.trn ?? '').isNotEmpty && store.trn != 'N/A') {
    b.text('TRN: ${store.trn}', size: normal, align: PAlign.center);
  }
  b.divider();
  b.text('RECEIPT VOUCHER', size: large - 2, bold: true, align: PAlign.center);
  b.divider();

  // ---- 2. Customer / voucher info ----
  final voucherNo = (data.sales != null && data.sales!.isNotEmpty)
      ? (data.sales![0].voucherNo ?? 'N/A')
      : 'N/A';
  final inDate = (data.sales != null && data.sales!.isNotEmpty)
      ? DateHelper.displayDate(data.sales![0].inDate)
      : 'N/A';
  final inTime = (data.sales != null && data.sales!.isNotEmpty)
      ? (data.sales![0].inTime ?? '')
      : '';

  if (data.customer != null && data.customer!.isNotEmpty) {
    final custName = data.customer![0].name ?? '';
    if (custName.trim().isNotEmpty) {
      b.row([Col('Customer:', flex: 2), Col(custName, flex: wide ? 9 : 5)], size: normal);
    }
  }
  b.row([
    Col('Voucher: $voucherNo', flex: 3),
    Col('Date: $inDate', flex: 2, align: PAlign.right),
  ], size: normal);
  if (inTime.isNotEmpty) {
    b.row([Col('', flex: 3), Col('Time: $inTime', flex: 2, align: PAlign.right)], size: normal);
  }
  if (data.customer != null && data.customer!.isNotEmpty) {
    final trn = data.customer![0].trn;
    if (trn != null && trn.isNotEmpty) {
      final vatLabel = (data.store != null && data.store!.isNotEmpty)
          ? (data.store![0].vatLabel ?? 'VAT')
          : 'VAT';
      b.text('$vatLabel: $trn', size: normal);
    }
  }
  b.divider();

  // ---- 3. Collection info ----
  if ((data.collectionType ?? '').toLowerCase() == 'cheque') {
    b.row([
      Col('Type: Cheque', flex: 3),
      Col('Bank: ${data.bank ?? 'N/A'}', flex: 2, align: PAlign.right),
    ], size: normal);
    b.row([
      Col('Cheque No: ${data.chequeNo ?? 'N/A'}', flex: 3),
      Col(
        'Date: ${data.chequeDate != null ? DateHelper.displayDate(data.chequeDate) : 'N/A'}',
        flex: 2,
        align: PAlign.right,
      ),
    ], size: normal);
  } else {
    b.text('Type: ${data.collectionType ?? 'Cash'}', size: normal);
  }
  b.text('Amount: ${data.totalAmount ?? '0.00'}', size: normal);
  b.divider();

  // ---- 4. Sales table ----
  b.row([
    Col('Sl', flex: 2),
    Col('Reference No', flex: 6),
    Col('Type', flex: 4),
    Col('Amount', flex: 3, align: PAlign.right),
  ], size: normal - 2, bold: true);
  b.divider(thickness: 1, spacing: 2);

  final sales = data.sales ?? [];
  for (int i = 0; i < sales.length; i++) {
    final sale = sales[i];
    b.row([
      Col('${i + 1}', flex: 2),
      Col(sale.invoiceNo ?? 'N/A', flex: 6),
      Col(_formatInvoiceType(sale.invoiceType), flex: 4),
      Col(sale.amount?.toString() ?? '0.00', flex: 3, align: PAlign.right),
    ], size: normal - 2);
  }
  b.divider();

  // ---- 5. Totals ----
  final van = (data.van != null && data.van!.isNotEmpty) ? (data.van![0].name ?? 'N/A') : 'N/A';
  final salesman = (data.user != null && data.user!.isNotEmpty) ? (data.user![0].name ?? 'N/A') : 'N/A';

  if (data.roundoff != null && (double.tryParse(data.roundoff!) ?? 0) != 0) {
    b.row([
      Col('', flex: 3),
      Col('Round Off: ${double.parse(data.roundoff!).toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal);
  }
  b.row([Col('', flex: 3), Col('Total: ${data.totalAmount ?? '0.00'}', flex: 2, align: PAlign.right)], size: normal);
  b.row([Col('', flex: 3), Col('Total Outstanding: $outstanding', flex: 2, align: PAlign.right)], size: normal);
  b.feed(6);
  b.row([
    Col('Van: $van', flex: 3),
    Col('Salesman: $salesman', flex: 2, align: PAlign.right),
  ], size: normal);
  b.feed(30);
}