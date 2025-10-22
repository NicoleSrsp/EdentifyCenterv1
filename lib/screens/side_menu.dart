import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'nurses_screen.dart';

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
      // ✅ Added padding for better alignment and spacing
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      leading: Icon(icon, color: Colors.white, size: 24), // Set explicit size
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16, // Set explicit font size
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: selected ? primaryColor : darkerPrimaryColor,
      // Added a subtle highlight for the selected item
      shape: selected
          ? const Border(left: BorderSide(color: Colors.white, width: 3.0))
          : null,
      onTap: () async {
        if (onTapOverride != null) {
          onTapOverride();
          return;
        }

        if (routeName == '/logout') {
          AuthService.logout(context);
          return;
        }

        if (routeName == '/aboutCenter') {
          final doc = await FirebaseFirestore.instance
              .collection('centers')
              .doc(centerId)
              .get();

          if (!doc.exists || !context.mounted) return;

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
              'logoAsset': data['logoAsset'] ?? 'assets/D.png',
            },
          );
        } else {
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
    // Get bottom padding for safe area (for notches, home bars, etc.)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: 200,
      color: darkerPrimaryColor,
      // ✅ Changed main Column structure
      child: Column(
        // This ensures the main items are at the top, and logout is at the bottom
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ This Expanded widget takes up all available space,
          // pushing the logout button to the bottom.
          Expanded(
            child: Column(
              children: [
                // --- HEADER ---
                InkWell(
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/home',
                      arguments: {
                        'centerId': centerId,
                        'centerName': centerName
                      },
                    );
                  },
                  child: Container(
                    // ✅ Adjusted padding to align logo with menu items below
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Vertically center
                      children: [
                        SizedBox(
                          width: 40, // Made logo container square
                          height: 40,
                          child: Image.asset('assets/D.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Edentify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // ✅ Removed the VerticalDivider for a cleaner look
                      ],
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1), // Subtle divider

                // --- TOP MENU ITEMS ---
                _buildMenuItem(context: context, icon: Icons.home, title: 'Home', selected: selectedMenu == 'Home', routeName: '/home'),
                _buildMenuItem(context: context, icon: Icons.people, title: 'Patients', selected: selectedMenu == 'Patients', routeName: '/patients'),
                _buildMenuItem(context: context, icon: Icons.medical_services, title: 'Doctors', selected: selectedMenu == 'Doctors', routeName: '/doctors'),
                _buildMenuItem(
                  context: context,
                  icon: Icons.vaccines,
                  title: 'Nurses',
                  selected: selectedMenu == 'Nurses',
                  routeName: '/nurses',
                  onTapOverride: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => NursesScreen(centerId: centerId, centerName: centerName)),
                    );
                  },
                ),
                _buildMenuItem(context: context, icon: Icons.info, title: 'About Center', selected: selectedMenu == 'About Center', routeName: '/aboutCenter'),
              ],
            ),
          ),

          // --- LOGOUT BUTTON AT THE BOTTOM ---
          // This is now outside the Expanded widget
          Column(
            children: [
              const Divider(color: Colors.white24, height: 1), // Divider above logout
              _buildMenuItem(
                context: context,
                icon: Icons.logout,
                title: 'Log Out',
                selected: selectedMenu == 'Logout',
                routeName: '/logout',
              ),
              // ✅ Add padding at the very bottom for the phone's safe area
              SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
            ],
          ),
        ],
      ),
    );
  }
}