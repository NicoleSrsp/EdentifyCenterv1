import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> folder;
  final String docId;
  final bool readonly;
  final String collectionName;
  final DateTime selectedDate;

  const PatientHistoryScreen({
    super.key,
    required this.folder,
    required this.docId,
    this.readonly = false,
    this.collectionName = 'users',
    required this.selectedDate,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  late TextEditingController _noteController;
  String patientName = 'Loading...';
  String healthCondition = '';
  bool isLoading = false;
  bool isApproved = false;

  DateTime get startOfDayUtc => DateTime.utc(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
      );
  DateTime get endOfDayUtc => startOfDayUtc.add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    fetchPatientName();
    fetchApprovalStatus();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> fetchPatientName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.docId)
          .get();

      final data = doc.data();
      if (data != null) {
        final first = data['firstName'] ?? '';
        final last = data['lastName'] ?? '';
        final condition = data['healthCondition'] ?? '';
        setState(() {
          patientName = '${first.trim()} ${last.trim()}'.trim();
          healthCondition = condition;
        });
      } else {
        setState(() {
          patientName = 'Unknown';
          healthCondition = '';
        });
      }
    } catch (e) {
      setState(() {
        patientName = 'Unknown';
        healthCondition = '';
      });
    }
  }

  Future<void> fetchApprovalStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pending_approvals')
          .doc(widget.docId)
          .get();
      if (doc.exists) {
        setState(() => isApproved = (doc.data()?['status'] == 'approved'));
      }
    } catch (_) {
      setState(() => isApproved = false);
    }
  }

  Stream<QuerySnapshot> _getSubcollectionStream(String subcollection) {
    return FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(widget.docId)
        .collection(subcollection)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDayUtc))
        .snapshots();
  }

  Future<void> updateDoctorNote() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.docId)
          .collection('scanHistory')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDayUtc))
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference
            .update({'doctor_note': _noteController.text});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Doctor's note updated.")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update note: $e")));
      }
    }
  }

  Future<void> approveEntry() async {
  setState(() => isLoading = true);

  try {
    final query = await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(widget.docId)
        .collection('scanHistory')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDayUtc))
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;

      await docRef.update({
        'approved': true,
        'approved_at': FieldValue.serverTimestamp(),
      });

      setState(() => isApproved = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry approved.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entry found to approve.')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve entry: $e')),
      );
    }
  } finally {
    setState(() => isLoading = false);
  }
}



  Widget buildScanSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('scanHistory'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading scans.');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Text('No scan records for this date.');

        final data = docs.first.data() as Map<String, dynamic>;
        final photoUrl = (data['imageURL'] as String?)?.trim();
        final result = data['result'] ?? 'No classification';
        final recommendations =
            data['recommendations'] ?? 'No recommendations available';
        _noteController.text = data['doctor_note'] ?? '';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Image and details
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? SizedBox(
                            width: 300,
                            height: 300,
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 80, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 300,
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image,
                                size: 80, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Result
                  Text(
                    result,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  // Recommendations
                  const Text(
                    'Recommendations:',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...recommendations
                      .toString()
                      .split('.')
                      .where((rec) => rec.trim().isNotEmpty)
                      .map(
                        (rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${rec.trim()}.',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      ),
                  const SizedBox(height: 24),

                  // Buttons
                  if (!widget.readonly)
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: isApproved ? null : approveEntry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isApproved ? Colors.grey : Colors.teal[400],
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(isApproved ? 'Approved' : 'Approve',
                                  style: const TextStyle(fontSize: 18)),
                        ),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final now = DateTime.now();
                                  final startOfDay =
                                      DateTime(now.year, now.month, now.day);
                                  final endOfDay =
                                      startOfDay.add(const Duration(days: 1));

                                  final querySnapshot = await FirebaseFirestore
                                      .instance
                                      .collection(widget.collectionName)
                                      .doc(widget.docId)
                                      .collection('scanHistory')
                                      .where('date',
                                          isGreaterThanOrEqualTo:
                                              Timestamp.fromDate(startOfDay))
                                      .where('date',
                                          isLessThan:
                                              Timestamp.fromDate(endOfDay))
                                      .limit(1)
                                      .get();

                                  if (querySnapshot.docs.isNotEmpty) {
                                    final doc = querySnapshot.docs.first;
                                    final currentClassification =
                                        doc['result'] ?? 'Normal';
                                    await showReclassificationDialog(
                                        doc.id, currentClassification);
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'No scan history available for today to reclassify.')),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[300],
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reclassify',
                              style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // Right Column: Doctor's Note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Doctor's Note",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    readOnly: widget.readonly,
                    decoration: InputDecoration(
                      hintText: "Doctor's notes",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  if (!widget.readonly)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateDoctorNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Save Note',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildTreatmentSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('treatment_data'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading treatment data.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('No treatment records for this date.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final preWeight = data['preWeight']?.toString() ?? 'N/A';
            final postWeight = data['postWeight']?.toString() ?? 'N/A';
            final ufVolume = data['ufVolume']?.toString() ?? 'N/A';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Pre Weight: $preWeight\nPost Weight: $postWeight\nUF Volume: $ufVolume',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildWaterIntakeSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('waterIntake'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading water intake data.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text('No water intake records for this date.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] ?? '';
            final amount = data['intakeAmount'] ?? 0;
            final totalAmount = data['totalAmount'] ?? 0;
            final waterLossCauses =
                (data['waterLossCauses'] as List<dynamic>?)?.cast<String>() ??
                    [];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Date: $dateStr\nAmount: $amount\nTotal: $totalAmount\nCauses: ${waterLossCauses.join(", ")}',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A79D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
            const Text(
              'Edentify',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient name header card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient: $patientName',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Condition: $healthCondition',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 4),

            // Scan Section Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: buildScanSection(),
              ),
            ),

            const SizedBox(height: 24),

            // Treatment Data Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Treatment Data',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    buildTreatmentSection(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Water Intake Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Water Intake',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    buildWaterIntakeSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showReclassificationDialog(
      String scanDocId, String currentClassification) async {
    String? selectedClassification = currentClassification.toLowerCase();

    final classifications = ['normal', 'mild', 'moderate', 'severe'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reclassify Condition'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: classifications.map((cls) {
                  return RadioListTile<String>(
                    title: Text(cls[0].toUpperCase() + cls.substring(1)),
                    value: cls,
                    groupValue: selectedClassification,
                    onChanged: (value) {
                      setState(() {
                        selectedClassification = value;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedClassification == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await updateReclassification(
                          scanDocId, selectedClassification!);
                    },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateReclassification(
      String scanDocId, String newClassification) async {
    setState(() => isLoading = true);

    try {
      final scanDocRef = FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.docId)
          .collection('scanHistory')
          .doc(scanDocId);

      await scanDocRef.update({
        'result': newClassification[0].toUpperCase() + newClassification.substring(1),
        'reclassified_at': FieldValue.serverTimestamp(),
        'reclassified_by': 'Doctor',
      });

      // Add notification for patient
      final notificationRef = FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.docId)
          .collection('notifications')
          .doc();

      await notificationRef.set({
        'type': 'reclassification',
        'message':
            'Your scan classification has been updated to $newClassification.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Classification updated to $newClassification and patient notified.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update classification: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }
}