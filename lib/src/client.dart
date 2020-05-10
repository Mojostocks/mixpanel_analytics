import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mixpanel_analytics/src/event.dart';

class Client {
  factory Client(String token) {
    if (_instances.containsKey(token)) {
      return _instances[token];
    }
    _instances[token] = Client._internal(token);
    return _instances[token];
  }

  Client._internal(this.token);

  static const String apiUrl = 'https://api.mixpanel.com';
  static final Map<String, Client> _instances = {};

  final String token;

  Future<int> post(List<Event> events, String operation) async {
    final List<Map<String, dynamic>> payload = events.map((e) => e.toPayload(token)).toList();
    String data = _base64Encoder(payload);

    try {
      final response = await http.post(
        '$apiUrl/$operation',
        headers: {
          'Content-type': 'application/x-www-form-urlencoded',
        },
        body: {
          'data': data,
        },
      );
      return response.statusCode;
    } catch (e) {
      return 500;
    }
  }

  String _base64Encoder(Object event) {
    var str = json.encode(event);
    var bytes = utf8.encode(str);
    var base64 = base64Encode(bytes);
    return base64;
  }
}
