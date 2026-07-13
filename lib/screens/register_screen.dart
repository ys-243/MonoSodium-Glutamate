import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_setup_screen.dart';
import 'package:plannus/theme_controller.dart';

class RegisterScreen extends StatefulWidget {
	const RegisterScreen({
    super.key,
    required this.themeController,
  });
  final ThemeController themeController;

	@override
	State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
	final _formKey = GlobalKey<FormState>();
	final TextEditingController _emailController = TextEditingController();
	final TextEditingController _passwordController = TextEditingController();
	final TextEditingController _confirmController = TextEditingController();
	bool _loading = false;
	bool _obscurePassword = true;
	bool _obscureConfirm = true;

	@override
	void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
		super.dispose();
	}

	Future<void> _register() async {
		if (!_formKey.currentState!.validate()) return;
		setState(() => _loading = true);

		try {
			await Supabase.instance.client.auth.signUp(
				email: _emailController.text.trim(),
				password: _passwordController.text,
			);

			// If signUp returns no error, show success message and pop.
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Account created successfully.')),
			);
			Navigator.of(context).pushReplacement(
				MaterialPageRoute(
					builder: (_) => ProfileSetupScreen(themeController: widget.themeController),
				),
			);
		} on AuthException catch (e) {
      // Show the error message from Supabase.
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(e.message)),
			);
		} catch (e) {
      // Show the other forms of error message.
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(e.toString())),
			);
		} finally {
			if (mounted) setState(() => _loading = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Register'),
				centerTitle: true,
			),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.all(16.0),
					child: Center(
						child: ConstrainedBox(
							constraints: const BoxConstraints(maxWidth: 480),
							child: Form(
								key: _formKey,
								child: Column(
									mainAxisSize: MainAxisSize.min,
									children: [
										const SizedBox(height: 12),
										TextFormField(
											controller: _emailController,
											keyboardType: TextInputType.emailAddress,
											decoration: const InputDecoration(
												labelText: 'Email',
											),
											validator: (value) {
												if (value == null || value.trim().isEmpty) {
													return 'Email cannot be empty';
												}
												return null;
											},
										),
										const SizedBox(height: 12),
										TextFormField(
											controller: _passwordController,
											obscureText: _obscurePassword,
											decoration: InputDecoration(
												labelText: 'Password',
												suffixIcon: IconButton(
													icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
													onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
												),
											),
											validator: (value) {
												if (value == null || value.isEmpty) {
													return 'Password cannot be empty';
												}
                        // Enforce a minimum password length for better security.
												if (value.length < 6) {
													return 'Password should be at least 6 characters';
												}
												return null;
											},
										),
										const SizedBox(height: 12),
										TextFormField(
											controller: _confirmController,
											obscureText: _obscureConfirm,
											decoration: InputDecoration(
												labelText: 'Confirm Password',
												suffixIcon: IconButton(
													icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
													onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
												),
											),
											validator: (value) {
												if (value == null || value.isEmpty) {
													return 'Please confirm your password';
												}
												if (value != _passwordController.text) {
													return 'Passwords do not match';
												}
												return null;
											},
										),
										const SizedBox(height: 20),
										SizedBox(
											width: double.infinity,
											child: ElevatedButton(
												onPressed: _loading ? null : _register,
												child: _loading
														? const SizedBox(
																height: 20,
																width: 20,
																child: CircularProgressIndicator(strokeWidth: 2),
															)
														: const Text('Create account'),
											),
										),
									],
								),
							),
						),
					),
				),
			),
		);
	}
}
