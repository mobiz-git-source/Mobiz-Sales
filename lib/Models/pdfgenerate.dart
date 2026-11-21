import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart' as open_file;
import 'package:path_provider/path_provider.dart' as path_provider;
// ignore: depend_on_referenced_packages
import 'package:printing/printing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

Future<String> saveAndLaunchFile(
    List<int> bytes, String fileName, bool _isPrint) async {
  String? path;
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isLinux ||
      Platform.isWindows) {
    final Directory directory =
        await path_provider.getApplicationSupportDirectory();
    path = directory.path;
  } else {
    path = await PathProviderPlatform.instance.getApplicationSupportPath();
  }
  final File file =
      File(Platform.isWindows ? '$path\\$fileName' : '$path/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  if (Platform.isIOS) {
    // iOS: show PDF with printing preview (share / print available)
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async => Uint8List.fromList(bytes),
    );
  } else if (Platform.isAndroid) {
    if (_isPrint) {
      final pdf = await rootBundle.load('$path/$fileName');
      await Printing.layoutPdf(onLayout: (_) => pdf.buffer.asUint8List());
    } else {
      await open_file.OpenFile.open('$path/$fileName');
    }
  } else if (Platform.isWindows) {
    await Process.run('start', <String>['$path\\$fileName'], runInShell: true);
  } else if (Platform.isMacOS) {
    await Process.run('open', <String>['$path/$fileName'], runInShell: true);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', <String>['$path/$fileName'],
        runInShell: true);
  }
  return '$path/$fileName';
}