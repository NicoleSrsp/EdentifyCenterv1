import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CenterLoginScreen extends StatefulWidget {
  final String centerName;
  final String centerId;

  const CenterLoginScreen({
    super.key,
    required this.centerName,
    required this.centerId,
  });

  @override
  State<CenterLoginScreen> createState() => _CenterLoginScreenState();
}

class _CenterLoginScreenState extends State<CenterLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorText = '';
  int _loginAttempts = 0;
  bool _accountLocked = false;
  String _centerName = '';

  @override
  void initState() {
    super.initState();
    // Use a single initialization function to prevent race conditions.
    _initializeScreen();
  }

  /// Handles the screen's initial setup to avoid race conditions between
  /// fetching data and checking the current user's auth state.
  Future<void> _initializeScreen() async {
    // 1. Fetch the center name first, as it's needed later.
    await _fetchCenterName();

    // 2. IMPORTANT: After an async gap, check if the widget is still mounted
    //    before proceeding to avoid calling setState on a disposed widget.
    if (!mounted) return;

    // 3. Now that the center name is available, check for a persistent login.
    await _checkCurrentUser();
  }

  /// Fetches the center's name from Firestore to display on the UI.
  Future<void> _fetchCenterName() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('centers')
              .doc(widget.centerId)
              .get();

      if (doc.exists) {
        setState(() {
          _centerName =
              (doc.data() as Map<String, dynamic>)['name'] ?? widget.centerName;
        });
      } else {
        setState(() {
          _centerName = widget.centerName; // Fallback to initial name
        });
      }
    } catch (e) {
      // If fetching fails, use the name passed to the widget as a fallback.
      setState(() {
        _centerName = widget.centerName;
        _errorText = "Could not verify center name.";
      });
    }
  }

  /// Checks if a user is already signed in. If so, navigates them to the home screen.
  Future<void> _checkCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is already logged in, proceed to home screen.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('centerId', widget.centerId);
      await prefs.setString('centerName', _centerName);

      // Another mounted check is crucial before navigation.
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (Route<dynamic> route) =>
            false, // This predicate removes all previous routes
        arguments: {'centerId': widget.centerId, 'centerName': _centerName},
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the user login logic.
  Future<void> _login() async {
    // Don't proceed if the form is invalid or the account is locked.
    if (!_formKey.currentState!.validate() || _accountLocked) return;

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    try {
      // Step 1: Get the center's data from Firestore first.
      final docRef = FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('No center account found for this ID.');
      }

      final userData = doc.data() as Map<String, dynamic>;
      final isFirstLogin = userData['isFirstLogin'] ?? true;
      final isLocked = userData['isLocked'] ?? false;

      // Step 2: Check if the account is locked from the database.
      if (isLocked) {
        setState(() => _accountLocked = true);
        throw Exception('Account locked. Please contact an administrator.');
      }

      // Step 3: Attempt to sign in with Firebase Auth.
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } on FirebaseAuthException {
        // --- CRITICAL SECURITY FIX ---
        // DO NOT create a new user if sign-in fails. Treat any auth error
        // as a failed login attempt. This prevents malicious account creation.
        _loginAttempts++;
        if (_loginAttempts >= 3) {
          setState(() => _accountLocked = true);
          // NOTE: This is client-side locking. A user can bypass this by
          // restarting the app. For true security, this logic should be
          // handled server-side (e.g., Cloud Functions).
          await _lockAccountInFirestore(widget.centerId);
        }
        throw Exception('Invalid email or password.');
      }

      // Step 4: Login successful. Reset attempts and save session data.
      _loginAttempts = 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('centerId', widget.centerId);
      await prefs.setString('centerName', _centerName);

      if (!mounted) return;

      // Step 5: Navigate to the appropriate screen.
      if (isFirstLogin) {
        Navigator.pushReplacementNamed(
          context,
          '/changePassword',
          arguments: {'centerId': widget.centerId, 'centerName': _centerName},
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (Route<dynamic> route) => false,
          arguments: {'centerId': widget.centerId, 'centerName': _centerName},
        );
      }
    } catch (e) {
      // Generic catch block to display any errors from the process.
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      // Ensure the loading indicator is always turned off.
      setState(() => _isLoading = false);
    }
  }

  /// Updates the lock status in Firestore.
  Future<void> _lockAccountInFirestore(String centerId) async {
    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(centerId)
          .update({'isLocked': true, 'lockedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      // Silently fail or log error. Don't let this block the user.
      debugPrint("Failed to lock account in Firestore: $e");
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
                        _centerName.isEmpty
                            ? "Loading Center..."
                            : "Log in to $_centerName",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
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
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
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
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
                              color: Colors.red[800]?.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
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
                                _accountLocked
                                    ? Colors.grey[600]
                                    : Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              _accountLocked || _isLoading ? null : _login,
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    _accountLocked
                                        ? 'ACCOUNT LOCKED'
                                        : 'LOG IN',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
