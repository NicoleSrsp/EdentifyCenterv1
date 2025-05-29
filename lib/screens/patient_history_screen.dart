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
  bool isLoading = false;
  bool isApproved = false;

  DateTime get startOfDayUtc =>
      DateTime.utc(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
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
      setState(() => patientName = '${first.trim()} ${last.trim()}'.trim());
    } else {
      setState(() => patientName = 'Unknown');
    }
  } catch (e) {
    setState(() => patientName = 'Unknown');
  }
}


  Future<void> fetchApprovalStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('pending_approvals').doc(widget.docId).get();
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
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDayUtc))
        .snapshots();
  }

  Future<void> updateDoctorNote() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.docId)
          .collection('scanHistory')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDayUtc))
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'doctor_note': _noteController.text});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor's note updated.")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update note: $e")));
      }
    }
  }

  Future<void> approveEntry() async {
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('pending_approvals').doc(widget.docId).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
      });
      setState(() => isApproved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry approved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to approve entry: $e')));
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
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Center(child: CircularProgressIndicator());

      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) return const Text('No scan records for this date.');

      final data = docs.first.data() as Map<String, dynamic>;
      final photoUrl = (data['imageURL'] as String?)?.trim();
      final result = data['result'] ?? 'No classification';
      final recommendations = data['recommendations'] ?? 'No recommendations available';
      _noteController.text = data['doctor_note'] ?? '';

      return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Photo + texts
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
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
            ),

            const SizedBox(width: 16),

            // Wrap the text widgets inside a Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Classification text
                Text(
                  result,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                // Recommendations title
                const Text(
                  'Recommendations:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Recommendations list
                ...recommendations
                    .toString()
                    .split('.')
                    .where((rec) => rec.trim().isNotEmpty)
                    .map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${rec.trim()}.',
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
              ],
            ),

            const SizedBox(width: 24),

            // Right side remains unchanged...
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 5,
                    readOnly: widget.readonly,
                    decoration: InputDecoration(
                      hintText: "Doctor's notes",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  if (!widget.readonly)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isApproved ? null : approveEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isApproved ? Colors.grey : Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isApproved ? 'Approved' : 'Approve', style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reclassification feature coming soon.')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Reclassify', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),

                  if (!widget.readonly) const SizedBox(height: 16),

                  if (!widget.readonly)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateDoctorNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Note', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );



    },
  );
}

  Widget buildTreatmentSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('treatment_data'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading treatment data.');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Text('No treatment records for this date.');

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
        if (snapshot.hasError) return const Text('Error loading water intake data.');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Text('No water intake records for this date.');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dateStr = data['date'] ?? '';
            final amount = data['intakeAmount'] ?? 0;
            final totalAmount = data['totalAmount'] ?? 0;
            final waterLossCauses = (data['waterLossCauses'] as List<dynamic>?)?.cast<String>() ?? [];

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
      title: Row(
        children: [
          Image.asset('assets/logo.png', height: 40),
          const SizedBox(width: 10),
          const Text('Edentify'),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.home)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.logout)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Patient: $patientName',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Scan Section Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: buildScanSection(),
            ),
          ),

          const SizedBox(height: 24),

          // Treatment Data Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Treatment Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Water Intake', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

}
