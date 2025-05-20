import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/landing_page.dart';
import 'screens/center_selection.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/schedules_screen.dart';
import 'screens/patient_folders_screen.dart';
import 'screens/entry_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EdentifyApp());
}

class EdentifyApp extends StatelessWidget {
  const EdentifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edentify Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: '',
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color.fromARGB(255, 0, 121, 107),
          secondary: Colors.amber.shade600,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          bodyLarge: TextStyle(color: Colors.black),
          labelLarge: TextStyle(color: Colors.black),
          titleLarge: TextStyle(color: Colors.black),
        ),
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingPage());

          case '/centerSelection':
            return MaterialPageRoute(builder: (_) => const CenterSelectionScreen());

          case '/login':
            final centerName = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => LoginScreen(centerName: centerName),
            );

          case '/home':
            final centerName = settings.arguments as String?;
            if (centerName == null) {
              return MaterialPageRoute(builder: (_) => const LandingPage());
            }
            return MaterialPageRoute(builder: (_) => HomeScreen(centerName: centerName));

          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());

          case '/pending-approval':
            return MaterialPageRoute(builder: (_) => const PendingApprovalScreen());

          case '/schedules':
            return MaterialPageRoute(builder: (_) => const SchedulesScreen());

          case '/folders':
            final patientId = settings.arguments as String?;
            if (patientId == null || patientId.isEmpty) {
              return MaterialPageRoute(builder: (_) => const HomeScreen(centerName: ''));
            }
            return MaterialPageRoute(
              builder: (_) => PatientFoldersScreen(patientId: patientId),
            );

          case '/entryDetail':
            final args = settings.arguments;
            if (args == null || args is! Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Invalid data passed to EntryDetailScreen')),
                ),
              );
            }
            final folder = args['folder'] as Map<String, dynamic>?;
            final docId = args['docId'] as String?;
            if (folder == null || docId == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Missing folder or docId')),
                ),
              );
          }
          return MaterialPageRoute(
            builder: (_) => EntryDetailScreen(folder: folder, docId: docId),
          );

          default:
            return null;
        }
      },
    );
  }
}
