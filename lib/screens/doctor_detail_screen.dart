import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String centerName;
  final String centerId;

  const DoctorDetailScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.centerName,
    required this.centerId,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  String sortOption = "Name"; // Default sort

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF056C5B);
    const darkerPrimaryColor = Color(0xFF045347);

    return Scaffold(
      body: Row(
        children: [
          /// Side Menu
          SideMenu(
            centerName: widget.centerName,
            centerId: widget.centerId,
            selectedMenu: "Doctors",
          ),

          /// Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header with Center Name
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  color: darkerPrimaryColor,
                  child: Text(
                    widget.centerName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                /// Doctor Info + Patients
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('doctor_inCharge')
                          .doc(widget.doctorId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text("Doctor not found.");
                        }

                        final doctorData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final contact = doctorData['contact'] ?? '';
                        final imageUrl = doctorData['imageUrl'] ?? '';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Doctor Info Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Profile Image (Square)
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    image: imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: imageUrl.isEmpty
                                      ? Center(
                                          child: Text(
                                            widget.doctorName.isNotEmpty
                                                ? widget.doctorName[0]
                                                : "?",
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),

                                /// Doctor Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.doctorName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text("Contact: $contact"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            /// Assigned Patients Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Assigned Patients",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),

                                /// Sort Dropdown
                                DropdownButton<String>(
                                  value: sortOption,
                                  items: const [
                                    DropdownMenuItem(
                                      value: "Name",
                                      child: Text("Sort by Name"),
                                    ),
                                    DropdownMenuItem(
                                      value: "Mobile",
                                      child: Text("Sort by Mobile Number"),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        sortOption = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            /// Patient List
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .where(
                                    'doctorId',
                                    isEqualTo: widget.doctorId,
                                  )
                                  .where(
                                    'centerId',
                                    isEqualTo: widget.centerId,
                                  )
                                  .where(
                                    'status',
                                    isEqualTo: 'active',
                                  )
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
                                  return const Text(
                                    "No patients assigned to this doctor.",
                                  );
                                }

                                /// Convert to list and sort
                                final patients = snapshot.data!.docs.toList();
                                patients.sort((a, b) {
                                  if (sortOption == "Name") {
                                    final firstA = (a['firstName'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    final firstB = (b['firstName'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    final lastA = (a['lastName'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    final lastB = (b['lastName'] ?? '')
                                        .toString()
                                        .toLowerCase();

                                    final firstCompare =
                                        firstA.compareTo(firstB);
                                    if (firstCompare != 0) return firstCompare;
                                    return lastA.compareTo(lastB);
                                  } else {
                                    final mobileA = (a['mobileNumber'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    final mobileB = (b['mobileNumber'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                    return mobileA.compareTo(mobileB);
                                  }
                                });

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: patients.length,
                                  itemBuilder: (context, index) {
                                    final patient = patients[index];
                                    final firstName =
                                        patient['firstName'] ?? '';
                                    final lastName = patient['lastName'] ?? '';
                                    final mobileNumber =
                                        patient['mobileNumber'] ?? '';

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.person,
                                          color: primaryColor,
                                        ),
                                        title: Text(
                                          "$firstName $lastName",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Mobile: $mobileNumber",
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
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
