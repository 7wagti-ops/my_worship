import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final Future<String?> Function(String email) onSubmit;
  const LoginScreen({super.key, required this.onSubmit});
  @override
  State<LoginScreen> createState() => _S();
}

class _S extends State<LoginScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _err;

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final email = _ctrl.text.trim().toLowerCase();
    if (!email.endsWith('@gmail.com')) {
      setState(() => _err = t.t('gmail_only'));
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    final e = await widget.onSubmit(email);
    if (mounted) setState(() { _loading = false; _err = e; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                t.t('app_name'),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t.t('email'),
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_err!,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(t.t('enter')),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final r = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupScreen(onSubmit: widget.onSubmit),
                    ),
                  );
                  if (r != null && mounted) _ctrl.text = r;
                },
                child: Text(t.t('create_new_account')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
