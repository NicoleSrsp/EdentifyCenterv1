import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/landing_page.dart';
import 'screens/center_selection.dart';
import 'screens/login_screen.dart';
import 'change_password.dart';
import 'screens/home_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/schedules_screen.dart';
import 'screens/patient_folders_screen.dart';
import 'screens/patient_history_screen.dart';
import 'screens/archive_patient_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
            return MaterialPageRoute(
              builder: (_) => const CenterSelectionScreen(),
            );

          case '/login':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DoctorLoginScreen(
                centerName: args['centerName'],
                doctorName: args['doctorName'],
              ),
            );

          case '/changePassword':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ChangePasswordScreen(
                doctorId: args['doctorId'],
                centerName: args['centerName'],
              ),
            );

          case '/home':
             final args = settings.arguments as Map<String, dynamic>?;
              if (args == null || args['centerName'] == null || args['doctorId'] == null) {
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('Missing center or doctor name')),
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (_) => HomeScreen(
                  centerName: args['centerName'],
                  doctorId: args['doctorId'],
                ),
              );

          case '/notifications':
            return MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            );

          case '/pending-approval':
            return MaterialPageRoute(
              builder: (_) => const PendingApprovalScreen(),
            );

          case '/schedules':
            return MaterialPageRoute(builder: (_) => const SchedulesScreen());

          case '/folders':
            final patientId = settings.arguments as String?;
            if (patientId == null || patientId.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => const HomeScreen(centerName: '', doctorId: ''),
              );
            }
            return MaterialPageRoute(
              builder: (_) => PatientFoldersScreen(patientId: patientId),
            );

          case '/patientHistory':
          final args = settings.arguments;
          if (args == null || args is! Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text('Invalid data passed to PatientHistoryScreen'),
                ),
              ),
            );
          }

          final folder = args['folder'] as Map<String, dynamic>?;
          final docId = args['docId'] as String?;
          final collectionName = args['collectionName'] as String? ?? 'users';
          final readonly = args['readonly'] as bool? ?? false;
          final selectedDate = args['selectedDate'] as DateTime?;

          if (folder == null || docId == null || selectedDate == null) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Missing folder, docId or selectedDate')),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (_) => PatientHistoryScreen(
              folder: folder,
              docId: docId,
              collectionName: collectionName,
              selectedDate: selectedDate,
              readonly: readonly,
            ),
          );
          
          case '/archivedPatients':
            final centerName = settings.arguments as String?;
            if (centerName == null || centerName.isEmpty) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('No center specified')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => ArchivedPatientsScreen(centerName: centerName),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
        }
      },
    );
  }
}