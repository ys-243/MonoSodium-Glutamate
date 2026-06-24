import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plannus/screens/login_screen.dart';
import 'package:plannus/screens/main_screen.dart';
import 'package:plannus/screens/profile_setup_screen.dart';

class AuthService extends StatelessWidget {
  const AuthService({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, authSnapshot) {
        
        final session = authSnapshot.data?.session;

        // If there is no active session, show the Login/Register flow
        if (session == null) {
          return const LoginScreen();
        }

        // 2. If there IS a session, check if their profile exists in the database
        return FutureBuilder(
          // .maybeSingle() returns null instead of an error if the row doesn't exist
          future: Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', session.user.id)
              .maybeSingle(), 
          builder: (context, profileSnapshot) {
            
            // Shows a loading spinner while checking the database
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If no profile row is found, divert them the Setup Screen to setup profile.
            if (profileSnapshot.data == null) {
              return const ProfileSetupScreen();
            }

            // If a profile is found, go to the Main Screen
            return const MainScreen();
          },
        );
      },
    );
  }
}