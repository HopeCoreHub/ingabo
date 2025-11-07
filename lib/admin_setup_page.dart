import 'package:flutter/material.dart';
import 'admin_setup.dart';
import 'admin_page.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  _AdminSetupPageState createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  bool _isLoading = true;
  String _status = 'Initializing admin setup...';
  bool _isSuccess = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _runAdminSetup();
  }
  
  Future<void> _runAdminSetup() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Checking Firebase connection...';
      });

      // First check Firebase connection
      try {
        final testRef = FirebaseDatabase.instance.ref('_test_connection');
        await testRef.set({'timestamp': ServerValue.timestamp});
        await testRef.remove();
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = 'Firebase connection error: $e';
          _status = 'Setup failed!';
        });
        return;
      }

      setState(() {
        _status = 'Setting up admin user...';
      });

      // Run the admin setup
      // Note: setupAdmin doesn't actually use context, but we check mounted for safety
      if (!mounted) return;
      final result = await AdminSetup.setupAdmin(context);
      
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _status = 'Admin setup completed successfully!';
        });
      } else {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = result['error'];
          _status = 'Setup failed!';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _errorMessage = 'Unexpected error: $e';
        _status = 'Setup failed!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
        backgroundColor: const Color(0xFF9667FF),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9667FF)),
                ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please wait while we set up the admin account...',
                  textAlign: TextAlign.center,
                ),
              ] else if (_isSuccess) ...[
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 72,
                ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'The admin account has been configured successfully.\n'
                  'You can now manage subscriptions and approve payments.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9667FF),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminPage()),
                    );
                  },
                  child: const Text('Go to Admin Dashboard'),
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 72,
                ),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9667FF),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: _runAdminSetup,
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 