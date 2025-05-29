import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class PatientHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> folder; // patient data document fields only
  final String docId;                // patient document ID (patient ID)
  final bool readonly;
  final String collectionName;       // Usually 'users'
  final DateTime selectedDate;

  const PatientHistoryScreen({
    super.key,
    required this.folder,
    required this.docId,
    this.readonly = false,
    this.collectionName = 'users',  // default to 'users'
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

  DateTime get startOfDayUtc => DateTime.utc(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
  DateTime get endOfDayUtc => startOfDayUtc.add(const Duration(days: 1));

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
    try {
      final doc = await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.docId).get();
      final data = doc.data();
      if (data != null) {
        final first = data['firstname'] ?? '';
        final last = data['lastname'] ?? '';
        setState(() => patientName = '$first $last'.trim());
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

  Widget buildScanTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSubcollectionStream('scanHistory'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error loading scans: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) return const Center(child: Text('No scan records for this date.'));

      // Get the first document (most recent scan)
      final doc = docs.first;
      final data = doc.data() as Map<String, dynamic>;

      // Extract image URL - ensure field name matches your Firestore
      final photoUrl = (data['imageURL'] as String?)?.trim();

 // or 'photoUrl' depending on your Firestore

      // Debug print to verify URL
      debugPrint('Image URL: $photoUrl');

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Improved Image Display
            if (photoUrl != null && photoUrl.isNotEmpty)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error: $error');
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
            
            // Rest of your existing UI...
            const SizedBox(height: 16),
            Text(data['result'] ?? 'No classification', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // ... continue with rest of your UI
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final dialysisDate = data['dialysisDate'] ?? 'N/A';
            final preWeight = data['preWeight']?.toString() ?? 'N/A';
            final postWeight = data['postWeight']?.toString() ?? 'N/A';
            final ufVolume = data['ufVolume']?.toString() ?? 'N/A';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate().toLocal().toString() ?? '';

            return Card(
              child: ListTile(
                title: Text('Dialysis Date: $dialysisDate'),
                subtitle: Text('Pre Weight: $preWeight\nPost Weight: $postWeight\nUF Volume: $ufVolume'),
                trailing: Text(timestamp.split(' ').first),
              ),
            );
          }).toList(),
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: docs.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final dateStr = data['date'] ?? '';
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate().toLocal().toString() ?? '';
            final amount = data['intakeAmount'] ?? 0;
            final totalAmount = data['totalAmount'] ?? 0;
            final waterLossCauses = (data['waterLossCauses'] as List<dynamic>?)?.cast<String>() ?? [];

            return Card(
              child: ListTile(
                title: Text('Date: $dateStr'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: $amount ml'),
                    Text('Total Amount: $totalAmount ml'),
                    Text('Water Loss Causes: ${waterLossCauses.join(', ')}'),
                  ],
                ),
                trailing: Text(timestamp.split(' ').first),
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
