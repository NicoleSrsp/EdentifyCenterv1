import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'side_menu.dart';

class AddPatientRecordScreen extends StatefulWidget {
  final String patientId;
  final String centerId;
  final String centerName;

  const AddPatientRecordScreen({
    super.key,
    required this.patientId,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<AddPatientRecordScreen> createState() => _AddPatientRecordScreenState();
}

class _AddPatientRecordScreenState extends State<AddPatientRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _preWeightController = TextEditingController();
  final _postWeightController = TextEditingController();
  final _ufGoalController = TextEditingController();
  final _ufRemovedController = TextEditingController();
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _respirationController = TextEditingController();
  final _o2Controller = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveRecord() async {
    final Map<String, dynamic> record = {};

    void addIfNotEmpty(
      String key,
      TextEditingController controller, {
      bool isNumber = false,
    }) {
      if (controller.text.trim().isNotEmpty) {
        record[key] = isNumber
            ? double.tryParse(controller.text.trim()) ?? controller.text.trim()
            : controller.text.trim();
      }
    }

    addIfNotEmpty("preWeight", _preWeightController, isNumber: true);
    addIfNotEmpty("postWeight", _postWeightController, isNumber: true);
    addIfNotEmpty("ufGoal", _ufGoalController, isNumber: true);
    addIfNotEmpty("ufRemoved", _ufRemovedController, isNumber: true);
    addIfNotEmpty("bloodPressure", _bpController);
    addIfNotEmpty("pulseRate", _pulseController, isNumber: true);
    addIfNotEmpty("temperature", _tempController, isNumber: true);
    addIfNotEmpty("respiration", _respirationController, isNumber: true);
    addIfNotEmpty("oxygenSaturation", _o2Controller, isNumber: true);

    record["date"] = _selectedDate.toIso8601String().split("T").first;
    record["createdAt"] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.patientId)
        .collection("records")
        .doc(_selectedDate.toIso8601String().split("T").first)
        .set(record, SetOptions(merge: true));

    // 🔔 Notification logic
    try {
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .get();

      if (patientDoc.exists) {
        final doctorId = patientDoc['doctorId'];
        final firstName = patientDoc['firstName'] ?? '';
        final lastName = patientDoc['lastName'] ?? '';

        if (doctorId != null && doctorId.toString().isNotEmpty) {
          final dialysisFields = ['preWeight', 'postWeight', 'ufGoal', 'ufRemoved'];
          final vitalFields = [
            'bloodPressure',
            'pulseRate',
            'temperature',
            'respiration',
            'oxygenSaturation'
          ];

          final hasDialysis = record.keys.any((k) => dialysisFields.contains(k));
          final hasVitals = record.keys.any((k) => vitalFields.contains(k));

          String title;
          String message;
          String category;

          if (hasDialysis && hasVitals) {
            title = 'New Vitals & Dialysis Info';
            message =
                'Nurse recorded dialysis information and vital signs for $firstName $lastName.';
            category = 'vitals_and_dialysis';
          } else if (hasDialysis) {
            title = 'New Dialysis Info';
            message = 'Nurse recorded dialysis information for $firstName $lastName.';
            category = 'dialysis';
          } else if (hasVitals) {
            title = 'New Vital Signs';
            message = 'Nurse recorded vital signs for $firstName $lastName.';
            category = 'vitals';
          } else {
            title = 'New Patient Record';
            message = 'Nurse updated patient record for $firstName $lastName.';
            category = 'record';
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(doctorId)
              .collection('notifications')
              .add({
            'title': title,
            'message': message,
            'patientId': widget.patientId,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
            'category': category,
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error sending doctor notification: $e');
    }

    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.number}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade600, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF045347),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔹 Side Menu
          SideMenu(
            centerId: widget.centerId,
            centerName: widget.centerName,
            selectedMenu: "Patients",
          ),

          // 🔹 Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header (same as home_screen.dart)
                Container(
                  color: const Color(0xFF045347),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        widget.centerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ✅ Main Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Picker Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today, color: Colors.teal),
                              title: Text(
                                "Date: ${DateFormat.yMMMMd().format(_selectedDate)}",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              trailing: ElevatedButton(
                                onPressed: _pickDate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Change",
                                  style: TextStyle(color: Colors.white), // ✅ White text
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Dialysis Info
                          _buildSectionHeader("Dialysis Information", Icons.local_hospital),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildTextField("Pre-Weight (kg)", _preWeightController),
                                  _buildTextField("Post-Weight (kg)", _postWeightController),
                                  _buildTextField("UF Goal (L)", _ufGoalController),
                                  _buildTextField("UF Removed (L)", _ufRemovedController),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Vital Signs
                          _buildSectionHeader("Vital Signs", Icons.monitor_heart),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildTextField("Blood Pressure (mmHg)", _bpController),
                                  _buildTextField("Pulse Rate (bpm)", _pulseController),
                                  _buildTextField("Temperature (°C)", _tempController,
                                      keyboard: const TextInputType.numberWithOptions(decimal: true)),
                                  _buildTextField("Respiration Rate", _respirationController),
                                  _buildTextField("Oxygen Saturation (%)", _o2Controller),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 10),
        child: FloatingActionButton.extended(
          onPressed: _saveRecord,
          icon: const Icon(Icons.save),
          label: const Text(
            "Save Record",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal.shade700,
        ),
      ),
    );
  }
}
