import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';

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

  /// Normalize a date to Monday 00:00 of that week
  DateTime _normalizeToMonday(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  // Calculate Monday–Sunday week range
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

  void _addPatient() {
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
              final suggestions =
                  allPatients.where((p) {
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

              // Generate weekdays for the chosen week
              final weekDays =
                  selectedWeek == null
                      ? <DateTime>[]
                      : List<DateTime>.generate(
                        5,
                        (i) => selectedWeek!.add(Duration(days: i)),
                      );

              return AlertDialog(
                title: const Text('Add Patient Schedule'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search Patient (Last, First)',
                            hintText: 'Type last name first',
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
                                    ? const Center(child: Text('No matches'))
                                    : ListView.builder(
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
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: frequency,
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
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
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                // normalize to Monday 00:00
                                selectedWeek = _normalizeToMonday(picked);
                                selectedDays = [];
                              });
                            }
                          },
                          child: Text(
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
                          decoration: const InputDecoration(labelText: 'Shift'),
                          items:
                              shifts
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            setDialogState(() => selectedShift = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        if (selectedPatientName != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Selected: $selectedPatientName'),
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
                    onPressed:
                        canAdd
                            ? () async {
                              try {
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
                                      'weekOf': Timestamp.fromDate(
                                        selectedWeek!,
                                      ),
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

                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving: $e')),
                                );
                              }
                            }
                            : null,
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Weekly Table with filtering by weekOf (full week range)
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

        Map<String, Map<String, List<String>>> table = {
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

            if (searchQuery.isNotEmpty &&
                !name.toLowerCase().contains(searchQuery.toLowerCase())) {
              continue;
            }

            if (table.containsKey(pShift)) {
              for (var d in pDays) {
                if (table[pShift]?[d] != null) {
                  table[pShift]?[d]?.add(name);
                }
              }
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Week: $weekRange",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                defaultColumnWidth: const FixedColumnWidth(140),
                children: [
                  TableRow(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey.shade200,
                        child: const Text(
                          'Shift/Day',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...weekDays.map(
                        (d) => Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Text(
                              DateFormat('EEE\ndd').format(d),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...shifts.map((s) {
                    return TableRow(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            s,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...weekDays.map((d) {
                          final key = DateFormat('yyyy-MM-dd').format(d);
                          final names = table[s]?[key] ?? [];
                          return Container(
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minHeight: 60),
                            child:
                                names.isEmpty
                                    ? const Text('-')
                                    : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children:
                                          names.map((n) => Text(n)).toList(),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat.yMMMM().format(selectedDate);

    return Scaffold(
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
                // 🔹 Header bar (center name, same style as PatientListScreen)
                Container(
                  color: const Color(0xFF045347), // darkerPrimaryColor
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      const SizedBox(width: 16), // consistent padding
                      Text(
                        widget.centerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28, // ✅ updated to match PatientListScreen
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 🔹 Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickDate,
                              child: Row(
                                children: [
                                  Text(
                                    monthYear,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                  hintText: 'Search Patient',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged:
                                    (v) => setState(() => searchQuery = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.person_add),
                              onPressed: _addPatient,
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
          ),
        ],
      ),
    );
  }
}
