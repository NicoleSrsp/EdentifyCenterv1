import 'package:flutter/material.dart';
import 'side_menu.dart';

const Color primaryColor = Color(0xFF056C5B);
const Color darkerPrimaryColor = Color(0xFF045347);

class SettingsScreen extends StatelessWidget {
  final String centerId;
  final String centerName;

  const SettingsScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          // ✅ Left Side Menu
          SizedBox(
            width: 250,
            child: SideMenu(
              centerId: centerId,
              centerName: centerName,
              selectedMenu: 'Settings',
            ),
          ),

          // ✅ Main Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Top Header (consistent style)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  color: darkerPrimaryColor,
                  child: Text(
                    centerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28, // ✅ consistent header font
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ✅ Page Title
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28, // ✅ larger and consistent title font
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),

                // ✅ Main Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Main Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Contact Support
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.support_agent,
                                    color: primaryColor,
                                  ),
                                ),
                                title: const Text(
                                  'Contact Support',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _modernDialog(
                                      context,
                                      title: 'Contact Support',
                                      content:
                                          '📧 Email us at:\n\naesync@gmail.com\n\nWe’ll get back to you shortly!',
                                    ),
                                  );
                                },
                              ),

                              const Divider(height: 1),

                              // Terms & Privacy
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.privacy_tip,
                                    color: primaryColor,
                                  ),
                                ),
                                title: const Text(
                                  'View Terms & Privacy',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _modernDialog(
                                      context,
                                      title: 'Terms & Privacy',
                                      content:
                                          'Welcome to Edentify!\n\n'
                                          'We value your trust and are committed to protecting your privacy.\n\n'
                                          '• All patient data is securely stored and only accessible by authorized medical staff.\n\n'
                                          '• We do not share personal or medical information with any third parties.\n\n'
                                          '• By using this application, you agree to follow our guidelines and terms of use.\n\n'
                                          'If you have any questions, feel free to contact support.\n\n'
                                          'Last updated: October 2025',
                                    ),
                                  );
                                },
                              ),
                            ],
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

  // 🪄 Reusable modern dialog widget
  Widget _modernDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: primaryColor, size: 42),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: darkerPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkerPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
