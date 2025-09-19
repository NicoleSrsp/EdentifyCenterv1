import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';

class AboutScreen extends StatelessWidget {
  final String centerId;
  final String centerName;

  const AboutScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("📌 AboutScreen opened with centerId: $centerId");

    return Scaffold(
      body: Row(
        children: [
          // ✅ Sidebar (keep only once)
          SideMenu(
            centerId: centerId,
            centerName: centerName, // use what was passed in
            selectedMenu: 'About Center',
          ),

          // ✅ Main content only, no duplicate SideMenu inside
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('centers')
                  .doc(centerId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint("❌ Firestore error: ${snapshot.error}");
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  debugPrint("❌ No document found for centerId: $centerId");
                  return const Center(child: Text('Failed to load center data'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                debugPrint("✅ Firestore data loaded: $data");

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Logo + Center Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(
                              Icons.local_hospital,
                              size: 40,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? centerName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // ✅ unchanged
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['address'] ?? 'No address provided',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "📞 ${data['contactNumber'] ?? 'No contact'}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black, // ✅ unchanged
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Mission & Vision Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Our Mission & Vision",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['mission'] ??
                                  'No mission/vision information available.',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black, // ✅ unchanged
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
