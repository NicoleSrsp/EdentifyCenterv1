import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'side_menu.dart';
import 'doctor_detail_screen.dart';

// Theme colors
const Color primaryColor = Color(0xFF056C5B);
const Color darkerPrimaryColor = Color(0xFF045347);

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
      stream:
          FirebaseFirestore.instance
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
          return const Center(
            child: Text(
              'No doctors found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doctor = docs[index];
            final data = doctor.data() as Map<String, dynamic>;
            final doctorName = data['name'] ?? 'No Name';
            final doctorContact = data['contact'] ?? 'No contact';
            final doctorEmail = data['email'] ?? 'No email';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DoctorDetailScreen(
                              doctorId: doctor.id,
                              doctorName: doctorName,
                              centerId: widget.centerId,
                              centerName: widget.centerName,
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: primaryColor,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctorEmail,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doctorContact,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.person_add_alt_1, color: primaryColor),
              SizedBox(width: 8),
              Text("Add Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(firstNameController, "First Name"),
                _buildTextField(lastNameController, "Last Name"),
                _buildTextField(
                  emailController,
                  "Email",
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  passwordController,
                  "Password",
                  obscureText: true,
                ),
                _buildTextField(
                  confirmPasswordController,
                  "Confirm Password",
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final firstName = firstNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (firstName.isEmpty ||
                    lastName.isEmpty ||
                    email.isEmpty ||
                    password.isEmpty) {
                  _showSnack("All fields are required");
                  return;
                }

                if (password != confirmPassword) {
                  _showSnack("Passwords do not match");
                  return;
                }

                try {
                  // Step 1: Create user in Firebase Auth
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                  String doctorId = userCredential.user!.uid;

                  // Step 2: Save doctor profile
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

                  // Step 3: Also save to doctors_centers
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
                  _showSnack("Doctor added successfully", success: true);
                } catch (e) {
                  _showSnack("Error: $e");
                }
              },
              icon: const Icon(Icons.check, size: 18, color: Colors.white),
              label: const Text(
                "Add",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? Colors.teal.shade700 : Colors.redAccent,
        content: Text(message),
      ),
    );
  }

  // --- Reusable TextField Builder ---
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: primaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // --- Main UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: _showAddDoctorDialog,
        label: const Text("Add Doctor"),
        icon: const Icon(Icons.add),
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
                    horizontal: 24,
                    vertical: 16,
                  ),
                  color: darkerPrimaryColor,
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
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Doctors List',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryColor,
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
