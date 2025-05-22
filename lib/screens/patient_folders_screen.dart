import 'package:cloud_firestore/cloud_firestore.dart';
import 'entry_detail_screen.dart';
import 'package:flutter/material.dart';

class PatientFoldersScreen extends StatelessWidget {
  final String patientId;
  const PatientFoldersScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    print('PatientFoldersScreen loaded with patientId: $patientId');

    if (patientId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Folders')),
        body: const Center(child: Text('No patient ID provided.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 121, 107), 
        foregroundColor: Colors.white,   
        title: const Text('Patient Folders')
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('folders')
            .where('patientId', isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error in folders stream: ${snapshot.error}');
            return const Center(child: Text('Error loading folders.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data!.docs;
          print('Found ${folders.length} folders for patientId: $patientId');

          if (folders.isEmpty) {
            return const Center(child: Text('No folders found.'));
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folderDoc = folders[index];
              final folderData = folderDoc.data()! as Map<String, dynamic>;
              print('Folder data: $folderData');

              return ListTile(
                leading: (folderData['photo_url'] != null && folderData['photo_url'].toString().isNotEmpty)
                    ? Image.network(
                        folderData['photo_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(folderData['date'] ?? 'No date'),
                subtitle: Text('Classification: ${folderData['classification'] ?? 'N/A'}'),
                trailing: Text(folderData['status'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EntryDetailScreen(
                        folder: folderData,    
                        docId: folderDoc.id,  
                        collectionName: 'pending_approvals',
                        readonly: true,       
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
