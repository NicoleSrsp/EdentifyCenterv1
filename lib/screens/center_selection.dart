import 'package:flutter/material.dart';

class CenterSelectionScreen extends StatefulWidget {
  const CenterSelectionScreen({super.key});

  @override
  State<CenterSelectionScreen> createState() => _CenterSelectionScreenState();
}

class _CenterSelectionScreenState extends State<CenterSelectionScreen> {
  String? selectedCenter;

  final List<String> centers = [
    'R&B Dialysis Center',
    'USWAG Dialysis Center - Molo Branch',
    'USWAG Dialysis Center - San Isidro Branch',
  ];

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
              padding: const EdgeInsets.symmetric(horizontal: 24.0), // horizontal margin
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400), // max width of the form
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCenter,
                        hint: const Text("Select Dialysis Center"),
                        underline: const SizedBox(),
                        items: centers.map((center) {
                          return DropdownMenuItem(
                            value: center,
                            child: Text(center),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCenter = value;
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
                      onPressed: selectedCenter == null
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                '/login',
                                arguments: selectedCenter,
                              );
                            },
                      child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
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
