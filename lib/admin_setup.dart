import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminSetup {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  /// Creates or verifies admin user and sets admin privileges
  static Future<Map<String, dynamic>> setupAdmin(
    BuildContext context, {
    String adminEmail = 'mjehovanis2@gmail.com',
    String adminPassword = 'MJehovanis@2',
  }) async {
    try {
      // First check if admin user already exists
      User? currentUser = _auth.currentUser;
      String? adminUid;
      
      // If someone else is logged in, we need to sign them out first
      if (currentUser != null && currentUser.email != adminEmail) {
        await _auth.signOut();
        currentUser = null;
      }
      
      if (currentUser == null) {
        try {
          // Try to sign in with admin credentials
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          adminUid = userCredential.user?.uid;
          debugPrint('Admin user signed in: $adminUid');
        } catch (signInError) {
          debugPrint('Admin sign-in failed: $signInError');
          
          // If sign-in fails, try to create the admin account
          try {
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            adminUid = userCredential.user?.uid;
            
            // Update profile with a name
            await userCredential.user?.updateDisplayName('Admin');
            debugPrint('Admin user created: $adminUid');
          } catch (createError) {
            return {
              'success': false,
              'error': 'Failed to create admin user: $createError',
            };
          }
        }
      } else {
        adminUid = currentUser.uid;
        debugPrint('Admin user already signed in: $adminUid');
      }
      
      // Now set admin privileges in the database
      if (adminUid != null) {
        await _database.child('admins').child(adminUid).set(true);
        
        // Also add admin flag to the user record
        await _database.child('users').child(adminUid).update({
          'isAdmin': true,
          'role': 'admin',
          'permissions': {
            'manageSubscriptions': true,
            'viewAllUsers': true,
            'approvePayments': true,
          }
        });
        
        return {
          'success': true,
          'message': 'Admin user set up successfully with ID: $adminUid',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get admin user ID',
        };
      }
    } catch (e) {
      debugPrint('Error setting up admin user: $e');
      return {
        'success': false,
        'error': 'Error setting up admin user: $e',
      };
    }
  }
  
  /// Check if the current user is an admin
  static Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final snapshot = await _database.child('admins').child(user.uid).get();
      return snapshot.exists && snapshot.value == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
} 