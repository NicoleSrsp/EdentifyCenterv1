import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';

class AboutScreen extends StatelessWidget {
  final String centerId;
  final String centerName;
  final String address;
  final String contactNumber;
  final String missionVision;
  final String staffInfo;
  final String doctorsInfo;
  final String logoAsset;

  const AboutScreen({
    super.key,
    required this.centerId,
    required this.centerName,
    required this.address,
    required this.contactNumber,
    required this.missionVision,
    required this.staffInfo,
    required this.doctorsInfo,
    required this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SideMenu(
            centerId: centerId,
            centerName: centerName,
            selectedMenu: 'About Center',
          ),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage(logoAsset),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              centerName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(address, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(contactNumber,
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Mission and Vision',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(missionVision, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  const Text('Staff',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(staffInfo, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  const Text('Doctors',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(doctorsInfo, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
