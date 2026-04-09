import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rider_auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _otpSent = false;
  String? _demoOtp;

  String get _cleanPhone => _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<RiderAuthProvider>();
    final otp = await auth.requestOtp(
      _cleanPhone,
      name: _nameCtrl.text.trim(),
    );
    if (!mounted || otp == null) return;

    setState(() {
      _otpSent = true;
      _demoOtp = otp;
    });
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<RiderAuthProvider>();
    final ok = await auth.verifyOtp(
      phone: _cleanPhone,
      otp: _otpCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
    );

    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<RiderAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0E8A39),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 72),
                const SizedBox(height: 18),
                const Text(
                  'Rider App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Register with your mobile number and verify with OTP before going online.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 36),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _otpSent ? 'Verify OTP' : 'Rider Registration',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _otpSent
                              ? 'Enter the OTP sent to your rider phone number.'
                              : 'Create or reopen your rider account with your mobile number.',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().length < 2) ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          enabled: !_otpSent,
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone_android_outlined),
                            prefixText: '+91 ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.replaceAll(RegExp(r'\D'), '').length != 10)
                                  ? 'Enter valid 10-digit phone number'
                                  : null,
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: 'OTP',
                              prefixIcon: const Icon(Icons.verified_user_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) => _otpSent && (value == null || value.trim().length != 6)
                                ? 'Enter 6-digit OTP'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (_demoOtp != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4FAF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFB8E4BF)),
                            ),
                            child: Text(
                              'Demo OTP: $_demoOtp',
                              style: const TextStyle(
                                color: Color(0xFF0C831F),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (auth.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: auth.loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E8A39),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _otpSent ? 'Verify And Continue' : 'Send OTP',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: auth.loading
                                ? null
                                : () {
                                    auth.clearError();
                                    setState(() {
                                      _otpSent = false;
                                      _otpCtrl.clear();
                                      _demoOtp = null;
                                    });
                                  },
                            child: const Text('Change phone number'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}