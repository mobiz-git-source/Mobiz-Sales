// image_report_printer.dart
//
// One common print layer for all reports (invoices, receipts, summaries...).
// Every report is drawn as an image using Flutter's own text engine, so Arabic,
// right-to-left text and mixed Arabic/English print correctly. The image is then
// wrapped in the right command language for the printer:
//   - Sewoo LK-P41 and other ESC/POS printers  -> ESC/POS raster (GS v 0)
//   - Zebra ZQ520 (default CPCL mode)          -> CPCL graphics (CG / EG)
//
// Dependency (pubspec.yaml):
//   qr_flutter: ^4.1.0
//
// Usage example (in any report):
//
//   final b = ImageReportBuilder(widthDots: 576);
//   b.text('شركة المثال للتجارة', size: 32, bold: true, align: PAlign.center);
//   b.text('Example Trading Co.', size: 26, bold: true, align: PAlign.center);
//   b.divider();
//   b.row([Col('Item', flex: 3), Col('Qty', align: PAlign.center), Col('Amount', flex: 2, align: PAlign.right)], bold: true);
//   b.row([Col('ماء 500 مل', flex: 3), Col('2', align: PAlign.center), Col('4.00', flex: 2, align: PAlign.right)]);
//   b.divider();
//   b.row([Col('الإجمالي / Total', flex: 4, bold: true), Col('4.00', flex: 2, align: PAlign.right, bold: true)]);
//   b.qrcode('INV-1001', size: 220, align: PAlign.center);
//   b.feed(20);
//
//   final bytes = await b.buildFor(PrinterType.zebraCpcl);   // or PrinterType.escPos
//   await sendInChunks((chunk) async {
//     connection.output.add(chunk);        // your Bluetooth package's write call
//     await connection.output.allSent;
//   }, bytes);

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:qr_flutter/qr_flutter.dart';

// false = do not send FORM (stops the Zebra feeding extra blank paper).
// Set to true to go back to the old behaviour.
const bool kZebraSendFormCommand = false;

enum PrinterType { escPos, zebraCpcl }

/// Named PAlign to avoid clashing with Flutter's Align widget.
enum PAlign { left, center, right }

class Col {
  final String text;
  final int flex;
  final PAlign align;
  final bool? bold; // null = use the row's setting
  const Col(this.text, {this.flex = 1, this.align = PAlign.left, this.bold});
}

final _arabicChars =
    RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');

bool containsArabic(String s) => _arabicChars.hasMatch(s);

/// Direction from the first real letter, so "Customer: محمد" stays left-to-right
/// with the Arabic part shaped correctly, while "محمد Trading" reads right-to-left.
TextDirection textDirectionOf(String s) {
  for (final r in s.runes) {
    if (_arabicChars.hasMatch(String.fromCharCode(r))) return TextDirection.rtl;
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

// ---------------------------------------------------------------------------
// Builder: draws the report onto a canvas, top to bottom.
// ---------------------------------------------------------------------------

class ImageReportBuilder {
  /// Printable width in dots at 203 dpi: 576 = 3" roll (your current paper),
  /// 832 = 4" roll, 384 = 2" roll.
  final int widthDots;

  /// Font bundled in the app with Arabic glyphs (e.g. 'NotoNaskhArabic', 'Cairo').
  /// null = system font (works on most Android devices, but bundling a font
  /// gives the same look on every phone).
  final String? fontFamily;

  /// Default text size in pixels (= printer dots). 24 is roughly 3 mm high.
  final double defaultSize;

  /// Extra space between lines, in dots.
 final double lineGap;
final int marginDots;

final ui.PictureRecorder _recorder = ui.PictureRecorder();
late final Canvas _canvas = Canvas(_recorder);
double _y = 0;
bool _built = false;

ImageReportBuilder({
  this.widthDots = 576,
  this.fontFamily,
  this.defaultSize = 24,
  this.lineGap = 4,
  this.marginDots = 0,
}) : assert(marginDots >= 0),
     assert(marginDots * 2 < widthDots);

double get contentWidth => (widthDots - 2 * marginDots).toDouble();

double get currentHeight => _y;

  TextStyle _style(double size, bool bold) => TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        // Thermal printers look best with heavier text.
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: const Color(0xFF000000),
        height: 1.15,
      );

  TextAlign _textAlign(PAlign a) => switch (a) {
        PAlign.left => TextAlign.left,
        PAlign.center => TextAlign.center,
        PAlign.right => TextAlign.right,
      };

  TextPainter _layout(String text, double width,
      {required double size, required bool bold, required PAlign align}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _style(size, bold)),
      textAlign: _textAlign(align),
      textDirection: textDirectionOf(text),
    )..layout(minWidth: width, maxWidth: width);
    return tp;
  }

  /// A full-width line of text. Long text wraps automatically.
 void text(String text,
    {double? size, bool bold = false, PAlign align = PAlign.left}) {
  // Empty text lays out with 0 height -> blank line disappears.
  if (text.trim().isEmpty) {
    _y += (size ?? defaultSize) * 1.15 + lineGap;
    return;
  }
  final tp = _layout(text, contentWidth,
      size: size ?? defaultSize, bold: bold, align: align);
tp.paint(_canvas, Offset(marginDots.toDouble(), _y));
    _y += tp.height + lineGap;
    tp.dispose();
  }

  /// Columns side by side. Set rtl: true for Arabic-layout tables
  /// (first column appears on the right).
  void row(List<Col> cols,
      {double? size, bool bold = false, bool rtl = false, double gap = 8}) {
  if (cols.every((c) => c.text.trim().isEmpty)) {
  _y += (size ?? defaultSize) * 1.15 + lineGap;
  return;
}
final totalFlex = cols.fold<int>(0, (s, c) => s + c.flex);
   final usable = contentWidth - gap * (cols.length - 1);
final ordered = rtl ? cols.reversed.toList() : cols;

double x = marginDots.toDouble();
    double rowHeight = 0;
    for (final c in ordered) {
      final w = usable * c.flex / totalFlex;
      final tp = _layout(c.text, w,
          size: size ?? defaultSize, bold: c.bold ?? bold, align: c.align);
      tp.paint(_canvas, Offset(x, _y));
      // rowHeight = math.max(rowHeight, tp.height);
      rowHeight = math.max(rowHeight, tp.height).toDouble();
      tp.dispose();
      x += w + gap;
    }
    _y += rowHeight + lineGap;
  }

  /// Horizontal line. dashed: true gives a receipt-style dashed line.
  void divider({double thickness = 2, bool dashed = false, double spacing = 6}) {
    _y += spacing;
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = thickness;
   final left = marginDots.toDouble();
final right = (widthDots - marginDots).toDouble();

if (dashed) {
  for (double x = left; x < right; x += 16) {
    _canvas.drawLine(
      Offset(x, _y),
      Offset(math.min(x + 9, right), _y),
      paint,
    );
  }
} else {
  _canvas.drawLine(Offset(left, _y), Offset(right, _y), paint);
}
    _y += thickness + spacing;
  }

  /// QR code, size in dots.
 void qrcode(String data, {double size = 200, PAlign align = PAlign.center}) {
  final actualSize = math.min(size, contentWidth);
  final x = _xFor(actualSize, align);
  final painter = QrPainter(data: data, version: QrVersions.auto, gapless: true);
  _canvas.save();
  _canvas.translate(x, _y);
  painter.paint(_canvas, Size(actualSize, actualSize));
  _canvas.restore();
  _y += actualSize + lineGap;
}

  /// A logo or any other picture (e.g. loaded with decodeImageFromList).
  void image(ui.Image img, {double? width, PAlign align = PAlign.center}) {
   final double w =
math.min(width ?? img.width.toDouble(), contentWidth).toDouble();
final double h = img.height * w / img.width;
final double x = _xFor(w, align);
    _canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(x, _y, w, h),
      Paint()..filterQuality = FilterQuality.high,
    );
    _y += h + lineGap;
  }

  /// Blank space in dots (e.g. 20 before tearing off).
  void feed(double dots) => _y += dots;

double _xFor(double itemWidth, PAlign align) => switch (align) {
  PAlign.left => marginDots.toDouble(),
  PAlign.center => marginDots.toDouble() + (contentWidth - itemWidth) / 2,
  PAlign.right => widthDots.toDouble() - marginDots - itemWidth,
};
  /// Renders everything drawn so far into a 1-bit bitmap.Q
  Future<MonoBitmap> buildBitmap({int threshold = 150}) async {
    if (_built) throw StateError('ImageReportBuilder can only be built once.');
    _built = true;

    final picture = _recorder.endRecording();
  final int height = math.max(_y.ceil(), 1).toInt();
    final img = await picture.toImage(widthDots, height);
    final rgba = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    img.dispose();
    picture.dispose();

    return MonoBitmap.fromRgba(rgba, widthDots, height, threshold: threshold);
  }

  /// Renders and encodes for the given printer in one step.
  Future<Uint8List> buildFor(PrinterType type) async {
    final bitmap = await buildBitmap();
    return switch (type) {
      PrinterType.escPos => encodeEscPos(bitmap),
      PrinterType.zebraCpcl => encodeCpcl(bitmap),
    };
  }
}

// ---------------------------------------------------------------------------
// 1-bit bitmap shared by all printers. Bit = 1 means a black dot.
// ---------------------------------------------------------------------------

class MonoBitmap {
  final int widthBytes;
  final int height;
  final Uint8List data;

  MonoBitmap(this.widthBytes, this.height, this.data);

  int get widthDots => widthBytes * 8;

  factory MonoBitmap.fromRgba(Uint8List rgba, int width, int height,
      {int threshold = 150}) {
    final wb = (width + 7) ~/ 8;
    final out = Uint8List(wb * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        final a = rgba[i + 3];
        if (a < 128) continue; // transparent = paper (white)
        // Pixels are premultiplied; for black-on-transparent this is fine.
        final lum = (rgba[i] * 299 + rgba[i + 1] * 587 + rgba[i + 2] * 114) ~/ 1000;
        if (lum < threshold) out[y * wb + (x >> 3)] |= (0x80 >> (x & 7));
      }
    }
    return MonoBitmap(wb, height, out);
  }

  Uint8List rows(int from, int count) =>
      data.sublist(from * widthBytes, (from + count) * widthBytes);
}



Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);


Uint8List encodeEscPos(MonoBitmap m, {int stripRows = 256, int feedLines = 4}) {
  final b = BytesBuilder();
  b.add([0x1B, 0x40]); // initialise
  for (int y = 0; y < m.height; y += stripRows) {
    final h = math.min(stripRows, m.height - y);
    b.add([
      0x1D, 0x76, 0x30, 0x00, // GS v 0, normal density
      m.widthBytes & 0xFF, (m.widthBytes >> 8) & 0xFF,
      h & 0xFF, (h >> 8) & 0xFF,
    ]);
    b.add(m.rows(y, h));
  }
  b.add(List<int>.filled(feedLines, 0x0A)); // feed out to tear bar
  return b.toBytes();
}

Uint8List encodeCpcl(
  MonoBitmap m, {
  int stripRows = 200,
  bool compressed = false,
  int tearOffFeedDots = 80,
}) {
  if (stripRows <= 0) {
    throw ArgumentError.value(
      stripRows,
      'stripRows',
      'Must be greater than 0',
    );
  }

  if (tearOffFeedDots < 0) {
    throw ArgumentError.value(
      tearOffFeedDots,
      'tearOffFeedDots',
      'Must not be negative',
    );
  }

  // Keep the existing behavior unless CG raw-byte support has already
  // been verified for this printer and encoder.
  if (compressed) {
    throw ArgumentError.value(
      compressed,
      'compressed',
      'CG compression is not implemented for raw bitmap bytes.',
    );
  }

   final b = BytesBuilder();
  final wb = m.widthBytes;

  // Ignore blank rows at the very bottom (report feed / empty lines) so the
  // Zebra does not push out extra paper. Sewoo output is not affected.
  int usedHeight = m.height;
  while (usedHeight > 0) {
    final base = (usedHeight - 1) * wb;
    bool hasInk = false;
    for (int c = 0; c < wb; c++) {
      if (m.data[base + c] != 0) {
        hasInk = true;
        break;
      }
    }
    if (hasInk) break;
    usedHeight--;
  }
  if (usedHeight == 0) usedHeight = m.height; // completely blank: keep as before

  final pageHeight = usedHeight + tearOffFeedDots;
  b.add(
    _ascii('! 0 200 200 $pageHeight 1\r\n'),
  );

  b.add(
    _ascii('PAGE-WIDTH ${m.widthDots}\r\n'),
  );

  // Process the bitmap in fixed-size bands.
  // Do not scan over an arbitrary number of blank rows.
   for (int top = 0; top < usedHeight; top += stripRows) {
    final bandHeight = math.min(
      stripRows,
      usedHeight - top,
    );

    int left = wb;
    int right = -1;

    // Find the used byte columns in this band.
    for (int row = 0; row < bandHeight; row++) {
      final base = (top + row) * wb;

      for (int column = 0; column < wb; column++) {
        if (m.data[base + column] != 0) {
          if (column < left) {
            left = column;
          }

          if (column > right) {
            right = column;
          }
        }
      }
    }

       // Fully blank band: nothing to print. Every EG has an absolute Y,
    // so the gap stays exactly as drawn.
    if (right < left) continue;

    final bandWidth = right - left + 1;
    final block = Uint8List(bandWidth * bandHeight);

    for (int row = 0; row < bandHeight; row++) {
      final sourceStart = (top + row) * wb + left;

      block.setRange(
        row * bandWidth,
        (row + 1) * bandWidth,
        m.data,
        sourceStart,
      );
    }

    final x = left * 8;
    final hex = StringBuffer();

    for (final byte in block) {
      hex.write(
        byte.toRadixString(16).padLeft(2, '0').toUpperCase(),
      );
    }

    b.add(
      _ascii(
        'EG $bandWidth $bandHeight $x $top $hex\r\n',
      ),
    );
  }

  // Keep one PRINT command for the complete report.
  if (kZebraSendFormCommand) {
    b.add(_ascii('FORM\r\n'));
  }
  b.add(_ascii('PRINT\r\n'));

return b.toBytes();
}

// ---------------------------------------------------------------------------
// Bluetooth sending, independent of which Bluetooth package you use.
// ---------------------------------------------------------------------------

typedef ByteWriter = Future<void> Function(Uint8List chunk);

/// Sends data in small pieces so the printer's Bluetooth buffer doesn't overflow.
/// If long reports stop halfway, lower chunkSize or raise pause.
Future<void> sendInChunks(
  ByteWriter write,
  Uint8List data, {
  int chunkSize = 512,
  Duration pause = const Duration(milliseconds: 20),
}) async {
  for (int i = 0; i < data.length; i += chunkSize) {
    final end = math.min(i + chunkSize, data.length);
    await write(Uint8List.sublistView(data, i, end));
    await Future<void>.delayed(pause);
  }
}

