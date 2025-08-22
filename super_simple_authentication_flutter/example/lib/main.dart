import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

final auth = SuperSimpleAuthentication(
  host: 'localhost',
  port: 8080,
  secureScheme: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize to load stored tokens
  await auth.initialize();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late final StreamSubscription<TokenData?> _accessTokenSubscription;
  bool _isSignedIn = false;
  bool _createUser = false;

  @override
  void initState() {
    super.initState();
    _isSignedIn = auth.isSignedIn;
    _accessTokenSubscription = auth.tokenDataStream.listen((token) {
      setState(() {
        _isSignedIn = auth.isSignedIn;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignedIn
                    ? 'Signed In as ${auth.tokenData?.userId}'
                    : 'Signed Out',
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: _createUser,
                    onChanged: (value) {
                      setState(() {
                        _createUser = value;
                      });
                    },
                  ),
                  Text('Create User'),
                ],
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_createUser) {
                        auth.createAccountWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                      } else {
                        auth.signInWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                      }
                    },
                    child: Text('Sign In'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      auth.signOut();
                    },
                    child: Text('Sign Out'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _accessTokenSubscription.cancel();
    super.dispose();
  }
}
