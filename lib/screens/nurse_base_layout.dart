import 'package:flutter/material.dart';
import 'side_menu.dart';

class NurseBaseLayout extends StatelessWidget {
  final String centerId;
  final String centerName;
  final String selectedMenu;
  final Widget content;

  const NurseBaseLayout({
    super.key,
    required this.centerId,
    required this.centerName,
    required this.selectedMenu,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      body: Row(
        children: [
          // ✅ Left side menu
          SideMenu(
            centerId: centerId,
            centerName: centerName,
            selectedMenu: selectedMenu,
          ),

          // ✅ Right side main content
          Expanded(
            child: Column(
              children: [
                // ✅ Fixed header height for consistency
                Container(
                  height: 80, // 🔒 lock the header height
                  color: const Color(0xFF045347),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        centerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Colors.white70),
                        tooltip: 'Help & Support',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // ✅ Consistent main content area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xFFF5F8FA),
                    child: content,
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
