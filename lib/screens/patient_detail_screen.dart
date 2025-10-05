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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔹 Left Side Menu
          SideMenu(
            centerId: widget.centerId,
            centerName: widget.centerName,
            selectedMenu: 'Patients',
          ),

          // 🔹 Main Content
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
                      // ✅ Consistent Header Bar (same as HomeScreen)
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

                      const SizedBox(height: 16),

                      // 🔹 Patient Info Card
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

                      // 🔹 Records Section
                      Expanded(
                        child: Column(
                          children: [
                            // ➕ Add Record Button
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

                            // 📋 Records List
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
                                              subtitle: Text(
                                                "Pre-Weight: ${record['preWeight'] ?? ''} | Post-Weight: ${record['postWeight'] ?? ''}",
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

  // 🔹 Info Row Widget
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

  // 🔹 Edit Dialog
  // 🔹 Modern & Improved Edit Dialog (UI Only)
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

                      // 🔹 Dialysis Info Card
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

                      // 🔹 Vital Signs Card
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
                                keyboard: TextInputType.text,
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
                              };

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patientId)
                                  .collection('records')
                                  .doc(recordId)
                                  .update(updatedData);

                              // ✅ Doctor Notification Logic (unchanged)
                              try {
                                final patientDoc =
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(patientId)
                                        .get();

                                if (patientDoc.exists) {
                                  final doctorId = patientDoc['doctorId'];
                                  final firstName =
                                      patientDoc['firstName'] ?? '';
                                  final lastName = patientDoc['lastName'] ?? '';

                                  if (doctorId != null &&
                                      doctorId.toString().isNotEmpty) {
                                    final changedFields = <String>[];
                                    updatedData.forEach((key, value) {
                                      if (key != 'updatedAt' &&
                                          record[key]?.toString() !=
                                              value.toString()) {
                                        changedFields.add(key);
                                      }
                                    });

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
                                            .map(
                                              (key) => fieldNames[key] ?? key,
                                            )
                                            .toList();

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

                                    String title;
                                    String message;

                                    if (changedFields.isEmpty) {
                                      title = 'Patient Record Saved';
                                      message =
                                          'Nurse saved ${firstName} ${lastName}\'s record.';
                                    } else {
                                      title = 'Updated Patient Record';
                                      message =
                                          'Nurse updated $formattedFields for $firstName $lastName.';
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(doctorId)
                                        .collection('notifications')
                                        .add({
                                          'title': title,
                                          'message': message,
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
                                  '⚠️ Error sending doctor notification: $e',
                                );
                              }

                              Navigator.pop(context);
                              // ✅ Themed Snackbar
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
                                      Theme.of(context)
                                          .colorScheme
                                          .primary, // 🟢 Uses app theme color
                                  behavior:
                                      SnackBarBehavior
                                          .floating, // makes it float above content
                                  margin: const EdgeInsets.all(
                                    16,
                                  ), // padding from edges
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(
                                    seconds: 2,
                                  ), // visible for 2 seconds
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

  // 🔹 Reusable labeled section header
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

  // 🔹 Reusable input field with flexible width
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
}
