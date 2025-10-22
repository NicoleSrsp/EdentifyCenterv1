import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'side_menu.dart';
import '../patient/patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  final String centerId;
  final String centerName;

  const PatientListScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  String _sortOption = 'Last Name (A–Z)';

  static const Color primaryColor = Color(0xFF056C5B);
  static const Color darkerPrimaryColor = Color(0xFF045347);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  String _getFullName(Map<String, dynamic> data) {
    final lastName = data['lastName'] ?? '';
    final firstName = data['firstName'] ?? '';
    if (firstName.isEmpty) return lastName;
    if (lastName.isEmpty) return firstName;
    return '$lastName, $firstName';
  }

  /// Modern Add Patient Dialog
  Future<void> _showAddPatientDialog() async {
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final birthdayController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final healthConditionController = TextEditingController();
    String? selectedDoctorId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👤 Header
                Row(
                  children: const [
                    Icon(Icons.person_add_alt_1, color: primaryColor, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Add New Patient",
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
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        firstNameController,
                        "First Name",
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        middleNameController,
                        "Middle Name",
                        icon: Icons.person_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  lastNameController,
                  "Last Name",
                  icon: Icons.person_3_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        birthdayController,
                        "Birthday (MM/DD/YYYY)",
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        phoneController,
                        "Phone Number",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  emailController,
                  "Email",
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  addressController,
                  "Address",
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 12),

                // 🩺 Health Condition
                _buildTextField(
                  healthConditionController,
                  "Health Condition",
                  icon: Icons.health_and_safety_outlined,
                ),
                const SizedBox(height: 12),

                // 👨‍⚕️ Assign Doctor Dropdown
                FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('doctor_inCharge')
                          .where('centerId', isEqualTo: widget.centerId)
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "No doctors available for this center.",
                        style: TextStyle(color: Colors.black54),
                      );
                    }
                    final doctors = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Assign Doctor",
                        prefixIcon: const Icon(Icons.medical_services_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      initialValue: selectedDoctorId,
                      items:
                          doctors.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(data['name'] ?? 'Unnamed Doctor'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        selectedDoctorId = value;
                      },
                    );
                  },
                ),

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
                        "Add Patient",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () async {
                        final firstName = firstNameController.text.trim();
                        final middleName = middleNameController.text.trim();
                        final lastName = lastNameController.text.trim();
                        final birthday = birthdayController.text.trim();
                        final phone = phoneController.text.trim();
                        final email = emailController.text.trim();
                        final address = addressController.text.trim();
                        final healthCondition =
                            healthConditionController.text.trim();

                        if (firstName.isEmpty ||
                            lastName.isEmpty ||
                            birthday.isEmpty ||
                            phone.isEmpty ||
                            address.isEmpty ||
                            selectedDoctorId == null) {
                          _showSnack("Please fill in all required fields");
                          return;
                        }

                        try {
                          await FirebaseFirestore.instance
                              .collection('patients')
                              .add({
                                'firstName': firstName,
                                'middleName': middleName,
                                'lastName': lastName,
                                'birthday': birthday,
                                'phone': phone,
                                'email': email,
                                'address': address,
                                'healthCondition': healthCondition,
                                'assignedDoctorId': selectedDoctorId,
                                'centerId': widget.centerId,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                          Navigator.pop(context);
                          _showSnack(
                            "Patient added successfully",
                            success: true,
                          );
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

  // 🧩 Helper function
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon:
              icon != null
                  ? Icon(icon, color: primaryColor)
                  : const Icon(Icons.circle, color: Colors.transparent),
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  /// Archived Patients Popup
  void _showArchivedPatientsPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Archived Patients'),
          content: SizedBox(
            width: 500,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .where('centerId', isEqualTo: widget.centerId)
                      .where('status', isEqualTo: 'archived')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text('No archived patients.');

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final fullName =
                        '${data['lastName'] ?? ''}, ${data['firstName'] ?? ''}';
                    return ListTile(
                      title: Text(fullName),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'restore') {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(docs[index].id)
                                .update({'status': 'active'});
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'restore',
                                child: Text(
                                  'Restore',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .where('centerId', isEqualTo: widget.centerId)
              .where('status', isEqualTo: 'active')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading patients.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;

        if (_searchText.isNotEmpty) {
          docs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = _getFullName(data).toLowerCase();
                return name.contains(_searchText);
              }).toList();
        }

        // Sorting logic (unchanged)
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          final firstNameA =
              (dataA['firstName'] ?? '').toString().toLowerCase();
          final firstNameB =
              (dataB['firstName'] ?? '').toString().toLowerCase();
          final lastNameA = (dataA['lastName'] ?? '').toString().toLowerCase();
          final lastNameB = (dataB['lastName'] ?? '').toString().toLowerCase();

          final timeA =
              (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final timeB =
              (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);

          switch (_sortOption) {
            case 'Last Name (Z–A)':
              return lastNameB.compareTo(lastNameA);
            case 'First Name (A–Z)':
              return firstNameA.compareTo(firstNameB);
            case 'First Name (Z–A)':
              return firstNameB.compareTo(firstNameA);
            case 'Newest':
              return timeB.compareTo(timeA);
            case 'Oldest':
              return timeA.compareTo(timeB);
            default:
              return lastNameA.compareTo(lastNameB);
          }
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No patients found.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final patient = docs[index];
            final data = patient.data() as Map<String, dynamic>;
            final fullName = _getFullName(data);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 14),
              child: Card(
                color: primaryColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  title: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 18, // ✅ larger and clearer
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'archive') {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(patient.id)
                            .update({'status': 'archived'});
                      }
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'archive',
                            child: Text(
                              'Archive',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PatientDetailScreen(
                              patientId: patient.id,
                              centerId: widget.centerId,
                              centerName: widget.centerName,
                            ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: SideMenu(
              centerId: widget.centerId,
              centerName: widget.centerName,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                /// Header Bar
                Container(
                  color: darkerPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.centerName,
                        style: const TextStyle(
                          fontSize: 28, // ✅ consistent header font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Archived Patients',
                            icon: const Icon(
                              Icons.archive_outlined,
                              color: Colors.white,
                            ),
                            onPressed: _showArchivedPatientsPopup,
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _showAddPatientDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              'Add Patient',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// Section Header
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Patient List',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),

                /// Search and Sort
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search patient by name...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _sortOption,
                        items: const [
                          DropdownMenuItem(
                            value: 'Last Name (A–Z)',
                            child: Text('Last Name (A–Z)'),
                          ),
                          DropdownMenuItem(
                            value: 'Last Name (Z–A)',
                            child: Text('Last Name (Z–A)'),
                          ),
                          DropdownMenuItem(
                            value: 'First Name (A–Z)',
                            child: Text('First Name (A–Z)'),
                          ),
                          DropdownMenuItem(
                            value: 'First Name (Z–A)',
                            child: Text('First Name (Z–A)'),
                          ),
                          DropdownMenuItem(
                            value: 'Newest',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'Oldest',
                            child: Text('Oldest'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortOption = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                /// Patient List
                Expanded(child: _buildPatientList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
