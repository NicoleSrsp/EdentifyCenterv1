import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'patient_history_screen.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  _PendingApprovalScreenState createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  final String doctorId = 'doctor_001';

  // Method to fetch folder data (patient document) by patientId
  Future<Map<String, dynamic>?> _fetchFolderData(String patientId) async {
    final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(patientId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  }

  // Helper to parse DateTime safely
  DateTime? _parseDate(dynamic dateField) {
    if (dateField == null) return null;
    if (dateField is Timestamp) return dateField.toDate();
    if (dateField is String) {
      try {
        return DateTime.parse(dateField);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending for Approval')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pending_approvals')
            .where('status', isEqualTo: 'pending')
            .where('doctor_id', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading approvals.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final approvals = snapshot.data!.docs;

          if (approvals.isEmpty) {
            return const Center(child: Text('No pending approvals.'));
          }

          return ListView.builder(
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final approval = approvals[index];
              final patientName = approval['patient_name'] ?? 'Unknown';
              final submittedDateRaw = approval['submitted_date'];
              final submittedDate = _parseDate(submittedDateRaw);

              final patientId = approval['patient_id']; // Make sure this field exists!

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(patientName),
                  subtitle: Text(
                    submittedDate != null
                        ? "Submitted on ${submittedDate.month}/${submittedDate.day}/${submittedDate.year}"
                        : "Submitted date unknown",
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      if (patientId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient ID missing')),
                        );
                        return;
                      }

                      // Fetch folder data before navigating
                      final folderData = await _fetchFolderData(patientId);
                      if (folderData == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Patient folder not found')),
                        );
                        return;
                      }

                      // Use submittedDate as selectedDate or fallback to DateTime.now()
                      final selectedDate = submittedDate ?? DateTime.now();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientHistoryScreen(
                            folder: folderData,
                            docId: patientId,
                            collectionName: 'users',
                            selectedDate: selectedDate,
                            readonly: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('View'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
