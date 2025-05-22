import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'entry_detail_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  final String doctorId = 'doctor_001';

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
              final submittedDate = approval['submitted_date'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(patientName),
                  subtitle: Text("Submitted on $submittedDate"),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EntryDetailScreen(
                            folder: approval.data() as Map<String, dynamic>,
                            docId: approval.id,
                            collectionName: 'pending_approvals',  // <-- Pass collection name
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
