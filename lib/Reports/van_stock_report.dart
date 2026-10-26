import 'dart:ui' as ui;

import '../Utilities/report_printer.dart';

class VanStockPrintUnit {
  final String name;
  final String quantity;

  const VanStockPrintUnit({
    required this.name,
    required this.quantity,
  });
}

class VanStockPrintProduct {
  final String name;
  final String code;
  final List<VanStockPrintUnit> units;

  const VanStockPrintProduct({
    required this.name,
    required this.code,
    required this.units,
  });
}

void drawVanStockReport(
  ImageReportBuilder b, {
  required String companyName,
  required String title,
  required List<VanStockPrintProduct> products,
  ui.Image? logo,
}) {
  if (logo != null) {
    b.image(logo, width: 248);
  }

  b.text(companyName, size: 28, bold: true, align: PAlign.center);
  b.text(title, size: 26, bold: true, align: PAlign.center);
  b.divider();

  b.row(
    [Col('#', flex: 1), Col('Product', flex: 8)],
    size: 22,
    bold: true,
  );
  b.row(
    [
      Col('', flex: 1),
      Col('Code', flex: 4),
      Col('Unit', flex: 3),
      Col('Qty', flex: 2, align: PAlign.right),
    ],
    size: 20,
    bold: true,
  );
  b.divider(thickness: 1, spacing: 2);

  var serialNumber = 1;
  for (final product in products) {
    final units = product.units.isEmpty
        ? const [VanStockPrintUnit(name: 'N/A', quantity: '0')]
        : product.units;

    for (final unit in units) {
      b.row(
        [
          Col('$serialNumber', flex: 1),
          Col(product.name.toUpperCase(), flex: 8),
        ],
        size: 21,
        bold: true,
      );
      b.row(
        [
          Col('', flex: 1),
          Col('[${product.code}]', flex: 4),
          Col(unit.name, flex: 3),
          Col(unit.quantity, flex: 2, align: PAlign.right),
        ],
        size: 20,
      );
      serialNumber++;
    }
  }

  b.divider();
  b.text('Total Items: ${serialNumber - 1}', size: 21, align: PAlign.center);
  b.feed(30);
}