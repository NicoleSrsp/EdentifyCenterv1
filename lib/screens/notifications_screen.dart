import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final String doctorId = 'doctor_001'; // hardcoded doctor ID

  void updateStatus(String docId, String status) {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white), 
        backgroundColor: Colors.teal.shade700,
        title: Row(
          children: const [
            Icon(Icons.notifications, color: Colors.white),
            SizedBox(width: 8),
            Text('Notifications', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('doctor_id', isEqualTo: doctorId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading notifications'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return const Center(child: Text('No pending notifications.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final notif = requests[index];
              final name = notif['patient_name'] ?? 'Unknown';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                    Row(
                      children: [
                        const Icon(Icons.person_add_alt_1,
                            color: Colors.teal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$name listed you as their doctor.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => updateStatus(notif.id, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 121, 107),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => updateStatus(notif.id, 'declined'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                             foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
