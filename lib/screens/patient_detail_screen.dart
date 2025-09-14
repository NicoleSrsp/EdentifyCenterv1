import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_patient_record_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text("Loading patient info..."));
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Patient not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.teal.shade700,
                width: double.infinity,
                child: const Text(
                  "R&B Dialysis Center",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Patient Info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: data['profilePicUrl'] != null
                          ? NetworkImage(data['profilePicUrl'])
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Birthday: ${data['birthday'] ?? 'N/A'}"),
                          Text("Address: ${data['address'] ?? 'N/A'}"),
                          Text("Contact: ${data['mobileNumber'] ?? 'N/A'}"),
                          Text("Health Conditions: ${data['healthConditions'] ?? 'None'}"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Patient Records Section
              Expanded(
                child: Column(
                  children: [
                    // Add Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Add"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddPatientRecordScreen(patientId: patientId),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Records List
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("users")
                            .doc(patientId)
                            .collection("records")
                            .orderBy("createdAt", descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No records yet"));
                          }

                          return ListView(
                            children: snapshot.data!.docs.map((doc) {
                              final record = doc.data() as Map<String, dynamic>;
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: const Icon(Icons.folder, color: Colors.teal),
                                  title: Text("Date: ${record['date'] ?? doc.id}"),
                                  subtitle: Text(
                                    "Pre-Weight: ${record['preWeight'] ?? ''} | Post-Weight: ${record['postWeight'] ?? ''}",
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
    );
  }
}
