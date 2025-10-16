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

  // 🔹 Store nurse info after verification
  Map<String, dynamic>? _verifiedNurse;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // 🔹 Show nurse verification dialog
  Future<Map<String, dynamic>?> _showNurseVerificationDialog() async {
    final TextEditingController pinController = TextEditingController();
    String? selectedNurse;
    List<QueryDocumentSnapshot> nurseDocs = [];

    // Fetch nurses under this center
    final snapshot =
        await FirebaseFirestore.instance
            .collection('centers')
            .doc(widget.centerId)
            .collection('nurses')
            .get();

    nurseDocs = snapshot.docs;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nurse Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Nurse'),
                items:
                    nurseDocs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                onChanged: (value) => selectedNurse = value,
              ),
              TextField(
                controller: pinController,
                decoration: const InputDecoration(labelText: 'Enter PIN'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedNurse == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a nurse')),
                  );
                  return;
                }

                final nurseDoc = nurseDocs.firstWhere(
                  (doc) => doc.id == selectedNurse,
                  orElse: () => throw Exception('Nurse not found'),
                );

                if (nurseDoc['pin'] == pinController.text.trim()) {
                  Navigator.pop(context, {
                    'nurseId': nurseDoc.id,
                    'nurseName': nurseDoc['name'],
                  });
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Invalid PIN')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
              ),
              child: const Text(
                'Verify',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRecord() async {
    // 🧩 Require nurse verification first
    if (_verifiedNurse == null) {
      final nurseInfo = await _showNurseVerificationDialog();
      if (nurseInfo == null) return; // cancelled
      setState(() => _verifiedNurse = nurseInfo);
    }

    final Map<String, dynamic> record = {};

    void addIfNotEmpty(
      String key,
      TextEditingController controller, {
      bool isNumber = false,
    }) {
      if (controller.text.trim().isNotEmpty) {
        record[key] =
            isNumber
                ? double.tryParse(controller.text.trim()) ??
                    controller.text.trim()
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

    // 🧩 Include nurse info
    record["enteredBy"] = _verifiedNurse;
    record["nurseName"] = _verifiedNurse?['nurseName']; // ✅ add for visibility

    final recordRef = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.patientId)
        .collection("records")
        .doc(_selectedDate.toIso8601String().split("T").first);

    final existingRecord = await recordRef.get();
    final isUpdate = existingRecord.exists;

    await recordRef.set(record, SetOptions(merge: true));

    // 🟢 Patient notification (now includes type + recordDate)
    try {
      String title;
      String message;

      if (!isUpdate) {
        title = "New Dialysis Record Added";
        message =
            "Nurse ${_verifiedNurse?['nurseName'] ?? ''} added your dialysis record for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}.";
      } else {
        title = "Dialysis Record Updated";
        message =
            "Nurse ${_verifiedNurse?['nurseName'] ?? ''} updated your dialysis record for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}.";
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId.trim())
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'treatment_record', // 🧩 Added field for navigation
            'recordDate':
                _selectedDate
                    .toIso8601String()
                    .split('T')
                    .first, // 🧩 yyyy-MM-dd
          });

      debugPrint("✅ Notification added for user ${widget.patientId}");
    } catch (e) {
      debugPrint("⚠️ Error sending patient notification: $e");
    }

    // 🟣 Doctor notification
    try {
      final patientDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.patientId)
              .get();

      if (patientDoc.exists && patientDoc.data()!.containsKey('doctorId')) {
        final doctorId = patientDoc['doctorId'];
        final firstName = patientDoc['firstName'] ?? '';
        final lastName = patientDoc['lastName'] ?? '';

        if (doctorId != null && doctorId.toString().isNotEmpty) {
          final dialysisFields = [
            'preWeight',
            'postWeight',
            'ufGoal',
            'ufRemoved',
          ];
          final vitalFields = [
            'bloodPressure',
            'pulseRate',
            'temperature',
            'respiration',
            'oxygenSaturation',
          ];

          final hasDialysis = record.keys.any(
            (k) => dialysisFields.contains(k),
          );
          final hasVitals = record.keys.any((k) => vitalFields.contains(k));

          String title;
          String message;
          String category;

          if (!isUpdate) {
            if (hasDialysis && hasVitals) {
              title = 'New Dialysis Record Added';
              message =
                  'Nurse ${_verifiedNurse?['nurseName'] ?? ''} added dialysis information and vital signs for $firstName $lastName.';
              category = 'vitals_and_dialysis';
            } else if (hasDialysis) {
              title = 'New Dialysis Record Added';
              message =
                  'Nurse ${_verifiedNurse?['nurseName'] ?? ''} added dialysis information for $firstName $lastName.';
              category = 'dialysis';
            } else if (hasVitals) {
              title = 'New Vital Signs Added';
              message =
                  'Nurse ${_verifiedNurse?['nurseName'] ?? ''} added vital signs for $firstName $lastName.';
              category = 'vitals';
            } else {
              title = 'New Patient Record Added';
              message =
                  'Nurse ${_verifiedNurse?['nurseName'] ?? ''} added a new record for $firstName $lastName.';
              category = 'record';
            }
          } else {
            title = 'Dialysis Record Updated';
            message =
                'Nurse ${_verifiedNurse?['nurseName'] ?? ''} updated dialysis record for $firstName $lastName.';
            category = 'record_update';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Record saved successfully',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType keyboard = TextInputType.number,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon:
              icon != null
                  ? Container(
                    margin: const EdgeInsets.only(right: 8, left: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.teal.shade700, size: 22),
                  )
                  : null,
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.teal.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade200, width: 1.5),
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
          SideMenu(
            centerId: widget.centerId,
            centerName: widget.centerName,
            selectedMenu: "Patients",
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.calendar_today,
                                color: Colors.teal,
                              ),
                              title: Text(
                                "Date: ${DateFormat.yMMMMd().format(_selectedDate)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
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
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSectionHeader(
                            "Dialysis Information",
                            Icons.local_hospital,
                          ),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide =
                                      constraints.maxWidth >
                                      600; // responsive layout
                                  return Wrap(
                                    spacing: 20,
                                    runSpacing: 10,
                                    children: [
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "Pre-Weight (kg)",
                                          _preWeightController,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "Post-Weight (kg)",
                                          _postWeightController,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "UF Goal (L)",
                                          _ufGoalController,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "UF Removed (L)",
                                          _ufRemovedController,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            "Vital Signs",
                            Icons.monitor_heart,
                          ),
                          const SizedBox(height: 10),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 600;
                                  return Wrap(
                                    spacing: 20,
                                    runSpacing: 10,
                                    children: [
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "Blood Pressure (mmHg)",
                                          _bpController,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "Pulse Rate (bpm)",
                                          _pulseController,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "Temperature (°C)",
                                          _tempController,
                                          keyboard:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "Respiration Rate",
                                          _respirationController,
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            isWide
                                                ? constraints.maxWidth / 2 - 20
                                                : double.infinity,
                                        child: _buildTextField(
                                          "Oxygen Saturation (%)",
                                          _o2Controller,
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
