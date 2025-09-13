import 'package:flutter/material.dart';

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

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool selected,
    required String routeName,
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
      tileColor: selected ? Colors.teal.shade600 : Colors.teal.shade700,
      onTap: () {
        Navigator.pushReplacementNamed(
          context,
          routeName,
          arguments: {
            'centerId': centerId,    
            'centerName': centerName, 
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.teal.shade700,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
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
              ],
            ),
          ),
          const Divider(color: Colors.white, height: 2),
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
            icon: Icons.settings,
            title: 'Doctors',
            selected: selectedMenu == 'Doctors',
            routeName: '/doctors',
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.logout,
            title: 'Logout',
            selected: selectedMenu == 'Logout',
            routeName: '/',
          ),
        ],
      ),
    );
  }
}
