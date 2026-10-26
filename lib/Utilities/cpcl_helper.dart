// Utilities/cpcl_helper.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
// PAPER ROLL SPECIFICATIONS
// 3-inch roll (Zebra ZQ520) = 576 dots printable width
// ═══════════════════════════════════════════════════════════════
const int kLabelWidthDots = 832;
const int kLogoWidthPx = 248;    // Byte-aligned (248 ~/ 8 = 31 bytes per row)
const bool kInvertLogoBits = false;
const int kCharWidthDots = 12;   // Monospace width for CPCL font 4

/// Converts an image to 1-bit monochrome bitmap for CPCL 'EG' (Expanded Graphics)
Uint8List imageTo1BitCpcl(img.Image src, {bool invert = false}) {
  final w = src.width, h = src.height;
  final bytesPerRow = (w / 8).ceil();
  final out = Uint8List(bytesPerRow * h);
  if (w == 0 || h == 0) return out;

  bool useV4Api = false;
  try {
    // ignore: avoid_dynamic_calls
    (src.getPixel(0, 0) as dynamic).luminanceNormalized;
    useV4Api = true;
  } catch (_) {
    useV4Api = false;
  }

  num lumAt(int x, int y) {
    final p = src.getPixel(x, y);
    if (useV4Api && (p as dynamic).a < 128) return 255; 
    return useV4Api ? (p as dynamic).luminanceNormalized * 255 : img.getLuminance(p);
  }

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool black = lumAt(x, y) < 128;
      if (invert) black = !black;
      if (black) {
        final byteIndex = y * bytesPerRow + (x ~/ 8);
        final bitIndex = 7 - (x % 8);
        out[byteIndex] |= (1 << bitIndex);
      }
    }
  }
  return out;
}

class CpclBuilder {
  final List<int> _bytes = [];
  int _y = 20;
  final int labelWidth;

  CpclBuilder(this.labelWidth);

  int get currentY => _y;

  String _sanitizeCpclText(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x20 && rune <= 0x7E) {
        buffer.writeCharCode(rune);
        continue;
      }
      switch (rune) {
        case 0x2018:
        case 0x2019:
          buffer.write("'");
          break;
        case 0x201C:
        case 0x201D:
          buffer.write('"');
          break;
        case 0x2013:
        case 0x2014:
          buffer.write('-');
          break;
        case 0x2026:
          buffer.write('...');
          break;
        case 0x00A0:
          buffer.write(' ');
          break;
        default:
          break;
      }
    }
    return buffer.toString();
  }

  void _ascii(String s) => _bytes.addAll(utf8.encode(_sanitizeCpclText(s)));

  void text(String data, {int font = 4, int size = 0, int x = 10, int lineGap = 30}) {
    if (data.trim().isEmpty) return;
    _ascii('TEXT $font $size $x $_y $data\r\n');
    _y += lineGap;
  }

  void boldText(String data, {int font = 5, int size = 0, int x = 10, int lineGap = 36}) {
    if (data.trim().isEmpty) return;
    _ascii('TEXT $font $size $x $_y $data\r\n');
    _y += lineGap;
  }

  void centerText(String data, {int font = 4, int size = 0, int lineGap = 30}) {
    if (data.trim().isEmpty) return;
    int charWidth = (font == 5 || font >= 6 || size > 0) ? 16 : kCharWidthDots;
    int textWidth = data.length * charWidth;
    int x = ((labelWidth - textWidth) ~/ 2);
    if (x < 10) x = 10;
    _ascii('TEXT $font $size $x $_y $data\r\n');
    _y += lineGap;
  }

  void twoColumn(String left, String right,
      {int font = 4, int size = 0, int lineGap = 30, int leftX = 10, int rightMargin = 10}) {
    if (left.isNotEmpty) {
      _ascii('TEXT $font $size $leftX $_y $left\r\n');
    }
    if (right.isNotEmpty) {
      int charWidth = (font == 5 || font >= 6 || size > 0) ? 16 : kCharWidthDots;
      int x = labelWidth - rightMargin - (right.length * charWidth);
      if (left.isNotEmpty && x < leftX + (left.length * charWidth) + 10) {
        x = leftX + (left.length * charWidth) + 10;
      }
      if (x < 10) x = 10;
      _ascii('TEXT $font $size $x $_y $right\r\n');
    }
    _y += lineGap;
  }

  void hLine({int thickness = 1, int lineGap = 16}) {
    _ascii('LINE 10 $_y ${labelWidth - 10} $_y $thickness\r\n');
    _y += lineGap;
  }

  void feed(int dots) => _y += dots;

  // ✅ CRITICAL FIX: 'EG' (Expanded Graphics) instead of 'CG'
  void addLogo(Uint8List packedBits, int bytesPerRow, int rows) {
    if (packedBits.isEmpty || bytesPerRow <= 0 || rows <= 0) return;
    final x = ((labelWidth - (bytesPerRow * 8)) ~/ 2).clamp(0, labelWidth);
     _ascii('EG $bytesPerRow $rows $x $_y ');
    for (final byte in packedBits) {
      _ascii(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    _ascii('\r\n');
    _y += rows + 12;
  }

  Uint8List build({int qty = 1}) {
    final header = utf8.encode('! 0 200 200 ${_y + 40} $qty\r\nPAGE-WIDTH $labelWidth\r\n');
  final footer = utf8.encode('FORM\r\nPRINT\r\n');
return Uint8List.fromList([...header, ..._bytes, ...footer]);
  }
}

// ═══════════════════════════════════════════════════════════════
// HOMEPAGE COMPATIBILITY FUNCTION (Fixes homepage.dart error)
// ═══════════════════════════════════════════════════════════════
Future<void> switchZebraToCpcl(BlueThermalPrinter printer) async {
  try {
    // Zebra handles CPCL automatically when job starts with "! 0 200 200".
    // We send a tiny safe CR/LF wake-up handshake
    await printer.writeBytes(Uint8List.fromList(utf8.encode('\r\n')));
    await Future.delayed(const Duration(milliseconds: 100));
  } catch (e) {
    print('Zebra handshake notice: $e');
  }
}

// ═══════════════════════════════════════════════════════════════
// ZEBRA SENDER
// Zebra Bluetooth pacing. If prints still break: raise kZebraChunkDelayMs (e.g. 40-60).
// If prints are perfect but slow: lower it (e.g. 15-20).
const int kZebraChunkBytes = 512;
const int kZebraChunkDelayMs = 25;

// Only one Zebra job is sent at a time (two jobs can never mix their bytes).
Future<void> _zebraSendQueue = Future<void>.value();

Future<void> sendCpcl(BlueThermalPrinter printer, Uint8List data,
    {int? chunk}) {
  final run = _zebraSendQueue.then((_) => _sendCpclNow(printer, data, chunk: chunk));
  _zebraSendQueue = run.catchError((_) {});
  return run;
}

Future<void> _sendCpclNow(BlueThermalPrinter printer, Uint8List data,
    {int? chunk}) async {
  final bool? liveConnected = await printer.isConnected;
  if (liveConnected != true) {
    throw Exception('Printer not connected via Bluetooth');
  }

  // Never go bigger than the safe size, even if a caller passes a larger chunk.
  final int size =
      (chunk != null && chunk > 0 && chunk < kZebraChunkBytes) ? chunk : kZebraChunkBytes;

  await switchZebraToCpcl(printer);
  await Future.delayed(const Duration(milliseconds: 100));

  final int totalChunks = (data.length / size).ceil();
  for (int i = 0; i < data.length; i += size) {
    final end = (i + size < data.length) ? i + size : data.length;
    await printer.writeBytes(data.sublist(i, end));
    await Future.delayed(const Duration(milliseconds: kZebraChunkDelayMs));
  }

  // Let the printer finish taking the job before anything else is sent.
  await Future.delayed(const Duration(milliseconds: 500));
  print('CPCL: sendCpcl finished ($totalChunks chunks written)');
}

// ═══════════════════════════════════════════════════════════════
// PRINTER TYPE CONFIG & SELECTION (Fixes selectproduct.dart errors)
// ═══════════════════════════════════════════════════════════════
const String kPrinterTypeKey = 'printer_type_selected';
const String kSelectedDeviceAddressKey = 'selected_device_address';

bool _cachedIsZebra = false;

String _printerTypeKeyForDevice(String address) => 'printer_type_$address';

/// Saves printer type per device (Zebra = true, Sewoo = false)
Future<void> savePrinterTypeForDevice(String deviceAddress, bool isZebra) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_printerTypeKeyForDevice(deviceAddress), isZebra ? 'zebra' : 'sewoo');
  await prefs.setString(kPrinterTypeKey, isZebra ? 'zebra' : 'sewoo');
  _cachedIsZebra = isZebra;
}

/// Legacy global save (Fixed error in selectproduct.dart line 187)
Future<void> savePrinterType(bool isZebra) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kPrinterTypeKey, isZebra ? 'zebra' : 'sewoo');
  _cachedIsZebra = isZebra;
}

/// Reads saved printer type per device (Fixed error in selectproduct.dart line 102)
Future<bool?> getSavedPrinterTypeForDevice(String deviceAddress) async {
  if (deviceAddress.isEmpty) return null;
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_printerTypeKeyForDevice(deviceAddress));
  if (saved == null) return null;
  return saved == 'zebra';
}

Future<void> loadPrinterTypeCache() async {
  final prefs = await SharedPreferences.getInstance();
  final address = prefs.getString(kSelectedDeviceAddressKey);
  if (address != null && address.isNotEmpty) {
    final perDevice = prefs.getString(_printerTypeKeyForDevice(address));
    if (perDevice != null) {
      _cachedIsZebra = (perDevice == 'zebra');
      return;
    }
  }
  final saved = prefs.getString(kPrinterTypeKey) ?? 'sewoo';
  _cachedIsZebra = (saved == 'zebra');
}

bool getCachedIsZebra() => _cachedIsZebra;

/// Smart detection: Automatically recognizes Zebra by Bluetooth Name
/// even if user forgot to select it manually!
bool isZebraPrinter(BluetoothDevice? device) {
  if (device != null && device.name != null && device.name!.isNotEmpty) {
    final name = device.name!.toLowerCase();

    // 1. Exact Zebra identification (names & serial prefixes like XXR)
    if (name.contains('zebra') ||
        name.contains('zq') ||
        name.contains('zd') ||
        name.contains('zr') ||
        name.contains('qln') ||
        name.contains('imz') ||
        name.contains('xxr')) {    
      return true;
    }

    // 2. Exact Sewoo identification
    if (name.contains('sewoo') ||
        name.contains('gl-') ||   
        name.contains('tw59') ||
        name.contains('lk-') ||
        name.contains('pos')) {
      return false;
    }
  }

  // 3. Fallback to cached saved choice
  return _cachedIsZebra;
}

// ═══════════════════════════════════════════════════════════════
// SEWOO LOGO BUILDER
// ═══════════════════════════════════════════════════════════════
Future<Uint8List?> buildSewooLogoBytes(String logoUrl, {int width = 248}) async {
  try {
    final response = await http.get(Uri.parse(logoUrl));
    if (response.statusCode != 200) return null;
    img.Image? original = img.decodeImage(response.bodyBytes);
    if (original == null) return null;

    final alignedWidth = (width ~/ 8) * 8;
    img.Image resized = img.copyResize(original, width: alignedWidth);

    bool useV4Api = false;
    try {
      // ignore: avoid_dynamic_calls
      (resized.getPixel(0, 0) as dynamic).luminanceNormalized;
      useV4Api = true;
    } catch (_) {
      useV4Api = false;
    }

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final p = resized.getPixel(x, y);
        final num lum = useV4Api
            ? (p as dynamic).luminanceNormalized * 255
            : img.getLuminance(p);
        final bw = lum < 128 ? 0 : 255;
        resized.setPixelRgb(x, y, bw, bw, bw);
      }
    }

    return Uint8List.fromList(img.encodePng(resized));
  } catch (e) {
    print('Sewoo logo build error: $e');
    return null;
  }
}