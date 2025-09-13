import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorDetailScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;

  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    final doctorRef =
        FirebaseFirestore.instance.collection('doctors').doc(doctorId);

    final patientsRef = FirebaseFirestore.instance
        .collection('patients')
        .where('doctor_id', isEqualTo: doctorId);

    return Scaffold(
      appBar: AppBar(
        title: Text(doctorName),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: doctorRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Doctor not found'));
          }

          final doctor = snapshot.data!;
          final doctorTitle = doctor['title'] ?? '';
          final doctorPhoto = doctor['photo_url'] ?? '';
          final doctorAddress = doctor['address'] ?? '';
          final doctorContact = doctor['contact'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          doctorPhoto.isNotEmpty ? NetworkImage(doctorPhoto) : null,
                      child: doctorPhoto.isEmpty ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctorName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(doctorTitle),
                          Text(doctorAddress),
                          Text(doctorContact),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'List of Patients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: patientsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No patients found'));
                      }

                      final patients = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          final patientName = patient['name'] ?? 'No Name';
                          return ListTile(
                            title: Text(patientName),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
