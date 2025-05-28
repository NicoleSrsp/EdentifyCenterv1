import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'archive_patient_screen.dart';

class HomeScreen extends StatefulWidget {
  final String centerName;
  final String doctorId;

  const HomeScreen({
    super.key,
    required this.centerName,
    required this.doctorId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  DateTime _selectedDate = DateTime.now();

  String? doctorName;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('doctor_inCharge')
          .doc(widget.doctorId)
          .get();

      if (!docSnapshot.exists) {
        setState(() {
          errorMessage = 'Doctor not found.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        doctorName = docSnapshot.data()?['name'] ?? 'Doctor';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load doctor info: $e';
        isLoading = false;
      });
    }
  }

  String _getFullName(Map<String, dynamic> data) {
    return '${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''}'
        .replaceAll(RegExp(' +'), ' ')
        .trim();
  }

  Widget _buildPatientList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('doctorInCharge', isEqualTo: widget.doctorId)
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
            final data = doc.data() as Map<String, dynamic>;
            final fullName = _getFullName(data).toLowerCase();
            return fullName.contains(_searchText);
          }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text('No patients found.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final patient = docs[index];
            final data = patient.data() as Map<String, dynamic>;
            final fullName = _getFullName(data);
            final healthCondition = data['healthCondition'] ?? 'N/A';
            final birthday = data['birthday'] ?? 'Unknown';

            return Card(
              color: Colors.teal.shade400,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  fullName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Condition: $healthCondition',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Birthday: $birthday',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                trailing: _tabController.index == 0
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'archive') {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(patient.id)
                                  .update({'status': 'archived'});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Patient is now archived')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to archive patient: $e')),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'archive',
                            child: Text('Archive'),
                          ),
                        ],
                      )
                    : null,
                onTap: () {
                  // Navigate or show details if needed
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingApprovals() {
    if (doctorName == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_approvals')
          .where('doctorInCharge', isEqualTo: doctorName)
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
            final approvalData = approval.data() as Map<String, dynamic>;
            final patientName = approvalData['patientName'] ?? 'Unknown';
            final submittedDate = approvalData['createdAt'] != null
                ? (approvalData['createdAt'] as Timestamp).toDate().toString()
                : 'Unknown date';

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
                        'approvalData': approvalData,
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
                .collection('users')
                .where('centerId', isEqualTo: widget.centerName)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error loading schedules'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              final patientsForToday = docs.where((doc) {
                final patientData = doc.data() as Map<String, dynamic>;
                final birthday = patientData['birthday'] as String?;
                if (birthday == null) return false;

                final todayFormatted = formatDate(_selectedDate);
                return birthday.contains(todayFormatted.substring(5)); // MM-DD
              }).toList();

              if (patientsForToday.isEmpty) {
                return const Center(child: Text('No patients scheduled for this day.'));
              }

              return ListView.builder(
                itemCount: patientsForToday.length,
                itemBuilder: (context, index) {
                  final patient = patientsForToday[index];
                  final patientData = patient.data() as Map<String, dynamic>;
                  final fullName = _getFullName(patientData);

                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(fullName),
                    subtitle: Text('Birthday: ${patientData['birthday']}'),
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
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          backgroundColor: Colors.teal.shade700,
        ),
        body: Center(child: Text(errorMessage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 8),
            const Text(
              'Edentify',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Patients'),
            Tab(text: 'Pending Approvals'),
            Tab(text: 'Schedules'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout logic
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Patients Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search patients',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      icon: const Icon(Icons.archive),
                      label: const Text('Archive'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArchivedPatientsScreen(
                              centerName: widget.centerName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildPatientList()),
            ],
          ),

          // Pending Approvals Tab
          _buildPendingApprovals(),

          // Schedules Tab
          _buildSchedules(),
        ],
      ),
    );
  }
}
