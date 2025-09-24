import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edentifyweb/screens/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String? _centerId;
  String? _centerName;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check Firebase Auth current user
    _currentUser = FirebaseAuth.instance.currentUser;

    // 2. Check stored center info
    _centerId = prefs.getString('centerId');
    _centerName = prefs.getString('centerName');

    if (_currentUser != null && _centerId != null && _centerName != null) {
      // 3. Fetch first login info from Firestore
      final doc = await FirebaseFirestore.instance.collection('centers').doc(_centerId).get();
      final data = doc.data();

      bool isFirstLogin = true;
      if (data != null && data.containsKey('isFirstLogin')) {
        isFirstLogin = data['isFirstLogin'] as bool;
      }

      if (isFirstLogin) {
        _navigateTo('/changePassword');
        return;
      } else {
        _navigateTo('/home');
        return;
      }
    }

    setState(() => _isLoading = false);
  }

  void _navigateTo(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, route, arguments: {
        'centerId': _centerId,
        'centerName': _centerName,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 4. If not logged in or center not selected, show landing/selection
    return const LandingPage(); // Or CenterSelectionScreen if you want to skip landing
  }
}
