import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  final String currentCenter = 'RnBDialysisCenter';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Schedules')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('center', isEqualTo: currentCenter)
            .where('scheduledDate', isEqualTo: today)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error'));

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final patient = docs[index];
              return ListTile(
                title: Text(patient['name']),
              );
            },
          );
        },
      ),
    );
  }
}
