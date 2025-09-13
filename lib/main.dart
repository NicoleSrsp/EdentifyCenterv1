import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/landing_page.dart';
import 'screens/center_selection.dart';
import 'screens/login_screen.dart';
import 'change_password.dart';
import 'screens/home_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/mark_active.dart';

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
                args['centerName'] == null ||
                args['centerId'] == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Missing center data')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => CenterLoginScreen(
                centerName: args['centerName'],
                centerId: args['centerId'],
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null ||
                args['centerName'] == null ||
                args['centerId'] == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Missing center data')),
                ),
              );
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
                args['centerName'] == null ||
                args['centerId'] == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Missing center data')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => PatientListScreen(
                centerId: args['centerId'],
                centerName: args['centerName'],
              ),
            );

          case '/settings':
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Settings Screen')),
              ),
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
