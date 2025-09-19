import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/landing_page.dart';
import 'screens/center_selection.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/doctors_screen.dart';
import 'screens/about_center.dart';

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
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color.fromARGB(255, 0, 121, 107),
          secondary: Colors.amber.shade600,
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
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null ||
                args['centerId'] == null ||
                args['centerName'] == null) {
              return _missingDataScreen('login');
            }
            return MaterialPageRoute(
              builder: (_) => CenterLoginScreen(
                centerId: args['centerId'],
                centerName: args['centerName'],
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null ||
                args['centerId'] == null ||
                args['centerName'] == null) {
              return _missingDataScreen('home');
            }
            return MaterialPageRoute(
              builder: (_) => HomeScreen(
                centerId: args['centerId'],
                centerName: args['centerName'],
              ),
            );

          case '/patients':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null ||
                args['centerId'] == null ||
                args['centerName'] == null) {
              return _missingDataScreen('patients');
            }
            return MaterialPageRoute(
              builder: (_) => PatientListScreen(
                centerId: args['centerId'],
                centerName: args['centerName'],
              ),
            );

          case '/doctors':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null ||
                args['centerId'] == null ||
                args['centerName'] == null) {
              return _missingDataScreen('doctors');
            }
            return MaterialPageRoute(
              builder: (_) => DoctorsScreen(
                centerId: args['centerId'],
                centerName: args['centerName'],
              ),
            );

          case '/aboutCenter':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null ||
                args['centerId'] == null ||
                args['centerName'] == null) {
              return _missingDataScreen('about center');
            }
            return MaterialPageRoute(
              builder: (_) => AboutScreen(
                centerId: args['centerId'],
                centerName: args['centerName'],
              ),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Route not found')),
              ),
            );
        }
      },
    );
  }

  /// Small helper so we don’t repeat the same error code everywhere
  MaterialPageRoute _missingDataScreen(String screenName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text('Missing center data for $screenName')),
      ),
    );
  }
}
