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
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // ✅ Sidebar (keep consistent)
          SideMenu(
            centerId: centerId,
            centerName: centerName,
            selectedMenu: 'About Center',
          ),

          // ✅ Main Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header (EXACT same as home_screen.dart)
                Container(
                  color: const Color(0xFF045347),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Text(
                        centerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // ✅ Scrollable Content
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
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text('Failed to load center data'),
                        );
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Center Info Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.teal.shade50,
                                    child: const Icon(
                                      Icons.local_hospital,
                                      size: 42,
                                      color: Color(0xFF045347),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? centerName,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF045347),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.teal,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                data['address'] ??
                                                    'No address provided',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              color: Colors.teal,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              data['contactNumber'] ??
                                                  'No contact number',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 🔹 Mission and Vision Section
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.flag_rounded,
                                        color: Colors.teal,
                                        size: 26,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Our Mission & Vision",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF045347),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    data['mission'] ??
                                        'No mission or vision provided yet.',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 🔹 Additional Info (if any)
                            if (data['description'] != null &&
                                (data['description'] as String).isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.teal,
                                          size: 26,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "About This Center",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF045347),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      data['description'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                        color: Colors.black87,
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
          ),
        ],
      ),
    );
  }
}
