import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarkActiveScreen extends StatefulWidget {
  const MarkActiveScreen({super.key});

  @override
  State<MarkActiveScreen> createState() => _MarkActiveScreenState();
}

class _MarkActiveScreenState extends State<MarkActiveScreen> {
  bool _isRunning = false;
  String _message = '';

  Future<void> _markAllPatientsActive() async {
    setState(() {
      _isRunning = true;
      _message = 'Updating patients...';
    });

    try {
      final patientsSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      int updatedCount = 0;

      for (var doc in patientsSnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('status')) {
          await doc.reference.update({'status': 'active'});
          updatedCount++;
        }
      }

      setState(() {
        _message = 'Finished! Updated $updatedCount patients to active.';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark All Patients Active')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRunning)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _markAllPatientsActive,
                child: const Text('Mark All Patients Active'),
              ),
            const SizedBox(height: 16),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
