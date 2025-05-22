import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  final String centerName;
  const HomeScreen({super.key, required this.centerName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPatientList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .where('center', isEqualTo: widget.centerName)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading patients'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;

        if (_searchText.isNotEmpty) {
          docs = docs.where((doc) {
            final name = (doc['name'] ?? '').toString().toLowerCase();
            return name.contains(_searchText);
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text('No patients found.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final patient = docs[index];
            return Card(
              color: Colors.teal.shade400,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                title: Text(
                  patient['name'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'archive') {
                      FirebaseFirestore.instance
                          .collection('patients')
                          .doc(patient.id)
                          .update({'status': 'archived'});
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'archive', child: Text('Archive')),
                  ],
                ),
                onTap: () {
                  final data = patient.data()! as Map<String, dynamic>;
                  final patientIdValue = data['patientId'];

                  if (patientIdValue != null && patientIdValue.isNotEmpty) {
                    Navigator.pushNamed(context, '/folders', arguments: patientIdValue);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Patient ID not found for this patient.')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingApprovals() {
    final doctorId = 'doctor_001';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_approvals')
          .where('doctor_id', isEqualTo: doctorId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error loading approvals'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No pending approvals.'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final approval = docs[index];
            final patientName = approval['patient_name'] ?? 'Unknown';
            final submittedDate = approval['submitted_date'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(patientName),
                subtitle: Text('Submitted on $submittedDate'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/entryDetail',
                      arguments: {
                        'folder': approval.data() as Map<String, dynamic>,
                        'docId': approval.id,
                      },
                    );
                  },
                  child: const Text('View'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSchedules() {
    String formatDate(DateTime date) {
      return "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";
    }

    return Column(
      children: [
        TableCalendar(
          focusedDay: _selectedDate,
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2030),
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
            });
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('patients')
                .where('center', isEqualTo: widget.centerName)
                .where('scheduledDate', isEqualTo: formatDate(_selectedDate))
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading schedules'));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No patients scheduled for this day.'));
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final patient = docs[index];
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(patient['name']),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('Edentify', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.notifications, color: Colors.white),
            label: const Text('Notifications', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Log Out', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.teal.shade700,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'List of Patients'),
            Tab(text: 'Pending for Approval'),
            Tab(text: 'Schedules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey.shade200,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.archive),
                      label: const Text(''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 1, 119, 121),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/archivedPatients', arguments: widget.centerName);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildPatientList()),
            ],
          ),
          _buildPendingApprovals(),
          _buildSchedules(),
        ],
      ),
    );
  }
}
