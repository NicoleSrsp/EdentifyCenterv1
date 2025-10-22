import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service class to handle authentication-related actions like logging out.
/// Keeping this logic separate from the UI makes the code cleaner and reusable.
class AuthService {
  // We make the method static so we don't have to create an instance of AuthService to use it.
  // We can just call it directly: AuthService.logout(context);
  static Future<void> logout(BuildContext context) async {
    // Show a confirmation dialog before proceeding with logout.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // User chose not to log out
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // User confirmed logout
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF056C5B), // Use your app's primary color
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    // Only proceed if the user confirmed the action.
    if (confirm == true) {
      // 1. Sign out from Firebase Authentication.
      await FirebaseAuth.instance.signOut();

      // 2. Clear any local data (e.g., SharedPreferences).
      // This is crucial to ensure no old session data remains.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. After an async gap, check if the widget is still on screen.
      // This is a best practice to avoid errors.
      if (!context.mounted) return;

      // 4. Navigate to the initial route (likely your login screen) and
      // remove all previous screens from the navigation history.
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/', // Navigate to the root route
        (route) => false, // This predicate ensures all routes are removed
      );
    }
  }
}
