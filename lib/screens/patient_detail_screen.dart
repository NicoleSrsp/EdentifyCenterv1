import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_patient_record_screen.dart';
import 'side_menu.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String centerId;
  final String centerName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  // 🔹 Store verified nurse after verification (used when editing)
  Map<String, dynamic>? _verifiedNurse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            centerId: widget.centerId,
            centerName: widget.centerName,
            selectedMenu: 'Patients',
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.patientId)
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("Patient not found."));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final fullName =
                      "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Header
                      Container(
                        color: const Color(0xFF045347),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        width: double.infinity,
                        child: Row(
                          children: [
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
                      const SizedBox(height: 16),

                      // 🔹 Patient Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundImage:
                                      data['profilePicUrl'] != null
                                          ? NetworkImage(data['profilePicUrl'])
                                          : const AssetImage(
                                                'assets/images/default_avatar.png',
                                              )
                                              as ImageProvider,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.cake,
                                        "Birthday",
                                        data['birthday'] ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        Icons.home,
                                        "Address",
                                        data['address'] ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        Icons.phone,
                                        "Contact",
                                        data['phone'] ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        Icons.medical_services,
                                        "Health Conditions",
                                        data['healthConditions'] ?? 'None',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 Records
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SideMenu.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Add Record",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddPatientRecordScreen(
                                              patientId: widget.patientId,
                                              centerId: widget.centerId,
                                              centerName: widget.centerName,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 🔹 Records list
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(widget.patientId)
                                        .collection("records")
                                        .orderBy("createdAt", descending: true)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                      child: Text("No records yet"),
                                    );
                                  }

                                  return ListView(
                                    padding: const EdgeInsets.all(16),
                                    children:
                                        snapshot.data!.docs.map((doc) {
                                          final record =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: ListTile(
                                              leading: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.teal.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: const Icon(
                                                  Icons.folder,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                              title: Text(
                                                "Date: ${record['date'] ?? doc.id}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Pre-Weight: ${record['preWeight'] ?? ''} | Post-Weight: ${record['postWeight'] ?? ''}",
                                                  ),
                                                  const SizedBox(height: 4),

                                                  // ✅ If record was updated, show "Updated by Nurse X"
                                                  if (record['updatedBy'] !=
                                                          null &&
                                                      record['updatedBy']
                                                          .toString()
                                                          .isNotEmpty)
                                                    Text(
                                                      "Updated by Nurse ${record['updatedBy']}",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.orange,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    )
                                                  // ✅ Else if only nurseName exists (new record), show "Added by Nurse X"
                                                  else if (record['nurseName'] !=
                                                          null &&
                                                      record['nurseName']
                                                          .toString()
                                                          .isNotEmpty)
                                                    Text(
                                                      "Added by Nurse ${record['nurseName']}",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                ],
                                              ),

                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.teal,
                                                ),
                                                tooltip: 'Edit Record',
                                                onPressed: () {
                                                  _showEditRecordDialog(
                                                    context,
                                                    widget.patientId,
                                                    doc.id,
                                                    record,
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 6),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditRecordDialog(
    BuildContext context,
    String patientId,
    String recordId,
    Map<String, dynamic> record,
  ) {
    final _formKey = GlobalKey<FormState>();

    final preWeightController = TextEditingController(
      text: record['preWeight']?.toString() ?? '',
    );
    final postWeightController = TextEditingController(
      text: record['postWeight']?.toString() ?? '',
    );
    final ufGoalController = TextEditingController(
      text: record['ufGoal']?.toString() ?? '',
    );
    final ufRemovedController = TextEditingController(
      text: record['ufRemoved']?.toString() ?? '',
    );
    final bpController = TextEditingController(
      text: record['bloodPressure']?.toString() ?? '',
    );
    final pulseController = TextEditingController(
      text: record['pulseRate']?.toString() ?? '',
    );
    final tempController = TextEditingController(
      text: record['temperature']?.toString() ?? '',
    );
    final respirationController = TextEditingController(
      text: record['respiration']?.toString() ?? '',
    );
    final o2Controller = TextEditingController(
      text: record['oxygenSaturation']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 700,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: const Color(0xFF045347),
                title: const Text(
                  "Edit Patient Record",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 10),
                      _buildSectionHeader(
                        Icons.monitor_weight,
                        "Dialysis Information",
                      ),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildEditField(
                                "Pre-Weight (kg)",
                                preWeightController,
                                width: 300,
                              ),
                              _buildEditField(
                                "Post-Weight (kg)",
                                postWeightController,
                                width: 300,
                              ),
                              _buildEditField(
                                "UF Goal (L)",
                                ufGoalController,
                                width: 300,
                              ),
                              _buildEditField(
                                "UF Removed (L)",
                                ufRemovedController,
                                width: 300,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(Icons.favorite, "Vital Signs"),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildEditField(
                                "Blood Pressure (mmHg)",
                                bpController,
                                width: 300,
                              ),
                              _buildEditField(
                                "Pulse Rate (bpm)",
                                pulseController,
                                width: 300,
                              ),
                              _buildEditField(
                                "Temperature (°C)",
                                tempController,
                                width: 300,
                              ),
                              _buildEditField(
                                "Respiration Rate",
                                respirationController,
                                width: 300,
                              ),
                              _buildEditField(
                                "Oxygen Saturation (%)",
                                o2Controller,
                                width: 300,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF045347),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // --- NEW: Require nurse verification before applying updates ---
                              final nurseInfo =
                                  await _promptNurseVerification();
                              if (nurseInfo == null) {
                                // canceled or verification failed
                                return;
                              }

                              // continue with original update logic, but include nurse info
                              final updatedData = {
                                'preWeight': preWeightController.text,
                                'postWeight': postWeightController.text,
                                'ufGoal': ufGoalController.text,
                                'ufRemoved': ufRemovedController.text,
                                'bloodPressure': bpController.text,
                                'pulseRate': pulseController.text,
                                'temperature': tempController.text,
                                'respiration': respirationController.text,
                                'oxygenSaturation': o2Controller.text,
                                'updatedAt': FieldValue.serverTimestamp(),
                                // add nurse who made the edit
                                'updatedBy': _verifiedNurse?['nurseName'],
                                'nurseName': nurseInfo['nurseName'],
                              };

                              // 🔹 Update record
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientId)
                                  .collection('records')
                                  .doc(recordId)
                                  .update(updatedData);

                              try {
                                // 🔹 Determine which fields actually changed
                                final changedFields = <String>[];
                                updatedData.forEach((key, value) {
                                  if (key != 'updatedAt' &&
                                      key != 'updatedBy' &&
                                      key != 'nurseName' &&
                                      record[key]?.toString() !=
                                          value.toString()) {
                                    changedFields.add(key);
                                  }
                                });

                                // 🔹 Make field names readable
                                final fieldNames = {
                                  'preWeight': 'Pre-Weight',
                                  'postWeight': 'Post-Weight',
                                  'ufGoal': 'UF Goal',
                                  'ufRemoved': 'UF Removed',
                                  'bloodPressure': 'Blood Pressure',
                                  'pulseRate': 'Pulse Rate',
                                  'temperature': 'Temperature',
                                  'respiration': 'Respiration',
                                  'oxygenSaturation': 'Oxygen Saturation',
                                };

                                final readableChanges =
                                    changedFields
                                        .map((key) => fieldNames[key] ?? key)
                                        .toList();

                                // 🔹 Format nicely: “A, B and C”
                                String formattedFields;
                                if (readableChanges.isEmpty) {
                                  formattedFields = '';
                                } else if (readableChanges.length == 1) {
                                  formattedFields = readableChanges.first;
                                } else {
                                  formattedFields =
                                      readableChanges
                                          .sublist(
                                            0,
                                            readableChanges.length - 1,
                                          )
                                          .join(', ') +
                                      ' and ' +
                                      readableChanges.last;
                                }

                                // 🔹 Compose message
                                final message =
                                    changedFields.isEmpty
                                        ? 'Nurse ${_verifiedNurse?['nurseName']} saved your dialysis record today.'
                                        : 'Nurse ${_verifiedNurse?['nurseName']} updated your $formattedFields today.';

                                // 🔹 Send patient notification
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(patientId)
                                    .collection('notifications')
                                    .add({
                                      'title':
                                          changedFields.isEmpty
                                              ? 'Dialysis Record Saved'
                                              : 'Dialysis Record Updated',
                                      'message': message,
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'read': false,
                                    });

                                // 🔹 Notify assigned doctor (if any)
                                final patientDoc =
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(patientId)
                                        .get();

                                if (patientDoc.exists &&
                                    patientDoc.data()!.containsKey(
                                      'doctorId',
                                    )) {
                                  final doctorId = patientDoc['doctorId'];
                                  if (doctorId != null &&
                                      doctorId.toString().isNotEmpty) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(doctorId)
                                        .collection('notifications')
                                        .add({
                                          'title': 'Dialysis Record Updated',
                                          'message':
                                              'Nurse ${_verifiedNurse?['nurseName']} updated $formattedFields for ${patientDoc['firstName']} ${patientDoc['lastName']}.',
                                          'patientId': patientId,
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'read': false,
                                          'changedFields': changedFields,
                                        });
                                  }
                                }
                              } catch (e) {
                                debugPrint(
                                  '⚠️ Error sending notifications: $e',
                                );
                              }

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Record updated successfully',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.number,
    double width = double.infinity,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal.shade700, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ------------------- Nurse verification helper -------------------
  // Fetches nurses under center, shows dialog (select nurse + enter PIN),
  // returns a Map { 'nurseId': id, 'nurseName': name } if verified, otherwise null.
  Future<Map<String, dynamic>?> _promptNurseVerification() async {
    final nursesRef = FirebaseFirestore.instance
        .collection('centers')
        .doc(widget.centerId)
        .collection('nurses');

    final nurseDocs = await nursesRef.get();
    final nurseList =
        nurseDocs.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    String? selectedNurseId;
    final pinController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nurse Verification"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Nurse"),
                items:
                    nurseList.map((nurse) {
                      return DropdownMenuItem<String>(
                        value: nurse['id'] as String?,
                        child: Text(nurse['name'] ?? (nurse['id'] as String)),
                      );
                    }).toList(),
                onChanged: (value) => selectedNurseId = value,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Enter PIN"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context, null),
            ),
            ElevatedButton(
              child: const Text("Verify"),
              onPressed: () async {
                if (selectedNurseId == null || pinController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select nurse and enter PIN"),
                    ),
                  );
                  return;
                }

                final nurseDoc = await nursesRef.doc(selectedNurseId).get();
                if (nurseDoc.exists &&
                    nurseDoc['pin'] == pinController.text.trim()) {
                  Navigator.pop(context, {
                    'nurseId': selectedNurseId,
                    'nurseName': nurseDoc['name'],
                  });
                  return;
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Invalid PIN")));
                }
              },
            ),
          ],
        );
      },
    );

    // Save locally for display if needed
    if (result != null) {
      setState(() => _verifiedNurse = result);
    }

    return result;
  }
}
