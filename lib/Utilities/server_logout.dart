import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';

/// Server-il ninn ee device-inte push token remove cheyyum.
/// Fail aayalum logout thudaranam, athukondu error ignore cheyyunnu.
Future<void> serverLogout() async {
  try {
    final token = AppState().token?.toString() ?? '';
    if (token.isEmpty) return;

    final info = DeviceInfoPlugin();
    final deviceId = Platform.isAndroid
        ? (await info.androidInfo).id
        : ((await info.iosInfo).identifierForVendor ?? '');

    final res = await http
        .post(
          Uri.parse('${RestDatasource().BASE_URL}/api/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'device_id': deviceId}),
        )
        .timeout(const Duration(seconds: 8));
    debugPrint('SERVER LOGOUT ${res.statusCode}');
  } catch (e) {
    debugPrint('SERVER LOGOUT ERROR (ignored): $e');
  }
}