import 'package:plannus/screens/main_page.dart'; 
import 'package:plannus/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.session != null) {
          // User is logged in, then show main screen.
          return const MainScreen(); 
        } else {
          // User is not logged in, show login screen.
          return const LoginScreen();
        }
      },
    );
  }
}