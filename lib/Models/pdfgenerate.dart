import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter/material.dart';
import 'package:mobizapp/main.dart' show navigatorKey;
import 'package:open_file/open_file.dart' as open_file;
import 'package:path_provider/path_provider.dart' as path_provider;
// ignore: depend_on_referenced_packages
import 'package:printing/printing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// PDF ethu step-il nilkkunnu ennu ariyaan (diagnostic)
String pdfStage = 'start';

/// File name-il "/" pole ulla invalid characters maatti "_" aakkunnu
String _safeFileName(String name) =>
    name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

Future<String> saveAndLaunchFile(
  List<int> bytes,
  String fileName,
  bool isPrint, {
  Rect shareOrigin = const Rect.fromLTWH(0, 0, 10, 10),
}) async {
  final Uint8List data = Uint8List.fromList(bytes);
  final String safeName = _safeFileName(fileName);

  pdfStage = 'save: folder';
  String path;
  if (Platform.isIOS) {
    path = (await path_provider.getTemporaryDirectory()).path;
  } else if (Platform.isAndroid || Platform.isLinux || Platform.isWindows) {
    path = (await path_provider.getApplicationSupportDirectory()).path;
  } else {
    path = (await PathProviderPlatform.instance.getApplicationSupportPath())!;
  }

  pdfStage = 'save: writing file';
  final String fullPath =
      Platform.isWindows ? '$path\\$safeName' : '$path/$safeName';
  await File(fullPath).writeAsBytes(data, flush: true);

  pdfStage = 'save: opening';
  if (isPrint) {
    await Printing.layoutPdf(name: safeName, onLayout: (_) async => data);
  } else if (Platform.isIOS) {
    // iPhone / iPad / Mac: direct PDF viewer
    final nav = navigatorKey.currentState;
    if (nav != null) {
      await nav.push(MaterialPageRoute(
        builder: (_) => _PdfViewerPage(name: safeName, bytes: data),
      ));
    } else {
      await open_file.OpenFile.open(fullPath);
    }
  } else if (Platform.isAndroid) {
    await open_file.OpenFile.open(fullPath);
  } else if (Platform.isWindows) {
    await Process.run('start', <String>[fullPath], runInShell: true);
  } else if (Platform.isMacOS) {
    await Process.run('open', <String>[fullPath], runInShell: true);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', <String>[fullPath], runInShell: true);
  }

  pdfStage = 'done';
  return fullPath;
}

class _PdfViewerPage extends StatelessWidget {
  final String name;
  final Uint8List bytes;
  const _PdfViewerPage({required this.name, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: name,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}