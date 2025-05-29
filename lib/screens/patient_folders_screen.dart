import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_history_screen.dart';

class PatientFoldersScreen extends StatefulWidget {
  final String patientId;
  const PatientFoldersScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  _PatientFoldersScreenState createState() => _PatientFoldersScreenState();
}

class _PatientFoldersScreenState extends State<PatientFoldersScreen> {
  Map<String, dynamic>? patientData;
  Map<DateTime, Map<String, List<Map<String, dynamic>>>> dataByDate = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchPatientDataAndSubcollections();
  }

  Future<void> _fetchPatientDataAndSubcollections() async {
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.patientId);
      final userDocSnap = await userDocRef.get();

      if (!userDocSnap.exists) {
        setState(() {
          error = 'Patient data not found.';
          isLoading = false;
        });
        return;
      }

      patientData = userDocSnap.data();

      // Fetch subcollections in parallel
      final scanSnap = await userDocRef.collection('scanHistory').get();
      final treatmentSnap = await userDocRef.collection('treatment_data').get();
      final waterSnap = await userDocRef.collection('waterIntake').get();

      // Helper to extract dateKey/dates in DateTime (year, month, day only)
      DateTime? extractDate(Map<String, dynamic> docData, List<String> possibleFields) {
        for (var field in possibleFields) {
          if (docData[field] != null) {
            final val = docData[field];
            if (val is Timestamp) {
              final dt = val.toDate();
              return DateTime(dt.year, dt.month, dt.day);
            } else if (val is String) {
              // try parse string date if needed
              try {
                final dt = DateTime.parse(val);
                return DateTime(dt.year, dt.month, dt.day);
              } catch (_) {}
            }
          }
        }
        return null;
      }

      void addDataToMap(List<QueryDocumentSnapshot> docs, String subCollectionName, List<String> dateFields) {
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final date = extractDate(data, dateFields);
          if (date != null) {
            dataByDate.putIfAbsent(date, () => {});
            dataByDate[date]!.putIfAbsent(subCollectionName, () => []);
            dataByDate[date]![subCollectionName]!.add(data);
          }
        }
      }

      addDataToMap(scanSnap.docs, 'scanHistory', ['dateKey']);
      addDataToMap(treatmentSnap.docs, 'treatment_data', ['dialysisDate']);
      addDataToMap(waterSnap.docs, 'waterIntake', ['date']);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load data: $e';
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
        title: const Text(
          'Patient Folders',
          style: TextStyle(color: Colors.white), // Title text color
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Back arrow color
        backgroundColor: const Color.fromARGB(255, 0, 121, 107),
      ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
           title: const Text(
          'Patient Folders',
          style: TextStyle(color: Colors.white), // Title text color
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Back arrow color
        backgroundColor: const Color.fromARGB(255, 0, 121, 107),
      ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (patientData == null) {
      return Scaffold(
        appBar: AppBar(
           title: const Text(
          'Patient Folders',
          style: TextStyle(color: Colors.white), // Title text color
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Back arrow color
        backgroundColor: const Color.fromARGB(255, 0, 121, 107),
      ),
        body: const Center(child: Text('No patient data found.')),
      );
    }

    if (dataByDate.isEmpty) {
      return Scaffold(
        appBar: AppBar(
           title: const Text(
          'Patient Folders',
          style: TextStyle(color: Colors.white), // Title text color
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Back arrow color
        backgroundColor: const Color.fromARGB(255, 0, 121, 107),
      ),
        body: const Center(child: Text('No history found for this patient.')),
      );
    }

    // Sort dates descending
    final dates = dataByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
       appBar: AppBar(
           title: const Text(
          'Patient Folders',
          style: TextStyle(color: Colors.white), // Title text color
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Back arrow color
        backgroundColor: const Color.fromARGB(255, 0, 121, 107),
      ),
      body: ListView.builder(
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final dayData = dataByDate[date]!;

          // Check which subcollections are available on this date
          final availableCollections = dayData.keys.toList();

          return ListTile(
          leading: const Icon(Icons.folder),
          title: Text(_formatDate(date)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientHistoryScreen(
                  folder: patientData!,
                  docId: widget.patientId,
                  collectionName: 'users',
                  selectedDate: date,
                  readonly: false,
                ),
              ),
            );
          },
        );
        },
      ),
    );
  }
}
