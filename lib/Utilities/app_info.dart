import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static String version = '';
  static String buildNumber = '';

  static Future<void> init() async {
    final p = await PackageInfo.fromPlatform();
    version = p.version;
    buildNumber = p.buildNumber;
  }
}