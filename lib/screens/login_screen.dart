import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final String centerName;
  const LoginScreen({super.key, required this.centerName});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String validEmail = 'd@gmail.com';
  final String validPassword = 'd123';

  String errorText = '';

  void _handleLogin() {
    if (_emailController.text == validEmail && _passwordController.text == validPassword) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: widget.centerName,
      );
    } else {
      setState(() {
        errorText = 'Invalid email or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Logging into:  ${widget.centerName}",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        filled: true,
                        fillColor: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    if (errorText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorText,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
