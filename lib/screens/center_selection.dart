import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CenterSelectionScreen extends StatefulWidget {
  const CenterSelectionScreen({super.key});

  @override
  State<CenterSelectionScreen> createState() => _CenterSelectionScreenState();
}

class _CenterSelectionScreenState extends State<CenterSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedDialysisCenter;
  String? selectedDoctor;

  // Map of centers to their doctors
  final Map<String, List<String>> centerDoctors = {
    'R&B Dialysis Center': ['Dr. Rebecca Santos', 'Dr. Enrique Navarro'],
    'RSI Dialysis Center': ['Dr. James Chua', 'Dr. Timothy Ong'],
    'Hartman Dialysis Center': ['Dr. Andres Gomez', 'Dr. Melissa Tan'],
  };

  List<String> availableDoctors = [];
  bool showDoctorDropdown = false;

  void _onCenterSelected(String? value) {
    setState(() {
      selectedDialysisCenter = value;
      selectedDoctor = null;
      availableDoctors = value != null ? centerDoctors[value]! : [];
      showDoctorDropdown = value != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/logo.png', height: 60),
              ],
            ),
          ),
          Center(
            child: Padding(
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
                      "Dialysis Center",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    // Center Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedDialysisCenter,
                        hint: const Text("Select Dialysis Center"),
                        underline: const SizedBox(),
                        items: centerDoctors.keys.map((center) {
                          return DropdownMenuItem(
                            value: center,
                            child: Text(center),
                          );
                        }).toList(),
                        onChanged: _onCenterSelected,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Doctor Dropdown (only shown when center is selected)
                    if (showDoctorDropdown)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedDoctor,
                          hint: const Text("Select Doctor"),
                          underline: const SizedBox(),
                          items: availableDoctors.map((doctor) {
                            return DropdownMenuItem(
                              value: doctor,
                              child: Text(doctor),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDoctor = value;
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 18),
                      ),
                      onPressed: selectedDoctor == null
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/login',
                                arguments: {
                                  'centerName': selectedDialysisCenter,
                                  'doctorName': selectedDoctor,
                                },
                              );
                            },
                      child: const Text("Continue",
                          style: TextStyle(fontWeight: FontWeight.bold)),
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