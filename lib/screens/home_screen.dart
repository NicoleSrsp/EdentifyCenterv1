import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final String centerName;
  final String doctorName;

  const HomeScreen({
    super.key,
    required this.centerName,
    required this.doctorName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? doctorId;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDoctorId();
  }

  Future<void> _fetchDoctorId() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctor_inCharge')
          .where('name', isEqualTo: widget.doctorName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = 'Doctor not found.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        doctorId = querySnapshot.docs.first.id;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load doctor info: $e';
        isLoading = false;
      });
    }
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
        appBar: AppBar(title: const Text('Home')),
        body: Center(child: Text(errorMessage)),
      );
    }

    // doctorId is loaded, show the list of users assigned to this doctor
    return Scaffold(
      appBar: AppBar(
        title: Text('Patients of ${widget.doctorName}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('doctorInCharge', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading patients: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final patients = snapshot.data?.docs ?? [];

          if (patients.isEmpty) {
            return const Center(child: Text('No patients found.'));
          }

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final data = patients[index].data() as Map<String, dynamic>;

              final fullName =
                  '${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''}'
                      .replaceAll(RegExp(' +'), ' ')
                      .trim();

              final healthCondition = data['healthCondition'] ?? 'N/A';
              final birthday = data['birthday'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(fullName),
                  subtitle: Text('Health Condition: $healthCondition\nBirthday: $birthday'),
                  isThreeLine: true,
                  onTap: () {
                    // TODO: Navigate to patient folder or details screen if any
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
