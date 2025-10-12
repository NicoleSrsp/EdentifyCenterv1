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
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('centerId', isEqualTo: widget.centerId)
          .where('status', isEqualTo: 'active')
          .get();

      final loaded = snapshot.docs.map((doc) {
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
      final snapshot = await FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('schedules')
          .get();

      final loaded = snapshot.docs.map((doc) {
        final d = doc.data();
        Timestamp? ts = d['weekOf'];
        final weekOf = ts?.toDate();
        return {
          'id': doc.id,
          'name': (d['patientName'] ?? '').toString(),
          'days': (d['days'] as List<dynamic>?)
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

  // unchanged logic for _addPatient() — only UI styling enhanced
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final suggestions = allPatients.where((p) {
            final name = (p['name'] ?? '').toString().toLowerCase();
            return name.startsWith(localSearch.toLowerCase());
          }).toList();

          final allowedDays =
              int.tryParse(frequency.replaceAll('x', '')) ?? 1;
          final canAdd = selectedPatientId != null &&
              selectedDays.length == allowedDays &&
              selectedShift != null &&
              selectedWeek != null;

          final weekDays = selectedWeek == null
              ? <DateTime>[]
              : List<DateTime>.generate(
                  5,
                  (i) => selectedWeek!.add(Duration(days: i)),
                );

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add Patient Schedule',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                        child: suggestions.isEmpty
                            ? const Center(child: Text('No matches'))
                            : Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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
                      value: frequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1x', child: Text('1x a week')),
                        DropdownMenuItem(value: '2x', child: Text('2x a week')),
                        DropdownMenuItem(value: '3x', child: Text('3x a week')),
                        DropdownMenuItem(value: '4x', child: Text('4x a week')),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: weekDays.map((d) {
                          final key = DateFormat('yyyy-MM-dd').format(d);
                          final isSelected = selectedDays.contains(key);
                          final disabled = !isSelected &&
                              selectedDays.length >= allowedDays;
                          return ChoiceChip(
                            label: Text(DateFormat('EEE dd').format(d)),
                            selected: isSelected,
                            selectedColor: Colors.teal.shade100,
                            onSelected: disabled
                                ? (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'You can only pick $allowedDays day(s)'),
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
                      value: selectedShift,
                      decoration: InputDecoration(
                        labelText: 'Shift',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: shifts
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedShift = v),
                    ),
                    const SizedBox(height: 12),
                    if (selectedPatientName != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Selected: $selectedPatientName',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.teal)),
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
                onPressed: canAdd
                    ? () async {
                        // logic unchanged
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

                        if (mounted) Navigator.pop(context);
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
      stream: FirebaseFirestore.instance
          .collection('centers')
          .doc(widget.centerId)
          .collection('schedules')
          .where('weekOf', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('weekOf', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final weekDays =
            List<DateTime>.generate(5, (i) => start.add(Duration(days: i)));

        Map<String, Map<String, List<String>>> table = {
          for (var s in shifts)
            s: {for (var d in weekDays) DateFormat('yyyy-MM-dd').format(d): []},
        };

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['patientName'] ?? '').toString();
            final pShift = (data['shift'] ?? '').toString();
            final pDays = (data['days'] as List<dynamic>? ?? [])
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

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Week: $weekRange",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    defaultColumnWidth: const FixedColumnWidth(140),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                            color: Colors.teal.shade100.withOpacity(0.4)),
                        children: [
                          _tableHeader('Shift/Day'),
                          ...weekDays.map(
                            (d) => _tableHeader(
                              DateFormat('EEE\ndd').format(d),
                            ),
                          ),
                        ],
                      ),
                      ...shifts.map((s) {
                        final index = shifts.indexOf(s);
                        return TableRow(
                          decoration: BoxDecoration(
                            color: index.isEven
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
                              final key =
                                  DateFormat('yyyy-MM-dd').format(d);
                              final names = table[s]?[key] ?? [];
                              return _tableCell(
                                names.isEmpty
                                    ? '-'
                                    : names.join('\n'),
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
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      );

  Widget _tableCell(String text,
      {bool isHeader = false, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {},
                        tooltip: 'Settings',
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
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      monthYear,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
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
                                onChanged: (v) =>
                                    setState(() => searchQuery = v),
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
