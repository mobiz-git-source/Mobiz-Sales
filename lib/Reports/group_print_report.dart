// Reports/group_print_report.dart
//
// Combined Sales + Return + Collection print, drawn once for every printer.
// Replaces _printZebra() in GroupPrint.dart.

import 'dart:ui' as ui;

import 'package:number_to_words/number_to_words.dart';

import '../Models/appstate.dart';
import '../Models/Group_Model.dart' as Invoice;
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

const String kStoreLogoBaseUrl = 'https://erpadmin.mobiz.ae/uploads/store/';

String _formatInvoiceType(String? t) {
  if (t == null) return 'N/A';
  switch (t.toLowerCase()) {
    case 'salesreturn':
      return 'Sales Return';
    case 'payment_voucher':
      return 'Payment';
    default:
      return t.isNotEmpty ? t[0].toUpperCase() + t.substring(1).toLowerCase() : t;
  }
}

String _amountInWords(double amount) {
  int wholePart = amount.toInt();
  int decimalPart = ((amount - wholePart).abs() * 100).round();
  String words = NumberToWord().convert('en-in', wholePart).toUpperCase();
  String result = "${AppState().code} $words";
  if (decimalPart > 0) {
    String decWords = NumberToWord().convert('en-in', decimalPart).toUpperCase();
    result += " AND ${AppState().minor ?? 'FILS'} $decWords";
  }
  return "Amount in Words: $result ONLY";
}

void drawGroupPrint(ImageReportBuilder b, Invoice.SaleReturnCollection invoice) {
  final dec = AppState().noOfDecimals ?? 2;
  final bool wide = b.widthDots >= 800;
  final double normal = wide ? 24 : 22;
  final double large = wide ? 32 : 28;

  final store = invoice.store ?? invoice.sales?.store ?? invoice.returnData?.store;
  final customer = invoice.sales?.customer ??
      invoice.returnData?.customer ??
      (invoice.collection?.customer != null && invoice.collection!.customer!.isNotEmpty
          ? invoice.collection!.customer!.first
          : null);

 if (store == null) {
  throw StateError('Store details are missing from the group print.');
}

  // ---- 1. Company header ----
  final companyName = store.name ?? 'N/A';
  if (companyName != 'N/A') {
    b.text(companyName, size: large, bold: true, align: PAlign.center);
  }
  final companyAddress = store.address ?? 'N/A';
  if (companyAddress != 'N/A') {
    b.text(companyAddress, size: normal, align: PAlign.center);
  }
  final companyMail = store.email ?? 'N/A';
  if (companyMail != 'N/A') {
    b.text(companyMail, size: normal, align: PAlign.center);
  }
  if ((store.trn ?? 'N/A') != 'N/A') {
    b.text('TRN: ${store.trn}', size: normal, align: PAlign.center);
  }
  b.divider();
  b.text('Tax Invoice', size: large - 2, bold: true, align: PAlign.center);
  b.divider();

  // ---- 2. Invoice info ----
  final invoiceNumber = invoice.sales?.invoiceNo ?? invoice.returnData?.invoiceNo ?? 'N/A';
  final rawDate = invoice.sales?.inDate ?? invoice.returnData?.inDate;
  final rawTime = invoice.sales?.inTime ?? invoice.returnData?.inTime;
  final invoiceDate = (rawDate != null && rawDate.isNotEmpty) ? DateHelper.displayDate(rawDate) : 'N/A';

  b.row([
    Col('Invoice No: $invoiceNumber', flex: 3),
    Col('Date: $invoiceDate', flex: 2, align: PAlign.right),
  ], size: normal);
  if (rawTime != null && rawTime.isNotEmpty) {
    b.row([Col('', flex: 3), Col('Time: $rawTime', flex: 2, align: PAlign.right)], size: normal);
  }
  b.feed(6);

  // ---- 3. Customer block ----
  final customerName = customer?.name ?? 'N/A';
  if (customerName != 'N/A') {
    b.row([Col('Customer:', flex: 2), Col(customerName, flex: wide ? 9 : 5)], size: normal);
  }
  final customerContact = customer?.contactNumber ?? 'N/A';
  if (customerContact != 'N/A') {
    b.text('Contact No: $customerContact', size: normal);
  }
  final customerTRN = customer?.trn ?? '';
  if (customerTRN.isNotEmpty) {
    b.text('${store.vatLabel ?? 'VAT'}: $customerTRN', size: normal);
  }
  final billType = invoice.sales?.cashCard ?? 'N/A';
  if (billType != 'N/A') {
    b.text('Bill Type: $billType', size: normal);
  }
  b.divider();

  // Shared item table (works for both Sales and Return detail lists)
  void itemTable(List detail) {
    if (wide) {
      b.row([
       Col('#', flex: 2),
Col('Product', flex: 7),
Col('', flex: 1),
Col('Unit', flex: 2),
        Col('Qty', flex: 2, align: PAlign.right),
        Col('Rate', flex: 3, align: PAlign.right),
        Col('Amount', flex: 3, align: PAlign.right),
        Col('Total', flex: 3, align: PAlign.right),
      ], size: normal - 2, bold: true);
      b.divider(thickness: 1, spacing: 2);
      for (final d in detail) {
        b.row([
          Col('${detail.indexOf(d) + 1}', flex: 2),
          Col('${d.name ?? ''}', flex: 8),
          Col('${d.unit ?? ''}', flex: 2),
          Col('${d.quantity ?? 0}', flex: 2, align: PAlign.right),
          Col((d.mrp as num?)?.toStringAsFixed(dec) ?? '0.00', flex: 3, align: PAlign.right),
          Col((d.taxable as num?)?.toStringAsFixed(dec) ?? '0.00', flex: 3, align: PAlign.right),
          Col((d.amount as num?)?.toStringAsFixed(dec) ?? '0.00', flex: 3, align: PAlign.right),
        ], size: normal - 2);
      }
    } else {
      b.row([Col('#', flex: 1), Col('Product', flex: 12)], size: normal, bold: true);
      b.row([
        Col('', flex: 1),
        Col('Type', flex: 4),
        Col('Qty', flex: 3, align: PAlign.right),
        Col('Rate', flex: 3, align: PAlign.right),
        Col('Total', flex: 3, align: PAlign.right),
      ], size: normal, bold: true);
      b.divider(thickness: 1, spacing: 2);
      for (int i = 0; i < detail.length; i++) {
        final d = detail[i];
        b.row([Col('${i + 1}', flex: 1), Col('${d.name ?? ''}'.toUpperCase(), flex: 12)], size: normal, bold: true);
        b.row([
          Col('', flex: 1),
          Col('${d.productType ?? ''}', flex: 4),
          Col('${d.quantity ?? 0} ${d.unit ?? ''}'.trim(), flex: 3, align: PAlign.right),
          Col((d.mrp as num?)?.toStringAsFixed(dec) ?? '0.00', flex: 3, align: PAlign.right),
          Col((d.amount as num?)?.toStringAsFixed(dec) ?? '0.00', flex: 3, align: PAlign.right),
        ], size: normal);
        b.feed(4);
      }
    }
  }

  // ---- 4. Sales section ----
  if (invoice.sales != null && invoice.sales!.detail.isNotEmpty) {
    b.text('SALES', size: large - 4, bold: true);
    b.divider(thickness: 1, spacing: 2);
    itemTable(invoice.sales!.detail);
    b.divider();
    b.row([
      Col('Salesman: ${invoice.sales!.user?.name ?? 'N/A'}', flex: 3),
      Col('Total: ${invoice.sales!.total.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal);
    b.row([
      Col('', flex: 3),
      Col('Vat: ${invoice.sales!.totalTax.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal);
    b.row([
      Col('', flex: 3),
      Col('Grand Total: ${invoice.sales!.grandTotal.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal, bold: true);
    b.feed(6);
    b.text(_amountInWords(invoice.sales!.grandTotal), size: normal - 2);
    b.feed(14);
  }

  // ---- 5. Return section ----
  if (invoice.returnData != null && invoice.returnData!.detail.isNotEmpty) {
    b.text('RETURN', size: large - 4, bold: true);
    b.divider(thickness: 1, spacing: 2);
    itemTable(invoice.returnData!.detail);
    b.divider();
    final van = invoice.returnData!.van?.name ?? invoice.sales?.van?.name ?? 'N/A';
    final discount = invoice.returnData!.discount;
    b.row([
      Col('Van: $van', flex: 3),
      Col(discount > 0 ? 'Discount: ${discount.toStringAsFixed(dec)}' : '', flex: 2, align: PAlign.right),
    ], size: normal);
    b.row([
      Col('Salesman: ${invoice.returnData!.user?.name ?? 'N/A'}', flex: 3),
      Col('Total: ${invoice.returnData!.total.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal);
    b.row([
      Col('', flex: 3),
      Col('Vat: ${invoice.returnData!.totalTax.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal);
    b.row([
      Col('', flex: 3),
      Col('Grand Total: ${invoice.returnData!.grandTotal.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal, bold: true);
    b.feed(6);
    b.text(_amountInWords(invoice.returnData!.grandTotal), size: normal - 2);
    b.feed(14);
  }

  // ---- 6. Collection section ----
  final coll = invoice.collection;
  final hasCollectionSales = coll?.sales != null && coll!.sales!.isNotEmpty;
  final collAmt = double.tryParse(coll?.totalAmount ?? '0') ?? 0;
  if (coll != null && (hasCollectionSales || collAmt != 0)) {
    b.text('COLLECTION', size: large - 4, bold: true);
    b.divider();

    b.text('Amount: ${collAmt.toStringAsFixed(dec)}', size: normal);
    if (coll.collectionType == 'Cheque') {
      b.row([
        Col('Type: Cheque', flex: 3),
        Col('Bank: ${coll.bank ?? 'N/A'}', flex: 2, align: PAlign.right),
      ], size: normal);
      b.row([
        Col('Cheque No: ${coll.chequeNo ?? 'N/A'}', flex: 3),
        Col('Date: ${coll.chequeDate ?? 'N/A'}', flex: 2, align: PAlign.right),
      ], size: normal);
    } else if (coll.collectionType == 'Cash') {
      b.text('Collection Type: Cash', size: normal);
    }

    if (hasCollectionSales) {
      b.feed(6);
      b.row([
        Col('Sl', flex: 2),
        Col('Reference No', flex: 6),
        Col('Type', flex: 4),
        Col('Amount', flex: 3, align: PAlign.right),
      ], size: normal - 2, bold: true);
      b.divider(thickness: 1, spacing: 2);
      for (int i = 0; i < coll.sales!.length; i++) {
        final sale = coll.sales![i];
        final saleAmount = double.tryParse(sale.amount ?? '0') ?? 0;
        b.row([
          Col('${i + 1}', flex: 2),
          Col(sale.invoiceNo ?? 'N/A', flex: 6),
          Col(_formatInvoiceType(sale.invoiceType), flex: 4),
          Col(saleAmount.toStringAsFixed(dec), flex: 3, align: PAlign.right),
        ], size: normal - 2);
      }
      b.divider();
    }

    if (coll.roundOff != null && (double.tryParse(coll.roundOff!) ?? 0) != 0) {
      b.row([
        Col('', flex: 3),
        Col('Round Off: ${double.parse(coll.roundOff!).toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
      ], size: normal);
    }
    b.row([Col('', flex: 3), Col('Total: ${collAmt.toStringAsFixed(dec)}', flex: 2, align: PAlign.right)], size: normal);
    if (coll.van != null && coll.van!.isNotEmpty) {
      b.text('Van: ${coll.van![0].name}', size: normal);
    }
    if (coll.user != null && coll.user!.isNotEmpty) {
      b.text('Salesman: ${coll.user![0].name}', size: normal);
    }
    b.feed(10);
  }

  b.feed(30);
}