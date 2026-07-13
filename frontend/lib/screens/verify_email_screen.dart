import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles /verify?token=UUID links sent in confirmation emails.
class VerifyEmailScreen extends StatefulWidget {
  final String token;
  const VerifyEmailScreen({super.key, required this.token});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _loading = true;
  bool _success = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      final result = await Supabase.instance.client
          .rpc('verify_email', params: {'token': widget.token});
      setState(() {
        _success = result == true;
        _message = _success
            ? 'Your email has been verified. Thank you!'
            : 'This link is invalid or has expired.';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _message = 'Verification failed. Please request a new link.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _success
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 72,
                      color: _success ? colorScheme.primary : Colors.red,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _success ? 'Email Verified' : 'Verification Failed',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/dashboard'),
                      child: const Text('Go to Dashboard'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
