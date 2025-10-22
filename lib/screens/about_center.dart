import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'side_menu.dart';

class AboutScreen extends StatelessWidget {
  final String centerId;
  final String centerName;

  const AboutScreen({
    super.key,
    required this.centerId,
    required this.centerName,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("📌 AboutScreen opened with centerId: $centerId");

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // ✅ Sidebar
          SideMenu(
            centerId: centerId,
            centerName: centerName,
            selectedMenu: 'About Center',
          ),

          // ✅ Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Header
                Container(
                  color: const Color(0xFF045347),
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  width: double.infinity,
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
                    ],
                  ),
                ),

                // ✅ Scrollable Area
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('centers')
                        .doc(centerId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(child: Text('Center data not found.'));
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Introduction Card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.local_hospital_rounded,
                                          color: Color(0xFF045347), size: 36),
                                      SizedBox(width: 10),
                                      Text(
                                        "About Edentify",
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF045347),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Welcome to Edentify — a digital healthcare platform built to revolutionize the way dialysis patients, nurses, and doctors connect. "
                                    "Our goal is to make healthcare smarter, simpler, and more accessible through technology that promotes collaboration and timely care. "
                                    "Edentify bridges the gap between patients and healthcare professionals by providing real-time updates, accurate health monitoring, "
                                    "and secure data management powered by Firestore. Together, we are shaping a future where technology and compassion work hand in hand to improve lives.",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.8,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // 🔹 Expandable Sections
                            _buildExpansionTile(
                              icon: Icons.apps_rounded,
                              title: "System Overview",
                              content:
                                  "Edentify is composed of three interconnected platforms that work together to deliver continuous, coordinated healthcare:\n\n"
                                  "• Mobile App (for Patients): Patients can scan their feet to detect edema levels (mild, normal, or severe), record their daily water intake, and monitor their health conveniently.\n\n"
                                  "• Web App (for Nurses): Nurses can register new patients, manage dialysis schedules, and update vital signs — with every update instantly reflected in the patient’s app.\n\n"
                                  "• Web App (for Doctors): Doctors receive real-time updates about patient scans and vital signs, and can add medical notes or recommendations for ongoing patient care.",
                            ),
                            _buildExpansionTile(
                              icon: Icons.flag_rounded,
                              title: "Mission and Vision",
                              content:
                                  "• Mission: To empower healthcare providers and dialysis patients through innovative, data-driven tools that support efficient monitoring, communication, and decision-making — ensuring better health outcomes for every patient.\n\n"
                                  "• Vision: To become a trusted digital partner in healthcare, leading the way toward a connected ecosystem where every dialysis patient receives proactive, compassionate, and personalized care powered by technology.",
                            ),
                            _buildExpansionTile(
                              icon: Icons.favorite_rounded,
                              title: "Core Values",
                              content:
                                  "• Compassion: We put people first by delivering care that values every patient’s comfort and dignity.\n"
                                  "• Innovation: We use technology as a bridge — transforming traditional healthcare processes into smarter, data-driven systems.\n"
                                  "• Integrity: We uphold transparency, accuracy, and accountability in every aspect of our platform.\n"
                                  "• Collaboration: We promote teamwork and communication among patients, nurses, and doctors to ensure holistic care.\n"
                                  "• Accessibility: We strive to make health monitoring simple, inclusive, and affordable for all.",
                            ),
                            _buildExpansionTile(
                              icon: Icons.verified_rounded,
                              title: "Quality Policy",
                              content:
                                  "At Edentify, we are dedicated to building reliable, secure, and user-friendly healthcare solutions. "
                                  "We continuously improve our platform through feedback, research, and innovation — ensuring that our technology meets the highest standards of safety, accuracy, and patient satisfaction.",
                            ),
                            _buildExpansionTile(
                              icon: Icons.privacy_tip_rounded,
                              title: "Privacy Statement",
                              content:
                                  "Your trust is our top priority. All personal and medical data — including health scans, vital signs, and user details — "
                                  "are securely stored and processed through Firestore’s encrypted infrastructure. We strictly adhere to data protection standards and handle all information with confidentiality and care.",
                            ),
                            _buildExpansionTile(
                              icon: Icons.cookie_rounded,
                              title: "Cookie Policy",
                              content:
                                  "To enhance your browsing experience, Edentify may use cookies to personalize content, analyze performance, and improve usability. "
                                  "You may adjust your cookie preferences through your browser settings at any time. We ensure transparency in how we collect and use non-sensitive data to enhance user experience.",
                            ),

                            const SizedBox(height: 30),

                            // 🔹 Optional center description (from Firestore)
                            if (data['description'] != null &&
                                (data['description'] as String).isNotEmpty)
                              _buildExpansionTile(
                                icon: Icons.info_outline_rounded,
                                title: "About This Center",
                                content: data['description'],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Improved Helper widget for clean and aligned ExpansionTiles
  Widget _buildExpansionTile({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFF045347)),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF045347),
            ),
          ),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8, // ✅ comfortable line spacing
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
