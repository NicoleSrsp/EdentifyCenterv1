import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_patient_record_screen.dart';
import 'side_menu.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  final String centerId;
  final String centerName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    required this.centerId,
    required this.centerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔹 Left Side Menu
          SideMenu(
            centerId: centerId,
            centerName: centerName,
            selectedMenu: 'Patients',
          ),

          // 🔹 Main Content
          Expanded(
            child: Container(
              color: Colors.grey.shade100, // subtle background
              child: FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(patientId)
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("Patient not found."));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final fullName =
                      "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Header Bar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: SideMenu.darkerPrimaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        width: double.infinity,
                        child: Text(
                          centerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 Patient Info Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundImage:
                                      data['profilePicUrl'] != null
                                          ? NetworkImage(data['profilePicUrl'])
                                          : const AssetImage(
                                                'assets/images/default_avatar.png',
                                              )
                                              as ImageProvider,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.cake,
                                        "Birthday",
                                        data['birthday'] ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        Icons.home,
                                        "Address",
                                        data['address'] ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        Icons.phone,
                                        "Contact",
                                        data['mobileNumber'] ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        Icons.medical_services,
                                        "Health Conditions",
                                        data['healthConditions'] ?? 'None',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔹 Records Section
                      Expanded(
                        child: Column(
                          children: [
                            // Add Button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: SideMenu.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Add Record",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddPatientRecordScreen(
                                              patientId: patientId,
                                              centerId: centerId,
                                              centerName: centerName,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Records List
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(patientId)
                                        .collection("records")
                                        .orderBy("createdAt", descending: true)
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                      child: Text("No records yet"),
                                    );
                                  }

                                  return ListView(
                                    padding: const EdgeInsets.all(16),
                                    children:
                                        snapshot.data!.docs.map((doc) {
                                          final record =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 3,
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: ListTile(
                                              leading: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.teal.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: const Icon(
                                                  Icons.folder,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                              title: Text(
                                                "Date: ${record['date'] ?? doc.id}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
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
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Reusable Info Row
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 6),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
