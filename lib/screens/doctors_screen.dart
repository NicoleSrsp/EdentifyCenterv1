import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'side_menu.dart';
import 'doctor_detail_screen.dart';

class DoctorsScreen extends StatefulWidget {
  final String centerId;
  final String centerName;

  const DoctorsScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  // --- Doctor list UI ---
  Widget _buildDoctorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_inCharge')
          .where('centerId', isEqualTo: widget.centerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading doctors.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No doctors found.'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doctor = docs[index];
            final data = doctor.data() as Map<String, dynamic>;
            final doctorName = data['name'] ?? 'No Name';
            final doctorContact = data['contact'] ?? '';
            final doctorEmail = data['email'] ?? '';

            return InkWell(
              onTap: () {
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
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        doctorName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        doctorContact,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        doctorEmail,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Add Doctor Dialog ---
  Future<void> _showAddDoctorDialog() async {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Doctor"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: "First Name"),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: "Last Name"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPasswordController,
                  decoration:
                      const InputDecoration(labelText: "Confirm Password"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword =
                    confirmPasswordController.text.trim();

                if (firstName.isEmpty ||
                    lastName.isEmpty ||
                    email.isEmpty ||
                    password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required")),
                  );
                  return;
                }

                if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Passwords do not match")),
                  );
                  return;
                }

                try {
                  // Step 1: Create user in Firebase Auth
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                          email: email, password: password);

                  String doctorId = userCredential.user!.uid;

                  // Step 2: Save doctor profile in doctor_inCharge
                  await FirebaseFirestore.instance
                      .collection("doctor_inCharge")
                      .doc(doctorId)
                      .set({
                    "name": "$firstName $lastName",
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "centerId": widget.centerId,
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  // Step 3: Save also in doctors_centers/doctor_center/doctors_center_collection
                  await FirebaseFirestore.instance
                      .collection("doctors_centers")
                      .doc("doctor_center")
                      .collection("doctors_center_collection")
                      .doc(doctorId)
                      .set({
                    "doctorId": doctorId,
                    "name": "$firstName $lastName",
                    "email": email,
                    "centerId": widget.centerId,
                    "createdAt": FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Doctor added successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // --- Main UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _showAddDoctorDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: SideMenu(
              centerId: widget.centerId,
              centerName: widget.centerName,
              selectedMenu: 'Doctors',
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  color: Colors.teal.shade700,
                  child: Text(
                    widget.centerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Doctors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(child: _buildDoctorsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
