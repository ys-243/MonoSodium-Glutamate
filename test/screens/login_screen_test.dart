import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plannus/screens/login_screen.dart'; 

// Mock classes for SupabaseClient and GoTrueClient to simulate authentication behavior.
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockAuth extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockAuth mockAuthClient;

  // Set up the mock Supabase client and its auth client before each test.
  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockAuth();
    
    // Link the fake auth client to the fake supabase client
    when(() => mockSupabaseClient.auth).thenReturn(mockAuthClient);
  });

  // Inject the fake client into the LoginScreen for testing purposes.
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: LoginScreen(supabaseClient: mockSupabaseClient), 
    );
  }

  group('LoginScreen UI Tests', () {
    testWidgets('Renders all necessary UI elements', (WidgetTester tester) async {
      
      // 1. Build the UI
      await tester.pumpWidget(createWidgetUnderTest());

      // 2. Verify two TextFormFields exists (Email and Password)
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // 3. Verify that we find the "Sign In" button 
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Shows validation errors when submitting an empty form', (WidgetTester tester) async {
      
      // 1. Build the UI
      await tester.pumpWidget(createWidgetUnderTest());

      final signInButton = find.byType(FilledButton);

      // 2. Tap the button with entering any text
      await tester.tap(signInButton);
      
      // 3. Rebuild the UI to reflect new state (should show validation errors)
      await tester.pump();

      // 4. Verify the exact validation messages appear
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Shows specific validation errors for bad email and short password', (WidgetTester tester) async {
      // 1. Build the UI
      await tester.pumpWidget(createWidgetUnderTest());

      // 2. Find the text fields
      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);

      // 3. Enter an invalid email (no '@') and a short password (under 6 chars)
      await tester.enterText(emailField, 'whatisthisfunnyemail.com');
      await tester.enterText(passwordField, '12345');

      // 4. Tap the Sign In button and rebuild UI
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // 5. Verify that the expected validation messages are displayed for both fields.
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });

  testWidgets('Shows server error Snackbar on failed login', (WidgetTester tester) async {
      // 1. Tell Mocktail what to do when the app tries to log in
      when(() => mockAuthClient.signInWithPassword(
        email: 'wrongwrong@u.nus.edu',
        password: 'wrongpassword',
      )).thenThrow(Exception('Invalid login credentials')); // Fake a server rejection

      await tester.pumpWidget(createWidgetUnderTest());

      // 2. Find the fields and enter the exact data Mocktail is waiting for
      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);

      await tester.enterText(emailField, 'wrongwrong@u.nus.edu');
      await tester.enterText(passwordField, 'wrongpassword');

      // 3. Tap the Sign In button to trigger the database call
      await tester.tap(find.byType(FilledButton));
      
      // 4. Rebuild the UI
      await tester.pump(); 

      // 5. Verify your catch(e) block works and the Snackbar with the error message is displayed.
      expect(find.text('Error: Exception: Invalid login credentials'), findsOneWidget); 
  });
}