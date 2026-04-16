import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nec_app/features/home/screens/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isStudent = false;
  String? _selectedGroup;
  bool _isLoading = false;

  String _getRoleFromEmail(String email) {
    if (email.startsWith('hod')) return 'hod';
    if (RegExp(r'\d').hasMatch(email)) return 'student';
    if (email.endsWith('@nec.edu.np')) return 'teacher';
    return 'unknown';
  }

  int? _getBatchFromEmail(String email) {
    final regExp = RegExp(r'0(\d{2})@');
    final match = regExp.firstMatch(email);
    if (match != null) {
      return 2000 + int.parse(match.group(1)!);
    }
    return null;
  }

  Future<void> _signUp() async {
    // This is the same logic function as before, no changes needed here.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final role = _getRoleFromEmail(email);

    if (role == 'unknown' || !email.endsWith('@nec.edu.np')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid college email format.')),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (role == 'student' && _selectedGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a group.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user != null) {
        final Map<String, dynamic> userData = {
          'name': name,
          'email': email,
          'role': role,
        };
        if (role == 'student') {
          userData['batch'] = _getBatchFromEmail(email) ?? 0;
          userData['group'] = _selectedGroup ?? 'N/A';
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.indigo[800],
      ),
      // Apply the same gradient background as the login screen
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Consistent header style
                  Text(
                    'Join the NEC Community',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[800],
                    ),
                  ),
                  Text(
                    'Create your account to get started',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Form fields inside a Card
                  Card(
                    elevation: 4,
                    shadowColor: Colors.indigo.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Please enter your name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'College Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (value) {
                              setState(() {
                                _isStudent =
                                    _getRoleFromEmail(value) == 'student';
                              });
                            },
                            validator: (value) =>
                                (value!.isEmpty ||
                                    !value.endsWith('@nec.edu.np'))
                                ? 'Please enter a valid NEC email'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (value) => (value!.length < 6)
                                ? 'Password must be at least 6 characters'
                                : null,
                          ),
                          // Animated visibility for the group selector
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _isStudent
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedGroup,
                                      hint: const Text('Select Your Group'),
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.group_outlined),
                                      ),
                                      items: ['A', 'B', 'C', 'D']
                                          .map(
                                            (g) => DropdownMenuItem<String>(
                                              value: g,
                                              child: Text('Group $g'),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedGroup = val),
                                      validator: (val) => val == null
                                          ? 'Please select a group'
                                          : null,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('SIGN UP'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
