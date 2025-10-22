import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the screens you need to navigate to
import '../patient/patient_detail_screen.dart';
import '../patient/add_patient_record_screen.dart';

/// A dedicated widget to display the weekly patient schedule table.
/// This is refactored from the HomeScreen to keep the code clean and modular.
class ScheduleCard extends StatelessWidget {
  final String weekRange;
  final List<DateTime> weekDays;
  final List<String> shifts;
  final Map<String, Map<String, List<Map<String, dynamic>>>> table;
  final String centerId;
  final String centerName;
  final Function(String, String) onDeleteSchedule; // Callback for deleting

  const ScheduleCard({
    super.key,
    required this.weekRange,
    required this.weekDays,
    required this.shifts,
    required this.table,
    required this.centerId,
    required this.centerName,
    required this.onDeleteSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. LARGER WEEK TITLE
            Text(
              "Week: $weekRange",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              // 2. REMOVED all borders
              columnWidths: {
                0: const IntrinsicColumnWidth(),
                ...Map.fromIterable(
                  List.generate(weekDays.length, (index) => index + 1),
                  key: (item) => item,
                  value: (item) => const FlexColumnWidth(1.0),
                ),
              },
              children: [
                // --- TABLE HEADER ROW ---
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  children: [
                    // 3. STYLED TABLE HEADER
                    _buildStyledHeader('Shift/Day'),
                    ...weekDays.map(
                      (d) => _buildStyledHeader(DateFormat('EEE\ndd').format(d)),
                    ),
                  ],
                ),
                // --- DATA ROWS (SHIFTS) ---
                ...shifts.map((s) {
                  final index = shifts.indexOf(s);
                  return TableRow(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // 4. SHIFT SEPARATION
                      border: Border(
                        top: BorderSide(
                          color: index == 0
                              ? Colors.grey.shade200
                              : Colors.grey.shade400,
                          width: index == 0 ? 1.0 : 1.5,
                        ),
                      ),
                    ),
                    children: [
                      // 5. STYLED SHIFT CELL
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        child: Text(
                          s, // "1st Shift", "2nd Shift"
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                      // --- Patient Cells for the week ---
                      ...weekDays.map((d) {
                        final key = DateFormat('yyyy-MM-dd').format(d);
                        final patients = table[s]?[key] ?? [];

                        if (patients.isEmpty) {
                          // 6. STYLED EMPTY CELL
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '-',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: patients.map((p) {
                              final isDoneByDay = Map<String, dynamic>.from(
                                  p['isDoneByDay'] ?? {});
                              final isDone = isDoneByDay[key] == true;

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: MouseRegion(
                                      cursor: isDone
                                          ? SystemMouseCursors.basic
                                          : SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: isDone
                                            ? null
                                            : () async {
                                                try {
                                                  // ✅ 1. GET TODAY'S DATE (for comparison)
                                                  final now = DateTime.now();
                                                  final today = DateTime(
                                                      now.year,
                                                      now.month,
                                                      now.day);

                                                  // ✅ 2. GET CLICKED DATE
                                                  // 'd' is the date for the column
                                                  final clickedDate = DateTime(
                                                      d.year, d.month, d.day);
                                                  final isToday = clickedDate
                                                      .isAtSameMomentAs(today);

                                                  // ✅ 3. USE CLICKED DATE FOR KEYS
                                                  final clickedDateKey =
                                                      DateFormat('yyyy-MM-dd')
                                                          .format(clickedDate);
                                                  final clickedDateFormatted =
                                                      DateFormat(
                                                              'MMM dd, yyyy')
                                                          .format(clickedDate);

                                                  final schedulePatientId =
                                                      p['id'] ?? '';
                                                  final schedulePatientName =
                                                      p['name'] ?? '';

                                                  if (schedulePatientName
                                                      .isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Missing patient name.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  // ... (find realUserId logic is unchanged)
                                                  final nameParts =
                                                      schedulePatientName
                                                          .split(',');
                                                  final lastName =
                                                      nameParts.first.trim();
                                                  final firstName =
                                                      nameParts.length > 1
                                                          ? nameParts[1].trim()
                                                          : '';

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
                                                      .docs.isNotEmpty) {
                                                    realUserId =
                                                        userQuery.docs.first.id;
                                                  } else {
                                                    realUserId =
                                                        schedulePatientId; // fallback
                                                  }

                                                  final recordsCollection =
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(realUserId)
                                                          .collection(
                                                            'records',
                                                          );

                                                  // ✅ 4. CHECK FOR RECORDS ON CLICKED DATE
                                                  final preDoc =
                                                      await recordsCollection
                                                          .doc(
                                                              '${clickedDateKey}_pre')
                                                          .get();
                                                  final postDoc =
                                                      await recordsCollection
                                                          .doc(
                                                              '${clickedDateKey}_post')
                                                          .get();

                                                  final preRecordExists =
                                                      preDoc.exists;
                                                  final postRecordExists =
                                                      postDoc.exists;

                                                  if (!context.mounted) return;

                                                  // ✅ 5. NEW SMARTER DIALOG LOGIC
                                                  String title =
                                                      'Dialysis Record Action';
                                                  String content;
                                                  String confirmText;
                                                  bool canAddRecord = true;

                                                  if (preRecordExists &&
                                                      postRecordExists) {
                                                    // --- CASE 1: Both records exist ---
                                                    title = 'Records Complete';
                                                    content =
                                                        'Both pre and post-dialysis records already exist for $schedulePatientName on $clickedDateFormatted.';
                                                    confirmText = 'OK';
                                                    canAddRecord = false;
                                                  } else if (preRecordExists) {
                                                    // --- CASE 2: Pre exists, ask for post ---
                                                    content =
                                                        'A pre-dialysis record exists for $schedulePatientName on $clickedDateFormatted. Add post-dialysis data?';
                                                    confirmText =
                                                        'Add Post-Dialysis';
                                                  } else {
                                                    // --- CASE 3: No records exist ---
                                                    content =
                                                        'No dialysis record found for $schedulePatientName on $clickedDateFormatted. Add a new record?';
                                                    confirmText =
                                                        'Add New Record';
                                                  }

                                                  // ✅ 6. ADD WARNING IF NOT TODAY
                                                  if (!isToday &&
                                                      canAddRecord) {
                                                    content =
                                                        '⚠️ WARNING: This schedule is for a different date ($clickedDateFormatted), not today.\n\n$content';
                                                  }

                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) =>
                                                        AlertDialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          16,
                                                        ),
                                                      ),
                                                      title: Text(
                                                        '$title - ${p['name'] ?? ''}',
                                                        style:
                                                            const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      content: Text(content),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                            ctx,
                                                          ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        // Only show the "Confirm" button if they can add a record
                                                        if (canAddRecord)
                                                          FilledButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  ctx);
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (_) =>
                                                                          AddPatientRecordScreen(
                                                                    patientId:
                                                                        realUserId,
                                                                    centerId:
                                                                        centerId,
                                                                    centerName:
                                                                        centerName,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Text(
                                                                confirmText),
                                                          )
                                                        else
                                                          // Show a simple "OK" button if records are complete
                                                          FilledButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    ctx),
                                                            child: Text(
                                                                confirmText),
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                } catch (e) {
                                                  print(
                                                    "⚠️ Error checking record: $e",
                                                  );
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error checking record: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 6.0),
                                          child: Text(
                                            p['name'] ?? '',
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              decoration: isDone
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.underline,
                                              decorationColor: Colors.teal,
                                              color: isDone
                                                  ? Colors.grey.shade600
                                                  : Colors.teal.shade900,
                                              fontWeight: isDone
                                                  ? FontWeight.normal
                                                  : FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          isDone
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          color: isDone
                                              ? Colors.grey
                                              : Colors.teal,
                                          size: 20,
                                        ),
                                        tooltip: isDone
                                            ? 'Mark as not done'
                                            : 'Mark as done',
                                        onPressed: () async {
                                          final docRef = FirebaseFirestore
                                              .instance
                                              .collection(
                                                'centers',
                                              )
                                              .doc(
                                                centerId,
                                              )
                                              .collection(
                                                'schedules',
                                              )
                                              .doc(p['id']);
                                          await docRef.update({
                                            'isDoneByDay.$key': !isDone,
                                          });
                                        },
                                      ),
                                      IconButton(
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: isDone
                                              ? Colors.grey
                                              : Colors.red.shade400,
                                        ),
                                        tooltip: 'Remove from schedule',
                                        onPressed: isDone
                                            ? null
                                            : () async {
                                                await onDeleteSchedule(
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
          ],
        ),
      ),
    );
  }

  // 8. HELPER WIDGET for the styled header
  Widget _buildStyledHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black54,
        ),
      ),
    );
  }
}