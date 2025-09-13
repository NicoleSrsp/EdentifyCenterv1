import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'doctor_detail_screen.dart';

class DoctorsScreen extends StatelessWidget {
  final String centerName;

  const DoctorsScreen({super.key, required this.centerName});

  @override
  Widget build(BuildContext context) {
    // Reference to doctors in Firestore filtered by center
    final doctorsRef = FirebaseFirestore.instance
        .collection('doctors')
        .where('center_name', isEqualTo: centerName);

    return Scaffold(
      appBar: AppBar(
        title: Text(centerName),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: doctorsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No doctors found'));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              final doctorName = doctor['name'] ?? 'No Name';
              final doctorTitle = doctor['title'] ?? '';
              final doctorPhoto = doctor['photo_url'] ?? '';
              final doctorAddress = doctor['address'] ?? '';
              final doctorContact = doctor['contact'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        doctorPhoto.isNotEmpty ? NetworkImage(doctorPhoto) : null,
                    child: doctorPhoto.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(doctorName),
                  subtitle: Text(doctorTitle),
                  onTap: () {
                    // Navigate to Doctor Detail Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorDetailScreen(
                          doctorId: doctor.id,
                          doctorName: doctorName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
