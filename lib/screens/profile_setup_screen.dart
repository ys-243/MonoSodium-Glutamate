import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plannus/screens/login_screen.dart';
import 'package:plannus/screens/main_screen.dart'; 

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _majorController = TextEditingController();

  final List<String> _schoolOptions = const [
    "NUS",
    "NTU",
    "SMU",
    "SUTD",
    "SUSS",
    "SIT",
    "SIM",
  ];

  final List<String> _yearOptions = const [
    "Year 1",
    "Year 2",
    "Year 3",
    "Year 4",
    "Year 5",
    "Year 6+",
  ];

  String? _selectedSchool = 'NUS';
  String? _selectedYear = 'Year 1';

  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      
      // Insert the profile data into our 'profiles' table in Supabase.
      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'user_name': _displayNameController.text.trim().isEmpty 
            ? _firstNameController.text.trim() 
            : _displayNameController.text.trim(),
        'school': _selectedSchool,
        'major': _majorController.text.trim().isEmpty ? 'Undeclared' : _majorController.text.trim(),
        'year_of_study': _selectedYear,
      });

      if (!mounted) return;
      // Profile is saved! Now we can safely send them to the main app.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    // Shpow errors if any.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome to PlanNUS! Let us get to know you.'),
            
            // First name box
            const SizedBox(height: 20),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),

            // Last name box
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),

            // Display name box
            const SizedBox(height: 12),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'What do you want others to call you?',
              ),
            ),

            // School dropdown
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSchool,
              decoration: const InputDecoration(
                labelText: 'School',
                border: OutlineInputBorder(),
              ),
              items: _schoolOptions
                  .map(
                    (school) => DropdownMenuItem<String>(
                      value: school,
                      child: Text(school),
                    ),
                  )
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _selectedSchool = value);
                    },
            ),

            // Major box
            const SizedBox(height: 12),
            TextField(
              controller: _majorController,
              decoration: const InputDecoration(labelText: 'Major'),
            ),

            // Year of study dropdown
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year of Study',
                border: OutlineInputBorder(),
              ),
              items: _yearOptions
                  .map(
                    (year) => DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    ),
                  )
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() => _selectedYear = value);
                    },
            ),

            // Save button
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}