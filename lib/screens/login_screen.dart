import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CenterLoginScreen extends StatefulWidget {
  final String centerName;
  final String centerId;

  const CenterLoginScreen({super.key,  required this.centerName, required this.centerId});

  @override
  State<CenterLoginScreen> createState() => _CenterLoginScreenState();
}

class _CenterLoginScreenState extends State<CenterLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorText = '';
  int _loginAttempts = 0;
  bool _accountLocked = false;
  String _centerName = '';

  @override
  void initState() {
    super.initState();
    _fetchCenterName();
  }

  Future<void> _fetchCenterName() async {
    final doc = await FirebaseFirestore.instance
        .collection('centers')
        .doc(widget.centerId)
        .get();
    if (doc.exists) {
      setState(() {
        _centerName = (doc.data() as Map<String, dynamic>)['name'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _accountLocked) return;

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    try {
      // 1. Check if center user exists by centerId
      final docRef = FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId);

      final doc = await docRef.get();

      if (!doc.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No center account found.',
        );
      }

      final userData = doc.data() as Map<String, dynamic>;
      final isFirstLogin = userData['isFirstLogin'] ?? true;
      final isLocked = userData['isLocked'] ?? false;

      if (isLocked || _loginAttempts >= 3) {
        await _lockAccount(widget.centerId);
        throw FirebaseAuthException(
            code: 'account-locked',
            message: 'Account locked. Contact administrator.');
      }

      // 2. Authenticate using Firebase Auth
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Create new account if not exists
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          throw e;
        }
      }

      // Reset login attempts
      _loginAttempts = 0;

      // Navigate based on first login
      if (isFirstLogin) {
        Navigator.pushReplacementNamed(
          context,
          '/changePassword',
          arguments: {
            'centerId': widget.centerId,
            'centerName': _centerName,
          },
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'centerId': widget.centerId, 'centerName': _centerName},
        );
      }
    } on FirebaseAuthException catch (e) {
      _loginAttempts++;
      setState(() {
        _errorText = e.message ?? 'Login failed';
        if (_loginAttempts >= 3) _accountLocked = true;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Login failed: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _lockAccount(String centerId) async {
    await FirebaseFirestore.instance
        .collection('centers')
        .doc(centerId)
        .update({'isLocked': true, 'lockedAt': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/background.png', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _centerName.isEmpty
                            ? "Logging in..."
                            : "Logging into: $_centerName",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      if (_errorText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[900]?.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorText,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _accountLocked ? Colors.grey : Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _accountLocked ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'LOG IN',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
