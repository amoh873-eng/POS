import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.onLogin});
  final ApiClient api;
  final VoidCallback onLogin;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'admin@demo.com');
  final _pass = TextEditingController(text: 'Admin@123');
  bool _loading = false;
  String? _err;
  Future<void> _login() async {
    setState(() { _loading = true; _err = null; });
    try {
      final res = await widget.api.post('/api/auth/login', {'email': _email.text, 'password': _pass.text});
      if (res['data'] != null && res['data']['access_token'] != null) {
        widget.api.token = res['data']['access_token'];
        widget.onLogin();
      } else {
        setState(() => _err = res.toString());
      }
    } catch (e) { setState(() => _err = e.toString()); }
    setState(() => _loading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('POS Cloud', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
        if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'))),
      ]))))),
    );
  }
}
