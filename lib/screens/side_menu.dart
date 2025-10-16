import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nurses_screen.dart'; // ✅ make sure this file exists

class SideMenu extends StatelessWidget {
  final String centerId;
  final String centerName;
  final String selectedMenu;

  const SideMenu({
    super.key,
    required this.centerId,
    required this.centerName,
    this.selectedMenu = 'Home',
  });

  static const Color primaryColor = Color(0xFF056C5B);
  static const Color darkerPrimaryColor = Color(0xFF045347);

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool selected,
    required String routeName,
    VoidCallback? onTapOverride,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: selected ? primaryColor : darkerPrimaryColor,
      onTap: () async {
        if (onTapOverride != null) {
          onTapOverride();
          return;
        }

        // 🔹 Handle Logout separately
        if (routeName == '/logout') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm Logout"),
              content: const Text("Are you sure you want to log out?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Logout"),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await FirebaseAuth.instance.signOut();

            // 🔹 Navigate back to login screen and clear navigation stack
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          }
          return;
        }

        // 🔹 If About Center, fetch details from Firebase first
        if (routeName == '/aboutCenter') {
          final doc = await FirebaseFirestore.instance
              .collection('centers')
              .doc(centerId)
              .get();

          if (!doc.exists) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Center details not found')),
            );
            return;
          }

          final data = doc.data()!;
          Navigator.pushReplacementNamed(
            context,
            routeName,
            arguments: {
              'centerId': centerId,
              'centerName': centerName,
              'address': data['address'] ?? '',
              'contactNumber': data['contactNumber'] ?? '',
              'missionVision': data['missionVision'] ?? '',
              'logoAsset': data['logoAsset'] ?? 'assets/logo.png',
            },
          );
        } else {
          // 🔹 Default navigation for other menu items
          Navigator.pushReplacementNamed(
            context,
            routeName,
            arguments: {
              'centerId': centerId,
              'centerName': centerName,
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: darkerPrimaryColor,
      child: Column(
        children: [
          // 🔹 Header (Clickable Logo + Text)
          InkWell(
            onTap: () {
              // Navigate to Home screen
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: {
                  'centerId': centerId,
                  'centerName': centerName,
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 40,
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edentify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const VerticalDivider(
                    color: Colors.white,
                    thickness: 1,
                    width: 20,
                  )
                ],
              ),
            ),
          ),

          // 🔹 Menu Items
          _buildMenuItem(
            context: context,
            icon: Icons.home,
            title: 'Home',
            selected: selectedMenu == 'Home',
            routeName: '/home',
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.people,
            title: 'Patients',
            selected: selectedMenu == 'Patients',
            routeName: '/patients',
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.medical_services,
            title: 'Doctors',
            selected: selectedMenu == 'Doctors',
            routeName: '/doctors',
          ),
          // 🧑‍⚕️ Nurses Section
          _buildMenuItem(
            context: context,
            icon: Icons.vaccines,
            title: 'Nurses',
            selected: selectedMenu == 'Nurses',
            routeName: '/nurses',
            onTapOverride: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NursesScreen(
                    centerId: centerId,
                    centerName: centerName,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.info,
            title: 'About Center',
            selected: selectedMenu == 'About Center',
            routeName: '/aboutCenter',
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.logout,
            title: 'Logout',
            selected: selectedMenu == 'Logout',
            routeName: '/logout', // ✅ now triggers sign out logic
          ),
        ],
      ),
    );
  }
}
