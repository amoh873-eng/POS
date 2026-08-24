import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  String? token;
  ApiClient(this.baseUrl);

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) async {
    final r = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    return jsonDecode(r.body);
  }

  Future<dynamic> post(String path, dynamic body, {Map<String, String>? extraHeaders}) async {
    final h = {...headers, ...?extraHeaders};
    final r = await http.post(Uri.parse('$baseUrl$path'), headers: h, body: jsonEncode(body));
    return jsonDecode(r.body);
  }
}
