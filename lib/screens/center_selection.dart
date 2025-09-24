import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CenterSelectionScreen extends StatefulWidget {
  const CenterSelectionScreen({super.key});

  @override
  State<CenterSelectionScreen> createState() => _CenterSelectionScreenState();
}

class _CenterSelectionScreenState extends State<CenterSelectionScreen> {
  List<Map<String, dynamic>> centers = [];
  String? selectedDialysisCenter;
  String? selectedCenterId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPersistentLogin();
    fetchCenters();
  }

  Future<void> fetchCenters() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('centers').get();
      setState(() {
        centers = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'centerName': data['name'],
            'centerId': doc.id,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch centers: $e')),
      );
    }
  }

  // Check persistent login
  Future<void> _checkPersistentLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final centerId = prefs.getString('centerId');
    final centerName = prefs.getString('centerName');
    final user = FirebaseAuth.instance.currentUser;

    if (centerId != null && centerName != null && user != null) {
      // User is logged in and center selected → navigate to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'centerId': centerId, 'centerName': centerName},
        );
      });
    }
  }

  Future<void> _saveSelectedCenter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('centerId', selectedCenterId!);
    await prefs.setString('centerName', selectedDialysisCenter!);
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
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Welcome to Edentify,",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Please select your dialysis center to continue.",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedDialysisCenter,
                              hint: const Text("Select Dialysis Center"),
                              underline: const SizedBox(),
                              items: centers.map<DropdownMenuItem<String>>((center) {
                                return DropdownMenuItem<String>(
                                  value: center['centerName'] as String,
                                  child: Text(center['centerName'] as String),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDialysisCenter = value;
                                  selectedCenterId = centers
                                      .firstWhere((c) => c['centerName'] == value)['centerId'] as String;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                            ),
                            onPressed: (selectedDialysisCenter == null || selectedCenterId == null)
                                ? null
                                : () async {
                                    await _saveSelectedCenter();
                                    Navigator.pushNamed(
                                      context,
                                      '/login',
                                      arguments: {
                                        'centerName': selectedDialysisCenter,
                                        'centerId': selectedCenterId,
                                      },
                                    );
                                  },
                            child: const Text(
                              "Continue",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
