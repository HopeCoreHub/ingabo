import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';

class FirebaseImportPage extends StatefulWidget {
  const FirebaseImportPage({super.key});

  @override
  State<FirebaseImportPage> createState() => _FirebaseImportPageState();
}

class _FirebaseImportPageState extends State<FirebaseImportPage> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _success = false;
  
  // Firebase instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _importToFirebase() async {
    if (_jsonController.text.isEmpty) {
      _showError('Please enter JSON data');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Importing data to Firebase...';
      _success = false;
    });

    try {
      // Parse JSON data
      final jsonData = json.decode(_jsonController.text);
      
      // Import to Firebase
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.saveCompleteUserDataStructure(jsonData);
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Data imported successfully!';
        _success = true;
      });
    } catch (e) {
      _showError('Error importing data: ${e.toString()}');
    }
  }
  
  Future<void> _createMugangaSubscription() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating Muganga subscription...';
      _success = false;
    });

    try {
      // Get current user
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isLoggedIn || authService.userId == null) {
        _showError('You must be logged in to create a subscription');
        return;
      }
      
      final userId = authService.userId!;
      
      // Create sample subscription data
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 30));
      
      final subscriptionData = {
        'isSubscribed': true,
        'subscriptionDate': now.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'paymentMethod': 'MTN Mobile Money',
        'paymentReference': 'MTN${DateTime.now().millisecondsSinceEpoch}',
        'amount': 2000,
        'currency': 'RWF',
        'autoRenew': true,
        'therapySessions': [
          {
            'id': 'session${DateTime.now().millisecondsSinceEpoch}',
            'therapistId': 'therapist001',
            'therapistName': 'Dr. Alice Mutoni',
            'scheduledDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            'duration': 60,
            'status': 'scheduled',
            'notes': 'Initial consultation session'
          }
        ]
      };
      
      // Save to Firebase
      await _db.collection('users')
          .doc(userId)
          .collection('muganga_subscriptions')
          .doc('current')
          .set(subscriptionData);
      
      setState(() {
        _isLoading = false;
        _statusMessage = 'Muganga subscription created successfully!';
        _success = true;
      });
    } catch (e) {
      _showError('Error creating subscription: ${e.toString()}');
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _statusMessage = message;
      _success = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Import Data to Firebase',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Paste your JSON data structure below to import it into Firebase:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Paste JSON here...',
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _importToFirebase,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Import to Firebase'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Create Muganga Subscription',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create a sample subscription for the currently logged in user:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createMugangaSubscription,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Muganga Subscription'),
            ),
            const SizedBox(height: 16),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _success ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _success ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 