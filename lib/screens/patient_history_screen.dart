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
    required this.collectionName,
    required this.selectedDate,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> with TickerProviderStateMixin {
  late TextEditingController _noteController;
  late TabController _tabController;

  String patientName = 'Loading...';
  bool isLoading = false;
  bool isApproved = false;

  String get dateKey => widget.selectedDate.toIso8601String().split('T').first;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    fetchPatientName();
    fetchApprovalStatus();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchPatientName() async {
    final patientId = widget.folder['patientId'] as String?;
    if (patientId == null) {
      setState(() => patientName = 'Patient ID not found');
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection(widget.collectionName).doc(patientId).get();
      setState(() => patientName = doc.data()?['name'] ?? 'Unknown');
    } catch (_) {
      setState(() => patientName = 'Unknown');
    }
  }

  Future<void> fetchApprovalStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('pending_approvals').doc(widget.docId).get();
      if (doc.exists) {
        setState(() {
          isApproved = (doc.data()?['status'] == 'approved');
        });
      }
    } catch (_) {
      setState(() => isApproved = false);
    }
  }

  Stream<QuerySnapshot> _getSubcollectionStream(String subcollection) {
    final patientId = widget.folder['patientId'] as String?;
    if (patientId == null) return const Stream.empty();

    final ref = FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(patientId)
        .collection(subcollection);

    if (subcollection == 'waterIntake') {
      final start = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
      final end = start.add(const Duration(days: 1));
      return ref
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end))
          .snapshots();
    } else {
      return ref.where('date', isEqualTo: dateKey).snapshots();
    }
  }

  Future<void> updateDoctorNote() async {
    final patientId = widget.folder['patientId'] as String?;
    if (patientId == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(patientId)
          .collection('scanHistory')
          .where('date', isEqualTo: dateKey)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'doctor_note': _noteController.text});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor's note updated.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update note: $e")));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry approved.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to approve entry: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildScanTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('scanHistory'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error loading scans: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No scan records for this date.'));

        final data = docs.first.data() as Map<String, dynamic>;
        final classification = data['result'] ?? 'No classification available yet';
        final recommendation = data['recommendations'] ?? 'No recommendations yet';
        final confidence = int.tryParse(data['confidence_score']?.toString() ?? '0') ?? 0;
        final photoUrl = data['imageURL'];
        final scanDate = data['dateKey'] ?? 'No scan date available';

        _noteController.text = data['doctor_note'] ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null && photoUrl.isNotEmpty)
                Image.network(
                  photoUrl,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 160),
                )
              else
                const Icon(Icons.image, size: 160),
              const SizedBox(height: 10),
              Text(classification, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Recommendations:", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(recommendation),
              const SizedBox(height: 10),
              Text("$confidence%", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal)),
              const Text("Confidence Score"),
              const SizedBox(height: 20),
              if (!widget.readonly) ...[
                const Text("Edema Classification Review:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!isApproved)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                          onPressed: isLoading ? null : approveEntry,
                          child: isLoading
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Approve"),
                        ),
                      ),
                    if (!isApproved) const SizedBox(width: 10),
                    if (!isApproved)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reclassify pressed')));
                        },
                        child: const Text("Reclassify"),
                      ),
                    if (isApproved)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter notes here'),
              ),
              const SizedBox(height: 10),
              if (!widget.readonly)
                ElevatedButton(
                  onPressed: updateDoctorNote,
                  child: const Text("Save Note"),
                ),
              const SizedBox(height: 10),
              Text("Date Scanned: $scanDate", style: TextStyle(color: Colors.grey[700])),
            ],
          ),
        );
      },
    );
  }

  Widget buildTreatmentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('treatment_data'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error loading treatments: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No treatment records for this date.'));

        final data = docs.first.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pre Weight: ${data['preWeight']?.toString() ?? 'No data'}"),
              Text("Post Weight: ${data['postWeight']?.toString() ?? 'No data'}"),
              Text("UF Volume: ${data['ufVolume']?.toString() ?? 'No data'}"),
              Text("Dialysis Date: ${data['dialysisDate']?.toString() ?? 'No data'}"),
            ],
          ),
        );
      },
    );
  }

  Widget buildWaterIntakeTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('waterIntake'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error loading water intake: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No water intake records for this date.'));

        final data = docs.first.data() as Map<String, dynamic>;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Intake Amount: ${data['intakeAmount']?.toString() ?? 'No data'}"),
              Text("Water Loss Causes: ${(data['waterLossCauses'] as List<dynamic>?)?.join(', ') ?? 'None'}"),
              Text("Time Recorded: ${(data['timestamp'] as Timestamp?)?.toDate().toLocal().toString() ?? 'No data'}"),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scan'),
            Tab(text: 'Treatment'),
            Tab(text: 'Water Intake'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildScanTab(),
          buildTreatmentTab(),
          buildWaterIntakeTab(),
        ],
      ),
    );
  }
}
