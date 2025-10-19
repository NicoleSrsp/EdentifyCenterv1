import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  String _sortOrder = "desc";
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
                      Container(
                        color: const Color(0xFF045347),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
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
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Sort by:",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: _sortOrder,
                                        items: const [
                                          DropdownMenuItem(
                                            value: "desc",
                                            child: Text("Newest First"),
                                          ),
                                          DropdownMenuItem(
                                            value: "asc",
                                            child: Text("Oldest First"),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() => _sortOrder = value!);
                                        },
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(widget.patientId)
                                        .collection("records")
                                        .orderBy(
                                          "createdAt",
                                          descending: _sortOrder == "desc",
                                        )
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
                                                "Date: ${record['date'] ?? doc.id} "
                                                "(${(record['sessionType'] ?? 'pre').toString().toUpperCase()}-Dialysis)",
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
        String sessionType = record['sessionType'] ?? 'pre';
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
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.monitor_weight,
                                  color: Colors.teal.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Dialysis Information",
                                  style: TextStyle(
                                    color: Colors.teal.shade800,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
                                  alignment: WrapAlignment.center,
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    _buildEditField(
                                      "Pre-Weight (kg)",
                                      preWeightController,
                                      width: 400,
                                    ),
                                    _buildEditField(
                                      "Post-Weight (kg)",
                                      postWeightController,
                                      width: 400,
                                    ),
                                    _buildEditField(
                                      "UF Goal (L)",
                                      ufGoalController,
                                      width: 400,
                                    ),
                                    _buildEditField(
                                      "UF Removed (L)",
                                      ufRemovedController,
                                      width: 400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.teal.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Vital Signs",
                                  style: TextStyle(
                                    color: Colors.teal.shade800,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
                                  alignment: WrapAlignment.center,
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    _buildEditField(
                                      "Blood Pressure (mmHg)",
                                      bpController,
                                      width: 400,
                                    ),
                                    _buildEditField(
                                      "Pulse Rate (bpm)",
                                      pulseController,
                                      width: 400,
                                    ),
                                    _buildEditField(
                                      "Temperature (°C)",
                                      tempController,
                                      width: 400,
                                    ),
                                    _buildEditField(
                                      "Respiration Rate",
                                      respirationController,
                                      width: 400,
                                    ),
                                    _buildEditField(
                                      "Oxygen Saturation (%)",
                                      o2Controller,
                                      width: 400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: Container(
                margin: const EdgeInsets.only(bottom: 10, right: 10),
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final nurseInfo = await _promptNurseVerification();
                      if (nurseInfo == null) return;
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
                        'updatedBy': _verifiedNurse?['nurseName'],
                        'nurseName': nurseInfo['nurseName'],
                        'sessionType': sessionType,
                      };

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(patientId)
                          .collection('records')
                          .doc(recordId)
                          .update(updatedData);

                      // 🔹 Add notification for updated record
                      final patientDoc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(patientId)
                              .get();

                      final patientData = patientDoc.data() ?? {};
                      final patientName =
                          "${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}"
                              .trim();

                      final sessionLabel =
                          sessionType == 'post'
                              ? 'Post-Dialysis'
                              : 'Pre-Dialysis';

                      // 🔹 Create notification in patient's notifications collection
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(patientId)
                          .collection('notifications')
                          .add({
                            'title': '$sessionLabel Record Updated',
                            'message':
                                'Nurse ${nurseInfo['nurseName']} updated your $sessionLabel record for ${DateFormat('MMM d, yyyy').format(DateTime.now())}.',
                            'sessionType': sessionType, // ✅ identifies pre/post
                            'createdAt':
                                FieldValue.serverTimestamp(), // ✅ matches realtime_notifications.dart
                            'read':
                                false, // ✅ matches realtime_notifications.dart
                          });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.white),
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
                          backgroundColor: Colors.teal.shade700,
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
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.teal.shade700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.number,
    double width = 400,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        cursorColor: Colors.teal.shade700,
        style: TextStyle(
          color: Colors.teal.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.teal.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal.shade700, width: 1.2),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700, // ✅ Button background
                foregroundColor: Colors.white, // ✅ Text (font) color
              ),
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
