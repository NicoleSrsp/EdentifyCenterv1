import 'package:cloud_firestore/cloud_firestore.dart';

/// A data model class to hold the combined records for a single day.
/// This makes it much easier to work with in the UI.
class CombinedDialysisRecord {
  final String date;
  final Map<String, dynamic>? preDialysisData;
  final Map<String, dynamic>? postDialysisData;
  final String? preDocId;
  final String? postDocId;

  CombinedDialysisRecord({
    required this.date,
    this.preDialysisData,
    this.postDialysisData,
    this.preDocId,
    this.postDocId,
  });

  // A helper to get the most recent timestamp for sorting
  Timestamp get sortingTimestamp {
    final preTime = preDialysisData?['createdAt'] as Timestamp?;
    final postTime = postDialysisData?['createdAt'] as Timestamp?;
    // Use the post-dialysis time if it exists, otherwise the pre-dialysis time
    return postTime ?? preTime ?? Timestamp.now();
  }
}

/// A service class to handle fetching and processing patient records.
class RecordService {
  /// Fetches all records for a patient and combines pre/post records for the same date.
  ///
  /// This returns a stream of a list of [CombinedDialysisRecord] objects,
  /// already sorted and ready for the UI.
  static Stream<List<CombinedDialysisRecord>> streamCombinedRecords({
    required String patientId,
    required String sortOrder,
  }) {
    final recordsCollection = FirebaseFirestore.instance
        .collection("users")
        .doc(patientId)
        .collection("records");

    // Listen to the raw data stream from Firestore
    return recordsCollection.snapshots().map((snapshot) {
      // 1. Create a map to group records by date
      final Map<String, CombinedDialysisRecord> recordsByDate = {};

      // 2. Process each document from Firestore
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String?;
        final sessionType = data['sessionType'] as String?;

        if (date == null) continue; // Skip if no date

        // Get or create the combined record for this date
        final record = recordsByDate[date] ?? CombinedDialysisRecord(date: date);

        // 3. Slot the data into the correct property
        if (sessionType == 'pre') {
          recordsByDate[date] = CombinedDialysisRecord(
            date: date,
            preDialysisData: data,
            preDocId: doc.id,
            postDialysisData: record.postDialysisData, // Keep existing post-data
            postDocId: record.postDocId,
          );
        } else if (sessionType == 'post') {
          recordsByDate[date] = CombinedDialysisRecord(
            date: date,
            preDialysisData: record.preDialysisData, // Keep existing pre-data
            preDocId: record.preDocId,
            postDialysisData: data,
            postDocId: doc.id,
          );
        }
      }

      // 4. Convert the map values to a list
      final combinedList = recordsByDate.values.toList();

      // 5. Sort the list based on the user's preference
      combinedList.sort((a, b) {
        final timeA = a.sortingTimestamp;
        final timeB = b.sortingTimestamp;
        // The 'createdAt' timestamp is used for sorting
        return sortOrder == 'desc'
            ? timeB.compareTo(timeA)
            : timeA.compareTo(timeB);
      });

      return combinedList;
    });
  }
}
