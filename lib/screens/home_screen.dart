import 'package:edentifyweb/screens/add_patient_record_screen.dart';
import 'package:edentifyweb/screens/patient_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String centerId;
  final String centerName;

  const HomeScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isDarkMode = false;
  DateTime selectedDate = DateTime.now();
  String searchQuery = '';
  List<Map<String, dynamic>> allPatients = [];
  List<Map<String, dynamic>> schedules = [];

  final List<String> shifts = ['1st Shift', '2nd Shift', '3rd Shift'];

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _fetchSchedules();
  }

  DateTime _normalizeToMonday(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime get startOfWeek => _normalizeToMonday(selectedDate);
  DateTime get endOfWeek => startOfWeek.add(const Duration(days: 6));

  String get weekRange {
    return "${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd').format(endOfWeek)}";
  }

  Future<void> _fetchPatients() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('centerId', isEqualTo: widget.centerId)
              .where('status', isEqualTo: 'active')
              .get();

      final loaded =
          snapshot.docs.map((doc) {
            final data = doc.data();
            final last = (data['lastName'] ?? '').toString();
            final first = (data['firstName'] ?? '').toString();
            String name;
            if (last.isNotEmpty && first.isNotEmpty) {
              name = '$last, $first';
            } else if (last.isNotEmpty) {
              name = last;
            } else if (first.isNotEmpty) {
              name = first;
            } else {
              name = (data['name'] ?? '').toString();
            }
            return {'id': doc.id, 'name': name};
          }).toList();

      setState(() {
        allPatients = loaded;
      });
    } catch (e) {
      setState(() => allPatients = []);
    }
  }

  Future<void> _fetchSchedules() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('centers')
              .doc(widget.centerId)
              .collection('schedules')
              .get();

      final loaded =
          snapshot.docs.map((doc) {
            final d = doc.data();
            Timestamp? ts = d['weekOf'];
            final weekOf = ts?.toDate();
            return {
              'id': doc.id,
              'name': (d['patientName'] ?? '').toString(),
              'days':
                  (d['days'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [],
              'shift': (d['shift'] ?? '').toString(),
              'weekOf': weekOf != null ? _normalizeToMonday(weekOf) : null,
            };
          }).toList();

      setState(() => schedules = loaded);
    } catch (e) {
      setState(() => schedules = []);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _deleteSchedule(String scheduleId) async {
    try {
      await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('schedules')
          .doc(scheduleId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete schedule: $e')));
    }
  }

  Future<void> _logNurseActivity({
    required String nurseId,
    required String nurseName,
    required String action,
    required String patientName,
  }) async {
    await FirebaseFirestore.instance
        .collection('centers')
        .doc(widget.centerId)
        .collection('activityLogs')
        .add({
          'nurseId': nurseId,
          'nurseName': nurseName,
          'action': action,
          'patientName': patientName,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _confirmAndDeleteSchedule(
    String scheduleId,
    String patientName,
  ) async {
    String? selectedNurseId;
    String? enteredPin;
    List<QueryDocumentSnapshot>? nurses;

    try {
      // Fetch all nurses for this center
      final nurseSnapshot =
          await FirebaseFirestore.instance
              .collection('centers')
              .doc(widget.centerId)
              .collection('nurses')
              .orderBy('createdAt', descending: false)
              .get();

      nurses = nurseSnapshot.docs;

      if (nurses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No nurses found for this center.')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching nurses: $e')));
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Confirm Schedule Removal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to remove "$patientName" from the schedule?',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  // 🩺 Nurse Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedNurseId,
                    decoration: const InputDecoration(
                      labelText: 'Select Nurse',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        (nurses ?? []).map((nurse) {
                          final name = nurse['name'] ?? 'Unnamed Nurse';
                          return DropdownMenuItem<String>(
                            value: nurse.id,
                            child: Text(name),
                          );
                        }).toList(),
                    onChanged:
                        (value) => setState(() => selectedNurseId = value),
                  ),

                  const SizedBox(height: 12),

                  // 🔐 PIN Input
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Enter Nurse PIN',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    onChanged: (value) => enteredPin = value.trim(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedNurseId == null ||
                        enteredPin == null ||
                        enteredPin!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a nurse and enter the PIN.',
                          ),
                        ),
                      );
                      return;
                    }

                    final selectedNurse = nurses!.firstWhere(
                      (n) => n.id == selectedNurseId,
                    );
                    final correctPin = (selectedNurse['pin'] ?? '').toString();

                    if (enteredPin == correctPin) {
                      // ✅ Delete the schedule
                      await FirebaseFirestore.instance
                          .collection('centers')
                          .doc(widget.centerId)
                          .collection('schedules')
                          .doc(scheduleId)
                          .delete();

                      // 🧾 Log nurse activity
                      await _logNurseActivity(
                        nurseId: selectedNurse.id,
                        nurseName: selectedNurse['name'] ?? 'Unknown',
                        action: 'Removed patient from schedule',
                        patientName: patientName,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Schedule removed by ${selectedNurse['name']}.',
                            ),
                            backgroundColor: Colors.teal.shade700,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incorrect PIN. Please try again.'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // unchanged logic for _addPatient() — only UI styling enhanced
  void _addPatient() async {
    String? selectedPatientId;
    String? selectedPatientName;
    String frequency = '3x';
    List<String> selectedDays = [];
    String? selectedShift;
    DateTime? selectedWeek;

    final TextEditingController searchController = TextEditingController();
    String localSearch = '';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setDialogState) {
              final filteredPatients = allPatients;
              final suggestions =
                  filteredPatients.where((p) {
                    final name = (p['name'] ?? '').toString().toLowerCase();
                    return name.startsWith(localSearch.toLowerCase());
                  }).toList();

              final allowedDays =
                  int.tryParse(frequency.replaceAll('x', '')) ?? 1;
              final canAdd =
                  selectedPatientId != null &&
                  selectedDays.length == allowedDays &&
                  selectedShift != null &&
                  selectedWeek != null;

              final weekDays =
                  selectedWeek == null
                      ? <DateTime>[]
                      : List<DateTime>.generate(
                        5,
                        (i) => selectedWeek!.add(Duration(days: i)),
                      );

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Add Patient Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Patient (Last, First)',
                            hintText: 'Type last name first',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (v) {
                            setDialogState(() {
                              localSearch = v.trim();
                              selectedPatientId = null;
                              selectedPatientName = null;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        if (localSearch.isNotEmpty && selectedPatientId == null)
                          SizedBox(
                            height: 140,
                            child:
                                suggestions.isEmpty
                                    ? const Center(
                                      child: Text('No matches found'),
                                    )
                                    : Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      child: ListView.builder(
                                        itemCount: suggestions.length,
                                        itemBuilder: (context, i) {
                                          final p = suggestions[i];
                                          return ListTile(
                                            title: Text(p['name'] ?? ''),
                                            onTap: () {
                                              setDialogState(() {
                                                selectedPatientId = p['id'];
                                                selectedPatientName = p['name'];
                                                searchController.text =
                                                    selectedPatientName ?? '';
                                                localSearch = '';
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                          ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: frequency,
                          decoration: InputDecoration(
                            labelText: 'Frequency',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '1x',
                              child: Text('1x a week'),
                            ),
                            DropdownMenuItem(
                              value: '2x',
                              child: Text('2x a week'),
                            ),
                            DropdownMenuItem(
                              value: '3x',
                              child: Text('3x a week'),
                            ),
                            DropdownMenuItem(
                              value: '4x',
                              child: Text('4x a week'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setDialogState(() {
                              frequency = v;
                              selectedDays = [];
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedWeek = _normalizeToMonday(picked);
                                selectedDays = [];
                              });
                            }
                          },
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            selectedWeek == null
                                ? "Pick Week"
                                : "Week of ${DateFormat('MMM dd, yyyy').format(selectedWeek!)}",
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (selectedWeek != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Select $allowedDays day(s):',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                weekDays.map((d) {
                                  final key = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(d);
                                  final isSelected = selectedDays.contains(key);
                                  final disabled =
                                      !isSelected &&
                                      selectedDays.length >= allowedDays;
                                  return ChoiceChip(
                                    label: Text(DateFormat('EEE dd').format(d)),
                                    selected: isSelected,
                                    selectedColor: Colors.teal.shade100,
                                    onSelected:
                                        disabled
                                            ? (_) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'You can only pick $allowedDays day(s)',
                                                  ),
                                                ),
                                              );
                                            }
                                            : (selected) {
                                              setDialogState(() {
                                                if (selected) {
                                                  selectedDays.add(key);
                                                } else {
                                                  selectedDays.remove(key);
                                                }
                                              });
                                            },
                                  );
                                }).toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedShift,
                          decoration: InputDecoration(
                            labelText: 'Shift',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items:
                              shifts
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setDialogState(() => selectedShift = v),
                        ),
                        const SizedBox(height: 12),
                        if (selectedPatientName != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Selected: $selectedPatientName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.teal,
                              ),
                            ),
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
                  FilledButton.icon(
                    onPressed:
                        canAdd
                            ? () async {
                              // 🔍 Step 1: Check if already scheduled this week and shift
                              // 🔍 Step 1: Check if already scheduled this week and shift
                              // 🔍 Step 1: Check if patient already has ANY existing schedule
                              // ✅ Step 1: Check if patient already has an *unfinished* schedule
                              final existing =
                                  await FirebaseFirestore.instance
                                      .collection('centers')
                                      .doc(widget.centerId)
                                      .collection('schedules')
                                      .where(
                                        'patientId',
                                        isEqualTo: selectedPatientId,
                                      )
                                      .get();

                              bool hasActiveSchedule = false;
                              Map<String, dynamic>? activeScheduleData;

                              for (var doc in existing.docs) {
                                final data = doc.data();
                                final Map<String, dynamic>? doneByDay =
                                    (data['isDoneByDay']
                                        as Map<String, dynamic>?) ??
                                    {};
                                final List<dynamic> scheduledDays =
                                    (data['days'] ?? []);

                                // Check if at least one day is not yet done
                                final stillOngoing = scheduledDays.any(
                                  (d) => doneByDay?[d.toString()] != true,
                                );

                                if (stillOngoing) {
                                  hasActiveSchedule = true;
                                  activeScheduleData = data;
                                  break;
                                }
                              }

                              if (hasActiveSchedule &&
                                  activeScheduleData != null) {
                                // Extract readable info for dialog
                                final Timestamp? weekTs =
                                    activeScheduleData['weekOf'];
                                final DateTime? weekOf = weekTs?.toDate();
                                final String shift =
                                    activeScheduleData['shift'] ?? '';
                                final List<dynamic> daysList =
                                    activeScheduleData['days'] ?? [];

                                // Format the week range (Mon–Fri)
                                String weekText = 'Unknown date';
                                if (weekOf != null) {
                                  final weekStart = _normalizeToMonday(weekOf);
                                  final weekEnd = weekStart.add(
                                    const Duration(days: 4),
                                  );
                                  weekText =
                                      '${DateFormat('MMM dd, yyyy').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}';
                                }

                                // Format weekday names
                                final formattedDays = daysList
                                    .map((d) {
                                      try {
                                        final date = DateTime.parse(d);
                                        return DateFormat('EEEE').format(date);
                                      } catch (_) {
                                        return d.toString();
                                      }
                                    })
                                    .join(', ');

                                // ❌ Show alert if there’s an ongoing (not fully done) schedule
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final screenWidth =
                                        MediaQuery.of(context).size.width;
                                    return Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: screenWidth * 0.9,
                                          minWidth: 380,
                                        ),
                                        child: AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          title: const Text(
                                            'Cannot Add Schedule',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent,
                                              fontSize: 20,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                '⚠️ This patient still has an ongoing dialysis schedule.\n\nPlease mark all days as done before adding a new one.',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                '🗓 Week: $weekText',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '📅 Days: $formattedDays',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '⏰ Shift: $shift',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text(
                                                'OK',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                                return;
                              }

                              // ✅ Step 2: Add new schedule
                              final ref = await FirebaseFirestore.instance
                                  .collection('centers')
                                  .doc(widget.centerId)
                                  .collection('schedules')
                                  .add({
                                    'patientId': selectedPatientId ?? '',
                                    'patientName': selectedPatientName ?? '',
                                    'centerId': widget.centerId,
                                    'frequency': frequency,
                                    'days': List<String>.from(selectedDays),
                                    'shift': selectedShift ?? '',
                                    'weekOf': Timestamp.fromDate(selectedWeek!),
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                              setState(() {
                                schedules.add({
                                  'id': ref.id,
                                  'name': selectedPatientName,
                                  'days': List<String>.from(selectedDays),
                                  'shift': selectedShift,
                                  'weekOf': selectedWeek,
                                });
                              });

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '✅ Schedule added successfully!',
                                    ),
                                    backgroundColor: Colors.teal.shade700,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                            : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // same logic, only better visual
  Widget _buildWeeklyTable() {
    final start = startOfWeek;
    final end = endOfWeek;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('centers')
              .doc(widget.centerId)
              .collection('schedules')
              .where(
                'weekOf',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('weekOf', isLessThanOrEqualTo: Timestamp.fromDate(end))
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final weekDays = List<DateTime>.generate(
          5,
          (i) => start.add(Duration(days: i)),
        );

        Map<String, Map<String, List<Map<String, dynamic>>>> table = {
          for (var s in shifts)
            s: {for (var d in weekDays) DateFormat('yyyy-MM-dd').format(d): []},
        };

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['patientName'] ?? '').toString();
            final pShift = (data['shift'] ?? '').toString();
            final pDays =
                (data['days'] as List<dynamic>? ?? [])
                    .map((e) => e.toString())
                    .toList();
            final isDoneByDay = Map<String, dynamic>.from(
              data['isDoneByDay'] ?? {},
            );

            if (searchQuery.isNotEmpty &&
                !name.toLowerCase().contains(searchQuery.toLowerCase())) {
              continue;
            }

            if (table.containsKey(pShift)) {
              for (var d in pDays) {
                if (table[pShift]?[d] != null) {
                  table[pShift]?[d]?.add({
                    'id': doc.id,
                    'name': name,
                    'isDoneByDay': isDoneByDay,
                  });
                }
              }
            }
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Week: $weekRange",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    defaultColumnWidth: const FixedColumnWidth(220),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100.withOpacity(0.4),
                        ),
                        children: [
                          _tableHeader('Shift/Day'),
                          ...weekDays.map(
                            (d) =>
                                _tableHeader(DateFormat('EEE\ndd').format(d)),
                          ),
                        ],
                      ),
                      ...shifts.map((s) {
                        final index = shifts.indexOf(s);
                        return TableRow(
                          decoration: BoxDecoration(
                            color:
                                index.isEven
                                    ? Colors.grey.shade50
                                    : Colors.white,
                          ),
                          children: [
                            _tableCell(
                              s,
                              isHeader: true,
                              align: TextAlign.center,
                            ),
                            ...weekDays.map((d) {
                              final key = DateFormat('yyyy-MM-dd').format(d);
                              final patients = table[s]?[key] ?? [];

                              if (patients.isEmpty) {
                                return _tableCell('-');
                              }

                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      patients.map((p) {
                                        final isDoneByDay =
                                            Map<String, dynamic>.from(
                                              p['isDoneByDay'] ?? {},
                                            );
                                        final isDone = isDoneByDay[key] == true;

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  try {
                                                    final now = DateTime.now();
                                                    final todayKey = DateFormat(
                                                      'yyyy-MM-dd',
                                                    ).format(
                                                      DateTime(
                                                        now.year,
                                                        now.month,
                                                        now.day,
                                                      ),
                                                    );

                                                    // 🧩 Get patient data from the schedule document
                                                    final schedulePatientId =
                                                        p['id'] ?? '';
                                                    final schedulePatientName =
                                                        p['name'] ?? '';

                                                    print(
                                                      "🧠 Patient map contents: $p",
                                                    );
                                                    print(
                                                      "👤 Tapped patient: $schedulePatientName",
                                                    );
                                                    print(
                                                      "📄 Schedule patientId: $schedulePatientId",
                                                    );

                                                    if (schedulePatientName
                                                        .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Missing patient name.',
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    // 🧩 Split "Reyes, Mika" into lastName = Reyes, firstName = Mika
                                                    final nameParts =
                                                        schedulePatientName
                                                            .split(',');
                                                    final lastName =
                                                        nameParts.first.trim();
                                                    final firstName =
                                                        nameParts.length > 1
                                                            ? nameParts[1]
                                                                .trim()
                                                            : '';

                                                    // 🔎 Find real userId in "users" collection
                                                    final userQuery =
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .where(
                                                              'firstName',
                                                              isEqualTo:
                                                                  firstName,
                                                            )
                                                            .where(
                                                              'lastName',
                                                              isEqualTo:
                                                                  lastName,
                                                            )
                                                            .limit(1)
                                                            .get();

                                                    String realUserId;
                                                    if (userQuery
                                                        .docs
                                                        .isNotEmpty) {
                                                      realUserId =
                                                          userQuery
                                                              .docs
                                                              .first
                                                              .id;
                                                      print(
                                                        "✅ Found matching userId: $realUserId",
                                                      );
                                                    } else {
                                                      realUserId =
                                                          schedulePatientId; // fallback
                                                      print(
                                                        "⚠️ No user found by name, using schedule ID: $realUserId",
                                                      );
                                                    }

                                                    print(
                                                      "🔗 Real userId used: $realUserId",
                                                    );

                                                    // 🧾 FIXED 🔍 Check if today's record (e.g. 2025-10-19_pre) exists
                                                    final recordsCollection =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(realUserId)
                                                            .collection(
                                                              'records',
                                                            );

                                                    final querySnap =
                                                        await recordsCollection
                                                            .where(
                                                              FieldPath
                                                                  .documentId,
                                                              isGreaterThanOrEqualTo:
                                                                  todayKey,
                                                            )
                                                            .where(
                                                              FieldPath
                                                                  .documentId,
                                                              isLessThan:
                                                                  '${todayKey}_z',
                                                            )
                                                            .get();

                                                    final hasTodayRecord =
                                                        querySnap
                                                            .docs
                                                            .isNotEmpty;
                                                    final existingRecordId =
                                                        hasTodayRecord
                                                            ? querySnap
                                                                .docs
                                                                .first
                                                                .id
                                                            : null;

                                                    print(
                                                      "🧾 Found today's record? $hasTodayRecord (id: $existingRecordId)",
                                                    );

                                                    if (!context.mounted)
                                                      return;

                                                    // 🧭 Ask what to do next
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (ctx) => AlertDialog(
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    16,
                                                                  ),
                                                            ),
                                                            title: Text(
                                                              'Dialysis Record Action - ${p['name'] ?? ''}',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            content: Text(
                                                              hasTodayRecord
                                                                  ? 'A dialysis record for ${p['name'] ?? ''} already exists for today. Would you like to edit it instead?'
                                                                  : 'No dialysis record found for ${p['name'] ?? ''} today. Would you like to add one now?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () =>
                                                                        Navigator.pop(
                                                                          ctx,
                                                                        ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              FilledButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                    ctx,
                                                                  );
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (_) =>
                                                                              hasTodayRecord
                                                                                  ? PatientDetailScreen(
                                                                                    patientId:
                                                                                        realUserId,
                                                                                    centerId:
                                                                                        widget.centerId,
                                                                                    centerName:
                                                                                        widget.centerName,
                                                                                  )
                                                                                  : AddPatientRecordScreen(
                                                                                    patientId:
                                                                                        realUserId,
                                                                                    centerId:
                                                                                        widget.centerId,
                                                                                    centerName:
                                                                                        widget.centerName,
                                                                                  ),
                                                                    ),
                                                                  );
                                                                },
                                                                child: Text(
                                                                  hasTodayRecord
                                                                      ? "Edit Today's Record"
                                                                      : "Add New Record",
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  } catch (e) {
                                                    print(
                                                      "⚠️ Error checking record: $e",
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Error checking record: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },

                                                child: Text(
                                                  p['name'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    decoration:
                                                        isDone
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                    color:
                                                        isDone
                                                            ? Colors.grey
                                                            : Colors
                                                                .teal
                                                                .shade900,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),

                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    isDone
                                                        ? Icons.check_box
                                                        : Icons
                                                            .check_box_outline_blank,
                                                    color: Colors.teal,
                                                    size: 18,
                                                  ),
                                                  tooltip:
                                                      isDone
                                                          ? 'Mark as not done'
                                                          : 'Mark as done',
                                                  onPressed: () async {
                                                    final docRef =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'centers',
                                                            )
                                                            .doc(
                                                              widget.centerId,
                                                            )
                                                            .collection(
                                                              'schedules',
                                                            )
                                                            .doc(p['id']);
                                                    await docRef.update({
                                                      'isDoneByDay.$key':
                                                          !isDone,
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip:
                                                      'Remove from schedule',
                                                  onPressed: () async {
                                                    await _confirmAndDeleteSchedule(
                                                      p['id']!,
                                                      p['name'] ?? '',
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18, // 🔹 increased from 14
          color: Color(0xFF045347),
        ),
      ),
    ),
  );

  Widget _tableCell(
    String text, {
    bool isHeader = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
          fontSize: isHeader ? 18 : 16, // 🔹 larger for both header and content
          color: isHeader ? Colors.teal.shade800 : Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat.yMMMM().format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      body: Row(
        children: [
          SideMenu(
            centerId: widget.centerId,
            centerName: widget.centerName,
            selectedMenu: 'Home',
          ),
          Expanded(
            child: Column(
              children: [
                // HEADER BAR
                Container(
                  color: const Color(0xFF045347),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.centerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white, // 👈 keeps the icon white
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SettingsScreen(
                                    centerId: widget.centerId,
                                    centerName: widget.centerName,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // MAIN CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Toolbar
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      monthYear, // 👈 Displays the formatted month + year
                                      style: const TextStyle(
                                        color: Color(0xFF045347),
                                        fontSize: 28, // ✅ Updated
                                        fontWeight:
                                            FontWeight.bold, // ✅ Updated
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 280,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search Patient',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                                onChanged:
                                    (v) => setState(() => searchQuery = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _addPatient,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Schedule'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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
          ),
        ],
      ),
    );
  }
}
