import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPatientRecordScreen extends StatefulWidget {
  final String patientId;

  const AddPatientRecordScreen({super.key, required this.patientId});

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

    Navigator.pop(context); // go back to PatientDetailScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Patient Record"), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _preWeightController, decoration: const InputDecoration(labelText: "Pre-Weight")),
              TextFormField(controller: _postWeightController, decoration: const InputDecoration(labelText: "Post-Weight")),
              TextFormField(controller: _ufGoalController, decoration: const InputDecoration(labelText: "UF Goal")),
              TextFormField(controller: _ufRemovedController, decoration: const InputDecoration(labelText: "UF Removed")),
              TextFormField(controller: _bpController, decoration: const InputDecoration(labelText: "Blood Pressure")),
              TextFormField(controller: _pulseController, decoration: const InputDecoration(labelText: "Pulse Rate")),
              TextFormField(controller: _tempController, decoration: const InputDecoration(labelText: "Temperature")),
              TextFormField(controller: _respirationController, decoration: const InputDecoration(labelText: "Respiration")),
              TextFormField(controller: _o2Controller, decoration: const InputDecoration(labelText: "Oxygen Saturation")),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text("Save Record"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
