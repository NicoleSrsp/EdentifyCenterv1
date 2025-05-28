import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> folder;
  final String docId;
  final String collectionName;
  final bool readonly;

  const PatientHistoryScreen({
    super.key,
    required this.folder,
    required this.docId,
    required this.collectionName,
    this.readonly = false, 
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  late TextEditingController _noteController;
  String patientName = 'Loading...';

  bool isApproved = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.folder['doctor_note'] ?? '');
    fetchPatientName(widget.folder['patientId']);
    fetchApprovalStatus();
  }

  Future<void> fetchPatientName(String patientId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          patientName = querySnapshot.docs.first.get('name') ?? 'Unknown';
        });
      } else {
        setState(() {
          patientName = 'Unknown';
        });
        print('Patient with patientId $patientId not found.');
      }
    } catch (e) {
      setState(() {
        patientName = 'Unknown';
      });
      print('Error fetching patient name: $e');
    }
  }

  Future<void> fetchApprovalStatus() async {
    final doc = await FirebaseFirestore.instance.collection('pending_approvals').doc(widget.docId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        isApproved = (data['status'] == 'approved');
      });
    }
  }

  Future<void> updateDoctorNote() async {
    final docId = widget.docId;

    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(docId)
          .update({'doctor_note': _noteController.text});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doctor's note updated.")),
      );
    } catch (e) {
      print('Failed to update doctor note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update note: $e")),
      );
    }
  }

  Future<void> approveEntry() async {
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pending_approvals').doc(widget.docId).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
      });
      setState(() {
        isApproved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry approved.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve entry: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;

    final String date = (folder['date'] ?? '')?.toString() ?? '';
    final String classification = (folder['classification'] ?? '')?.toString() ?? '';
    final String recommendation = (folder['recommendation'] ?? '')?.toString() ?? '';
    final int confidence = (folder['confidence_score'] is int)
        ? folder['confidence_score'] 
        : int.tryParse(folder['confidence_score']?.toString() ?? '0') ?? 0;
    final String? photoUrl = folder['photo_url']?.toString();

    final int waterIntake = (folder['water_intake'] is int)
        ? folder['water_intake']
        : int.tryParse(folder['water_intake']?.toString() ?? '0') ?? 0;

    final int intakeCups = (folder['water_intake_cups'] is int)
        ? folder['water_intake_cups']
        : int.tryParse(folder['water_intake_cups']?.toString() ?? '0') ?? 0;

    final String preWeight = (folder['pre_weight'] ?? '')?.toString() ?? '';
    final String postWeight = (folder['post_weight'] ?? '')?.toString() ?? '';
    final String ufVolume = (folder['uf_volume'] ?? '')?.toString() ?? '';


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 121, 107),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 10),
            const Text(
              'Edentify',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Patient Name: $patientName", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Date Scanned: $date", style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT SIDE
                Expanded(
                  flex: 3,
                  child: Card(
                    color: const Color(0xFFE1F7F6),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          photoUrl != null && photoUrl.isNotEmpty
                              ? Image.network(
                                  photoUrl,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 160);
                                  },
                                )
                              : const Icon(Icons.image, size: 160),
                          const SizedBox(height: 10),
                          Text(classification, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text("Recommendations:", style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text(recommendation),
                          const SizedBox(height: 10),
                          Text("$confidence%", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal)),
                          const Text("Confidence Score"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // RIGHT SIDE
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.readonly) ...[
                        const Text("Edema Classification Review:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (!isApproved)
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: isLoading ? null : approveEntry,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text("Approve"),
                                ),
                              ),
                            if (!isApproved) const SizedBox(width: 10),
                            if (!isApproved)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reclassify pressed')),
                                  );
                                },
                                child: const Text("Reclassify"),
                              ),
                            if (isApproved)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Approved"),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Text("Doctor's Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 4,
                        controller: _noteController,
                        readOnly: widget.readonly,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (!widget.readonly) const SizedBox(height: 10),
                      if (!widget.readonly)
                        ElevatedButton(
                          onPressed: updateDoctorNote,
                          child: const Text("Save Note"),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            const Text("Today's Water Intake", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('${waterIntake} ml', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(width: 10),
                Text("/ $intakeCups cup/s"),
                const SizedBox(width: 30),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text("Appointment Data", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _dataField("Dialysis Date", date),
                _dataField("Pre-Weight", preWeight),
                _dataField("Post-Weight", postWeight),
                _dataField("UF Volume", ufVolume),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: const Color.fromARGB(255, 39, 39, 39))),
          const SizedBox(height: 5),
          SizedBox(
            width: 120,
            child: TextField(
              enabled: false,
              controller: TextEditingController(text: value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
