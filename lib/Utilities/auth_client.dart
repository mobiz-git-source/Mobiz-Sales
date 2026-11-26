import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static String? token;
  static DateTime? tokenTime;
  static DateTime? loginTime;
  static String appVersion = '';

  static Future<void> save(String t, {bool isLogin = false}) async {
    token = t;
    tokenTime = DateTime.now();
    if (isLogin) loginTime = tokenTime;
    final p = await SharedPreferences.getInstance();
    await p.setString('api_token', t);
    await p.setString('api_token_time', tokenTime!.toIso8601String());
    if (isLogin) {
      await p.setString('api_login_time', loginTime!.toIso8601String());
    }
  }

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('api_token');
    tokenTime = DateTime.tryParse(p.getString('api_token_time') ?? '');
    loginTime = DateTime.tryParse(p.getString('api_login_time') ?? '');
    appVersion = (await PackageInfo.fromPlatform()).version;
  }

  static Future<void> clear() async {
    token = null;
    tokenTime = null;
    loginTime = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('api_token');
    await p.remove('api_token_time');
    await p.remove('api_login_time');
  }
}

class AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  static const _skip = [
    '/api/login',
    '/api/register',
    '/api/refresh',
    '/api/logout',
    'customer/login',
    'customer/register',
  ];

  static void Function()? onSessionExpired;
  static Future<bool>? _refreshFuture;

  bool _needsToken(Uri u) => !_skip.any((s) => u.path.contains(s));

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['app-version'] = TokenStore.appVersion;

    if (!_needsToken(request.url) || TokenStore.token == null) {
      return _inner.send(request);
    }

    final age =
        DateTime.now().difference(TokenStore.tokenTime ?? DateTime.now());
    if (age.inMinutes >= 50) await _refresh(request.url);
    if (TokenStore.token == null) return _inner.send(request);

    request.headers['Authorization'] = 'Bearer ${TokenStore.token}';
    final res = await _inner.send(request);
    if (res.statusCode == 401 && request is http.Request) {
      if (await _refresh(request.url)) {
        final retry = http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..headers['Authorization'] = 'Bearer ${TokenStore.token}'
          ..bodyBytes = request.bodyBytes;
        return _inner.send(retry);
      }
    }
    return res;
  }

  Future<bool> _refresh(Uri any) {
    _refreshFuture ??= _doRefresh(any).whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }
  static Future<void> ensureFresh(Uri any) async {
    if (TokenStore.token == null) return;
    final age =
        DateTime.now().difference(TokenStore.tokenTime ?? DateTime.now());
    if (age.inMinutes >= 50) await AuthClient()._refresh(any);
  }
  Future<bool> _doRefresh(Uri any) async {
    try {
      final login = TokenStore.loginTime;
      if (login == null || DateTime.now().difference(login).inDays >= 14) {
        await TokenStore.clear();
        onSessionExpired?.call();
        return false;
      }
      final uri = any.replace(path: '/api/refresh', query: '');
      final r = await _inner.post(uri, headers: {
        'Authorization': 'Bearer ${TokenStore.token}',
        'app-version': TokenStore.appVersion,
        'Accept': 'application/json',
      });
      if (r.statusCode == 200) {
        final decoded = jsonDecode(r.body);
        final t = decoded['token'] ??
            decoded['authorisation']?['token'] ??
            decoded['data']?['token'];
        if (t != null) {
          await TokenStore.save(t.toString());
          return true;
        }
      }
      await TokenStore.clear();
      onSessionExpired?.call();
      return false;
    } catch (_) {
      return false;
    }
  }
}