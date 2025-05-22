import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArchivedPatientsScreen extends StatelessWidget {
  final String centerName;

  const ArchivedPatientsScreen({super.key, required this.centerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        iconTheme: const IconThemeData(color: Colors.white), // back arrow color
        title: const Text(
          'Archived Patients',
          style: TextStyle(color: Colors.white), // title text color
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('center', isEqualTo: centerName)
            .where('status', isEqualTo: 'archived')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading archived patients'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No archived patients.'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final patient = docs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(patient['name']),
                  subtitle: const Text('Archived'),
                  trailing: TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('patients')
                          .doc(patient.id)
                          .update({'status': 'active'});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Patient unarchived')),
                      );
                    },
                    child: const Text('Unarchive'),
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
