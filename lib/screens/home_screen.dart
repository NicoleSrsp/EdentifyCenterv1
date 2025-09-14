import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'side_menu.dart';

class HomeScreen extends StatefulWidget {
  final String centerId;
  final String centerName;

  const HomeScreen({super.key, required this.centerId, required this.centerName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  List<Map<String, dynamic>> patients = [];

  final List<String> shifts = ['First', 'Second', 'Third'];
  final List<String> days = ['M', 'T', 'W', 'TH', 'F'];

  List<Map<String, dynamic>> get weeklyPatients {
    DateTime startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    return patients.where((p) {
      final date = p['date'] as DateTime;
      final matchWeek =
          !date.isBefore(startOfWeek) && !date.isAfter(endOfWeek);
      final matchSearch =
          searchQuery.isEmpty || p['name'].toLowerCase().contains(searchQuery.toLowerCase());
      return matchWeek && matchSearch;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _addPatient() {
    String name = '';
    String frequency = 'M,W,F';
    String shift = 'First';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Patient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Patient Name"),
              onChanged: (v) => name = v,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Frequency"),
              initialValue: frequency,
              items: const [
                DropdownMenuItem(value: 'M,W,F', child: Text('M,W,F')),
                DropdownMenuItem(value: 'T,TH', child: Text('T,TH')),
              ],
              onChanged: (v) {
                if (v != null) frequency = v;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Shift"),
              initialValue: shift,
              items: shifts
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) shift = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                setState(() {
                  patients.add({
                    'name': name,
                    'frequency': frequency,
                    'shift': shift,
                    'date': selectedDate
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTable() {
    Map<String, Map<String, List<String>>> table = {};
    for (var s in shifts) {
      table[s] = {for (var d in days) d: []};
    }

    for (var p in weeklyPatients) {
      final pShift = p['shift'];
      final pFreq = p['frequency'].split(',');
      final date = p['date'] as DateTime;
      final dayAbbr = days[(date.weekday - 1) % 5];

      if (pFreq.contains(dayAbbr)) {
        table[pShift]?[dayAbbr]?.add(p['name']);
      }
    }

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          children: [
            const SizedBox(),
            ...days.map((d) => Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          ],
        ),
        ...shifts.map((s) {
          return TableRow(
            children: [
              Center(child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold))),
              ...days.map((d) {
                final names = table[s]?[d] ?? [];
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: names.map((n) => Text(n)).toList(),
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String monthYear = DateFormat.yMMMM().format(selectedDate);

    return Scaffold(
      body: Row(
        children: [
          // Permanent Side Menu
          SideMenu( centerId: widget.centerId, centerName: widget.centerName, selectedMenu: 'Home'),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: date picker + search + add
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            Text(
                              monthYear,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Search Patient",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            setState(() {
                              searchQuery = v;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _addPatient,
                        tooltip: 'Add Patient',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildWeeklyTable(),
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
