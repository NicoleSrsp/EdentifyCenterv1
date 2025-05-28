import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorLoginScreen extends StatefulWidget {
  final String centerName;
  final String doctorName;

  const DoctorLoginScreen({
    super.key,
    required this.centerName,
    required this.doctorName,
  });

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorText = '';
  bool _obscurePassword = true;
  int _loginAttempts = 0;
  bool _accountLocked = false;

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
      // 1. Verify doctor exists in Firestore
      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('doctor_inCharge')
          .where('name', isEqualTo: widget.doctorName)
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (doctorSnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'doctor-not-found',
          message: 'No doctor found with these credentials',
        );
      }

      final doc = doctorSnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final doctorId = doc.id;
      final isFirstLogin = data['isFirstLogin'] ?? false;

      // 2. Check if account is locked
      if (_loginAttempts >= 3 || (data['isLocked'] ?? false)) {
        await _lockAccount(doctorId);
        throw FirebaseAuthException(
          code: 'account-locked',
          message: 'Account locked. Please contact administrator.',
        );
      }

      // 3. Authenticate with Firebase Auth
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Create auth user if missing (but exists in Firestore)
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          throw e;
        }
      }

      // 4. Reset login attempts on success
      _loginAttempts = 0;

      // 5. Navigate based on first login status
      if (isFirstLogin) {
        Navigator.pushReplacementNamed(
          context,
          '/change-password',
          arguments: {
            'doctorId': doctorId,
            'centerName': widget.centerName,
            'doctorName': widget.doctorName,
          },
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'centerName': widget.centerName,
            'doctorName': widget.doctorName,
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      _loginAttempts++;
      setState(() {
        _errorText = _getErrorMessage(e.code);
        if (_loginAttempts >= 3) {
          _accountLocked = true;
        }
      });
    } catch (e) {
      setState(() {
        _errorText = 'Login failed: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _lockAccount(String doctorId) async {
    await FirebaseFirestore.instance
        .collection('doctor_inCharge')
        .doc(doctorId)
        .update({'isLocked': true, 'lockedAt': FieldValue.serverTimestamp()});
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'Account disabled';
      case 'user-not-found':
      case 'doctor-not-found':
        return 'Doctor not found';
      case 'wrong-password':
        return 'Incorrect password. ${3 - _loginAttempts} attempts remaining';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'account-locked':
        return 'Account locked. Contact administrator';
      default:
        return 'Login failed (code: $code)';
    }
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
                        "Logging into: ${widget.centerName}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Doctor: ${widget.doctorName}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
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
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
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
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
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
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
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
                            backgroundColor:
                                _accountLocked ? Colors.grey : Colors.white,
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _accountLocked
                            ? null
                            : () {
                                FirebaseAuth.instance
                                    .sendPasswordResetEmail(
                                  email: _emailController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset email sent'),
                                  ),
                                );
                              },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.white),
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
