import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/data_exception.dart';

/// Tüm HTTP hatalarını [DataSourceException]'a çeviren ince JSON istemcisi.
class JsonClient {
  JsonClient({http.Client? client, this.timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  Future<dynamic> getJson(Uri uri) async {
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const DataSourceException(DataErrorKind.timeout);
    } catch (e) {
      throw DataSourceException(DataErrorKind.network, e.runtimeType.toString());
    }
    if (res.statusCode == 429) {
      throw const DataSourceException(DataErrorKind.rateLimit);
    }
    if (res.statusCode >= 500) {
      throw DataSourceException(DataErrorKind.server, 'HTTP ${res.statusCode}');
    }
    if (res.statusCode != 200) {
      throw DataSourceException(
          DataErrorKind.invalidResponse, 'HTTP ${res.statusCode}');
    }
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw const DataSourceException(
          DataErrorKind.invalidResponse, 'JSON çözümlenemedi');
    }
  }
}
