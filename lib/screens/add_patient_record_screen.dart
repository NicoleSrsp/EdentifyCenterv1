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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final record = {
      "preWeight": _preWeightController.text,
      "postWeight": _postWeightController.text,
      "ufGoal": _ufGoalController.text,
      "ufRemoved": _ufRemovedController.text,
      "bloodPressure": _bpController.text,
      "pulseRate": _pulseController.text,
      "temperature": _tempController.text,
      "respiration": _respirationController.text,
      "oxygenSaturation": _o2Controller.text,
      "date": _selectedDate.toIso8601String().split("T").first,
      "createdAt": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.patientId)
        .collection("records")
        .doc(_selectedDate.toIso8601String().split("T").first)
        .set(record);

    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.number}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (val) =>
            val == null || val.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
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
            selectedMenu: "Patients", // ✅ highlight Patients since record belongs there
          ),

          // 🔹 Main Content
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Add Patient Record"),
                backgroundColor: Colors.teal,
                elevation: 2,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Date Section
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.teal),
                          title: Text(
                              "Date: ${DateFormat.yMMMd().format(_selectedDate)}"),
                          trailing: TextButton(
                            onPressed: _pickDate,
                            child: const Text("Change"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Dialysis Info Section
                      Text("Dialysis Information",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _buildTextField(
                                  "Pre-Weight (kg)", _preWeightController),
                              _buildTextField(
                                  "Post-Weight (kg)", _postWeightController),
                              _buildTextField("UF Goal (L)", _ufGoalController),
                              _buildTextField(
                                  "UF Removed (L)", _ufRemovedController),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vital Signs Section
                      Text("Vital Signs",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _buildTextField(
                                  "Blood Pressure (mmHg)", _bpController),
                              _buildTextField(
                                  "Pulse Rate (bpm)", _pulseController),
                              _buildTextField(
                                  "Temperature (°C)", _tempController,
                                  keyboard: const TextInputType.numberWithOptions(
                                      decimal: true)),
                              _buildTextField(
                                  "Respiration Rate", _respirationController),
                              _buildTextField(
                                  "Oxygen Saturation (%)", _o2Controller),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _saveRecord,
                backgroundColor: Colors.teal,
                icon: const Icon(Icons.save),
                label: const Text("Save Record"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
