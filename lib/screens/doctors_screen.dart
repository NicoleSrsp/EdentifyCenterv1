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
  String searchQuery = "";

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

        // 🔍 Apply search filter
        if (searchQuery.isNotEmpty) {
          docs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(searchQuery.toLowerCase()) ||
                    email.contains(searchQuery.toLowerCase());
              }).toList();
        }

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No doctors found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
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
              margin: const EdgeInsets.only(bottom: 14),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
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
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: primaryColor,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                doctorEmail,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doctorContact,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 28,
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
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🩺 Header
              Row(
                children: const [
                  Icon(Icons.person_add_alt_1, color: primaryColor, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Add New Doctor",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkerPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(thickness: 1, color: Colors.teal),

              // 🧾 Form Fields
              const SizedBox(height: 16),
              _buildTextField(firstNameController, "First Name",
                  icon: Icons.person_outline),
              _buildTextField(lastNameController, "Last Name",
                  icon: Icons.badge_outlined),
              _buildTextField(emailController, "Email",
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined),
              _buildTextField(passwordController, "Password",
                  obscureText: true, icon: Icons.lock_outline),
              _buildTextField(confirmPasswordController, "Confirm Password",
                  obscureText: true, icon: Icons.lock_reset_outlined),

              const SizedBox(height: 24),

              // 🧩 Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    label: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      "Add Doctor",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
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
                        _showSnack("All fields are required");
                        return;
                      }

                      if (password != confirmPassword) {
                        _showSnack("Passwords do not match");
                        return;
                      }

                      try {
                        UserCredential userCredential = await FirebaseAuth
                            .instance
                            .createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                        String doctorId = userCredential.user!.uid;

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
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? icon,
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
          prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
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

                // 🔍 Search Bar
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Text(
                    'Doctors List',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: primaryColor,
                    ),
                  ),
                ),

                // 🔍 Search Bar (now below the title)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: TextField(
                    onChanged:
                        (value) => setState(() => searchQuery = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search doctors by name or email...',
                      prefixIcon: const Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryColor,
                          width: 2,
                        ),
                      ),
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
