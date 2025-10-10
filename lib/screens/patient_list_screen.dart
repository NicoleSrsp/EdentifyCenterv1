import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'side_menu.dart';
import 'patient_detail_screen.dart';

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

  // Sorting option
  String _sortOption = 'Last Name (A–Z)';

  // Custom brand colors
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

  /// Pop-up dialog to add new patient
  void _showAddPatientDialog() {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController middleNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController birthdayController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController healthController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    String? selectedDoctorId;
    String? selectedDoctorName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Patient'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: middleNameController,
                  decoration: const InputDecoration(labelText: 'Middle Name'),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: birthdayController,
                  decoration: const InputDecoration(
                    labelText: 'Birthday (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Start of Treatment (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: healthController,
                  decoration: const InputDecoration(
                    labelText: 'Health Condition(s)',
                  ),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                // Dropdown for doctors under this center
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('doctor_inCharge')
                          .where('centerId', isEqualTo: widget.centerId)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Text("No doctors available.");
                    }

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Assign Doctor",
                      ),
                      value: selectedDoctorId,
                      items:
                          docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(data['name'] ?? "No Name"),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedDoctorId = value;
                          final doctorDoc = docs.firstWhere(
                            (d) => d.id == value,
                          );
                          selectedDoctorName =
                              (doctorDoc.data()
                                  as Map<String, dynamic>)['name'];
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final firstName = firstNameController.text.trim();
                final middleName = middleNameController.text.trim();
                final lastName = lastNameController.text.trim();
                final birthday = birthdayController.text.trim();
                final phone = phoneController.text.trim();
                final email = emailController.text.trim();
                final address = addressController.text.trim();
                final startDate = startDateController.text.trim();
                final health = healthController.text.trim();
                final password = passwordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (firstName.isEmpty ||
                    lastName.isEmpty ||
                    birthday.isEmpty ||
                    phone.isEmpty ||
                    address.isEmpty ||
                    startDate.isEmpty ||
                    health.isEmpty ||
                    password.isEmpty ||
                    email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required.")),
                  );
                  return;
                }

                if (password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords do not match.")),
                  );
                  return;
                }

                if (selectedDoctorId == null || selectedDoctorName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please assign a doctor.")),
                  );
                  return;
                }

                try {
                  // ✅ Create patient account in FirebaseAuth
                  UserCredential cred = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );

                  final uid = cred.user!.uid;

                  // ✅ Save patient profile in Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .set({
                        'firstName': firstName,
                        'middleName': middleName,
                        'lastName': lastName,
                        'birthday': birthday,
                        'phone': phone,
                        'email': email,
                        'address': address,
                        'startDate': startDate,
                        'healthConditions': health,
                        'centerId': widget.centerId,
                        'centerName': widget.centerName,
                        'doctorId': selectedDoctorId,
                        'doctorName': selectedDoctorName,
                        'status': 'active',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                  // ✅ Create a notification for the assigned doctor
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(selectedDoctorId)
                      .collection('notifications')
                      .add({
                        'title': 'New Patient Assigned',
                        'message':
                            '$firstName $lastName has been assigned to you.',
                        'patientId': uid,
                        'createdAt': FieldValue.serverTimestamp(),
                        'read': false,
                      });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Patient added successfully."),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Auth error: ${e.message}")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// Popup for archived patients
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

        // ✅ Updated Sorting Logic
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
            default: // Last Name (A–Z)
              return lastNameA.compareTo(lastNameB);
          }
        });

        if (docs.isEmpty) {
          return const Center(child: Text('No patients found.'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final patient = docs[index];
            final data = patient.data() as Map<String, dynamic>;
            final fullName = _getFullName(data);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
            );
          },
        );
      },
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
              selectedMenu: 'Patients',
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.person_add, color: primaryColor),
                        tooltip: 'Add Patient',
                        onPressed: _showAddPatientDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive, color: primaryColor),
                        tooltip: 'Archived Patients',
                        onPressed: _showArchivedPatientsPopup,
                      ),
                    ],
                  ),
                ),

                // ✅ Sorting Dropdown UI
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    bottom: 8.0,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Sort by: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF045347),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _sortOption,
                        dropdownColor: Colors.white,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Color(0xFF045347)),
                        borderRadius: BorderRadius.circular(8),
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
                            setState(() {
                              _sortOption = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Expanded(child: _buildPatientList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
