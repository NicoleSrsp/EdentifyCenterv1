import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';

class NursesScreen extends StatefulWidget {
  final String centerId;
  final String centerName;

  const NursesScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<NursesScreen> createState() => _NursesScreenState();
}

class _NursesScreenState extends State<NursesScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  Future<void> _addNurse() async {
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty || pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both name and PIN'),
          backgroundColor: Colors.redAccent,
        ),
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
        SnackBar(
          content: const Text('✅ Nurse added successfully'),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding nurse: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteNurse(
    String nurseId,
    String nurseName,
    String storedPin,
  ) async {
    final pinController = TextEditingController();

    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete Nurse "$nurseName"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    final enteredPin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('PIN Verification'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter Nurse PIN',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, pinController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF045347),
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    if (enteredPin == null || enteredPin.isEmpty) return;

    if (enteredPin != storedPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN. Deletion cancelled.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('nurses')
          .doc(nurseId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Nurse "$nurseName" deleted successfully.'),
          backgroundColor: Colors.teal.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting nurse: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Row(
        children: [
          SideMenu(
            centerId: widget.centerId,
            centerName: widget.centerName,
            selectedMenu: 'Nurses',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ HEADER BAR
                Container(
                  color: const Color(0xFF045347),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.centerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {},
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ),

                // ✅ MAIN CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nurses Management',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF045347),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add or manage registered nurses under this dialysis center.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ✅ ADD NURSE CARD
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1,
                                        color: Color(0xFF045347),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Add New Nurse',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nameController,
                                          decoration: InputDecoration(
                                            labelText: 'Nurse Name',
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: _pinController,
                                          obscureText: true,
                                          decoration: InputDecoration(
                                            labelText: 'PIN',
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: _addNurse,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Nurse'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF047C70),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ✅ SEARCH BAR
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search nurse by name...",
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // ✅ EXISTING NURSES SECTION
                          const Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                color: Color(0xFF045347),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Existing Nurses',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF045347),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          StreamBuilder<QuerySnapshot>(
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
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(
                                      color: Colors.teal,
                                    ),
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      'No nurses found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 🔍 Filter nurses by search query
                              final filteredNurses = snapshot.data!.docs.where((doc) {
                                final name = (doc['name'] ?? '').toString().toLowerCase();
                                return name.contains(searchQuery);
                              }).toList();

                              if (filteredNurses.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No matching nurses found.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredNurses.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final nurse = filteredNurses[index];
                                  final name = nurse['name'] ?? 'Unnamed';
                                  final pin = nurse['pin'] ?? '';

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(0xFF045347)
                                            .withOpacity(0.1),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF045347),
                                        ),
                                      ),
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'PIN: ${pin.replaceAll(RegExp(r"."), "•")}',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            _confirmAndDeleteNurse(
                                          nurse.id,
                                          name,
                                          pin,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
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
