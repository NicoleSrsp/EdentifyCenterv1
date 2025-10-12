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
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 100,
            vertical: 50,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Add New Patient",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkerPrimaryColor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.black54,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// Personal Information Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Personal Information",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              TextField(
                                controller: firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                ),
                              ),
                              TextField(
                                controller: middleNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Middle Name',
                                ),
                              ),
                              TextField(
                                controller: lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                ),
                              ),
                              TextField(
                                controller: birthdayController,
                                decoration: const InputDecoration(
                                  labelText: 'Birthday (YYYY-MM-DD)',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Contact Information Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Contact Information",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              TextField(
                                controller: addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Health Information Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Health Information",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
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
                              const SizedBox(height: 8),
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('doctor_inCharge')
                                        .where(
                                          'centerId',
                                          isEqualTo: widget.centerId,
                                        )
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
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
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          return DropdownMenuItem<String>(
                                            value: doc.id,
                                            child: Text(
                                              data['name'] ?? "No Name",
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedDoctorId = value;
                                          final doctorDoc = docs.firstWhere(
                                            (d) => d.id == value,
                                          );
                                          selectedDoctorName =
                                              (doctorDoc.data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >)['name'];
                                        });
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// Account Information Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Account Information",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              TextField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                              ),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final firstName = firstNameController.text.trim();
                              final middleName =
                                  middleNameController.text.trim();
                              final lastName = lastNameController.text.trim();
                              final birthday = birthdayController.text.trim();
                              final phone = phoneController.text.trim();
                              final email = emailController.text.trim();
                              final address = addressController.text.trim();
                              final startDate = startDateController.text.trim();
                              final health = healthController.text.trim();
                              final password = passwordController.text.trim();
                              final confirmPassword =
                                  confirmPasswordController.text.trim();

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
                                  const SnackBar(
                                    content: Text("All fields are required."),
                                  ),
                                );
                                return;
                              }

                              if (password != confirmPassword) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Passwords do not match."),
                                  ),
                                );
                                return;
                              }

                              if (selectedDoctorId == null ||
                                  selectedDoctorName == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please assign a doctor."),
                                  ),
                                );
                                return;
                              }

                              try {
                                UserCredential cred = await FirebaseAuth
                                    .instance
                                    .createUserWithEmailAndPassword(
                                      email: email,
                                      password: password,
                                    );

                                final uid = cred.user!.uid;

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
                                    content: Text(
                                      "Patient added successfully.",
                                    ),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Auth error: ${e.message}"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            },
                            child: const Text("Add Patient"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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

        // Sorting logic
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
            ),
          ),
          Expanded(
            child: Column(
              children: [
                /// Header Bar
                /// Header Bar (Simplified — Center Name Only)
                Container(
                  color: Color(0xFF045347),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.centerName,
                        style: const TextStyle(
                          fontSize: 28,
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
                            label: const Text('Add Patient'),
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

                /// Search and Sort
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search patient by name',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
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
