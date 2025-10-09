import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';

class NursesScreen extends StatefulWidget {
  final String centerId;
  const NursesScreen({super.key, required this.centerId});

  @override
  State<NursesScreen> createState() => _NursesScreenState();
}

class _NursesScreenState extends State<NursesScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();

  Future<void> _addNurse() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and PIN')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('nurses')
          .add({
        'name': name,
        'pin': pin,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _pinController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nurse added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding nurse: $e')),
      );
    }
  }

  Future<void> _deleteNurse(String nurseId) async {
    await FirebaseFirestore.instance
        .collection('centers')
        .doc(widget.centerId)
        .collection('nurses')
        .doc(nurseId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nurse deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            centerId: widget.centerId,
            centerName: 'Center',
            selectedMenu: 'Nurses',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nurses',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF045347),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Nurse',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nurse Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pinController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'PIN',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _addNurse,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Nurse'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Existing Nurses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF045347),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('centers')
                          .doc(widget.centerId)
                          .collection('nurses')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.teal,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No nurses found'),
                          );
                        }

                        final nurses = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: nurses.length,
                          itemBuilder: (context, index) {
                            final nurse = nurses[index];
                            final name = nurse['name'] ?? 'Unnamed';
                            final pin = nurse['pin'] ?? '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.person,
                                    color: Colors.teal),
                                title: Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text('PIN: ${pin.replaceAll(RegExp(r"."), "•")}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteNurse(nurse.id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
