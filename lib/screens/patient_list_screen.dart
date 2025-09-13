import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
    final _formKey = GlobalKey<FormState>();
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Patient'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: mobileController,
                    decoration:
                        const InputDecoration(labelText: 'Mobile Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 121, 107),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final firstName = firstNameController.text.trim();
                  final lastName = lastNameController.text.trim();
                  final mobile = mobileController.text.trim();
                  final password = passwordController.text.trim();

                  // Check if mobile already exists
                  final existing = await FirebaseFirestore.instance
                      .collection('users')
                      .where('mobileNumber', isEqualTo: mobile)
                      .get();

                  if (existing.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Mobile number already exists')),
                    );
                    return;
                  }

                  // Hash password using SHA-256
                  final hashedPassword =
                      sha256.convert(utf8.encode(password)).toString();

                  // Add patient to Firestore
                  await FirebaseFirestore.instance.collection('users').add({
                    'firstName': firstName,
                    'lastName': lastName,
                    'mobileNumber': mobile,
                    'password': hashedPassword,
                    'centerId': widget.centerId,
                    'status': 'active',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
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
              stream: FirebaseFirestore.instance
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
                          } else if (value == 'rename') {
                            final TextEditingController renameController =
                                TextEditingController(text: fullName);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Rename Patient'),
                                content: TextField(
                                  controller: renameController,
                                  decoration: const InputDecoration(
                                      labelText: 'Full Name'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromARGB(255, 0, 121, 107),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final fullName =
                                          renameController.text.trim();

                                      String last = '';
                                      String first = '';

                                      if (fullName.contains(',')) {
                                        final parts = fullName.split(',');
                                        last = parts[0].trim();
                                        first = parts.length > 1
                                            ? parts[1].trim()
                                            : '';
                                      } else {
                                        final parts = fullName.split(' ');
                                        last = parts[0].trim();
                                        first = parts.length > 1
                                            ? parts.sublist(1).join(' ').trim()
                                            : '';
                                      }

                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(docs[index].id)
                                          .update({
                                        'firstName': first,
                                        'lastName': last,
                                      });

                                      Navigator.pop(context); // closes rename popup
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'restore',
                            child: Text(
                              'Restore',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text(
                              'Rename',
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
      stream: FirebaseFirestore.instance
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
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = _getFullName(data).toLowerCase();
            return name.contains(_searchText);
          }).toList();
        }

        docs.sort((a, b) {
          final nameA =
              _getFullName(a.data() as Map<String, dynamic>).toLowerCase();
          final nameB =
              _getFullName(b.data() as Map<String, dynamic>).toLowerCase();
          return nameA.compareTo(nameB);
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
              color: Colors.teal.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                title: Text(
                  fullName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (value) async {
                    if (value == 'archive') {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(patient.id)
                          .update({'status': 'archived'});
                    } else if (value == 'rename') {
                      final TextEditingController renameController =
                          TextEditingController(text: fullName);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Rename Patient'),
                          content: TextField(
                            controller: renameController,
                            decoration:
                                const InputDecoration(labelText: 'Full Name'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 121, 107),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final fullName =
                                    renameController.text.trim();

                                String last = '';
                                String first = '';

                                if (fullName.contains(',')) {
                                  final parts = fullName.split(',');
                                  last = parts[0].trim();
                                  first = parts.length > 1
                                      ? parts[1].trim()
                                      : '';
                                } else {
                                  final parts = fullName.split(' ');
                                  last = parts[0].trim();
                                  first = parts.length > 1
                                      ? parts.sublist(1).join(' ').trim()
                                      : '';
                                }

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(patient.id)
                                    .update({
                                  'firstName': first,
                                  'lastName': last,
                                });

                                Navigator.pop(context); // closes rename popup
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text(
                        'Archive',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text(
                        'Rename',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/folders',
                    arguments: patient.id,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        icon: const Icon(Icons.person_add, color: Colors.teal),
                        tooltip: 'Add Patient',
                        onPressed: _showAddPatientDialog,
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive, color: Colors.teal),
                        tooltip: 'Archived Patients',
                        onPressed: _showArchivedPatientsPopup,
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
