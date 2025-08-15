import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'services/auth_service.dart';
import 'localization/base_screen.dart';

class AdminPage extends BaseStatelessScreen {
  const AdminPage({super.key});

  @override
  Widget buildScreen(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? const Color(0xFF9667FF) : const Color(0xFFE53935);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF111827) : Colors.white,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : accentColor,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Pending Subscriptions'),
              Tab(text: 'All Subscriptions'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Force refresh the subscription lists
                _SubscriptionListState.pendingSubscriptionsKey.currentState?.refresh();
                _SubscriptionListState.allSubscriptionsKey.currentState?.refresh();
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            // Pending subscriptions
            SubscriptionList(statusFilter: 'pending'),
            // All subscriptions
            SubscriptionList(statusFilter: null),
          ],
        ),
      ),
    );
  }
}

class SubscriptionList extends StatefulWidget {
  final String? statusFilter;
  
  const SubscriptionList({super.key, this.statusFilter});

  @override
  _SubscriptionListState createState() => _SubscriptionListState();
}

class _SubscriptionListState extends State<SubscriptionList> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;
  String? _error;
  
  // Global keys for refreshing the lists from parent widget
  static final GlobalKey<_SubscriptionListState> pendingSubscriptionsKey = GlobalKey<_SubscriptionListState>();
  static final GlobalKey<_SubscriptionListState> allSubscriptionsKey = GlobalKey<_SubscriptionListState>();
  
  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }
  
  // Method to refresh subscriptions data
  void refresh() {
    if (mounted) {
      _loadSubscriptions();
    }
  }

  Future<void> _loadSubscriptions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Reference to the muganga_subscriptions collection
      final DatabaseReference subscriptionsRef = _database.child('muganga_subscriptions');
      
      // If filtering by status, use the pending subfolder
      Query query;
      if (widget.statusFilter == 'pending') {
        query = subscriptionsRef.child('pending');
      } else {
        // For all subscriptions, we need to merge data from multiple locations
        // This is a simplification - in a real app, you might want a better data structure
        query = subscriptionsRef.child('all');
      }
      
      final snapshot = await query.get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> subscriptions = [];
        
        // Convert the database data to a list of subscription objects
        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final subscription = _convertToSubscription(key.toString(), value);
            subscriptions.add(subscription);
          }
        });
        
        // Sort by creation date (newest first)
        subscriptions.sort((a, b) {
          final DateTime dateA = DateTime.fromMillisecondsSinceEpoch(a['createdAt'] as int);
          final DateTime dateB = DateTime.fromMillisecondsSinceEpoch(b['createdAt'] as int);
          return dateB.compareTo(dateA);
        });
        
        if (mounted) {
          setState(() {
            _subscriptions = subscriptions;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _subscriptions = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load subscriptions: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Map<String, dynamic> _convertToSubscription(String id, Map<dynamic, dynamic> data) {
    return {
      'id': id,
      'userId': data['userId'] as String? ?? '',
      'username': data['username'] as String? ?? 'Unknown User',
      'transactionId': data['transactionId'] as String? ?? '',
      'amount': data['amount'] as int? ?? 0,
      'currency': data['currency'] as String? ?? 'RWF',
      'status': data['status'] as String? ?? 'pending',
      'paymentMethod': data['paymentMethod'] as String? ?? 'Unknown',
      'createdAt': data['createdAt'] as int? ?? 0,
      'expiresAt': data['expiresAt'] as int?,
      'verificationStatus': data['verificationStatus'] as String? ?? 'submitted',
    };
  }

  Future<void> _updateSubscriptionStatus(Map<String, dynamic> subscription, String newStatus) async {
    try {
      final userId = subscription['userId'];
      final subscriptionId = subscription['id'];
      
      // Update in both locations
      // 1. In the pending subscriptions list (if it's there)
      await _database
          .child('muganga_subscriptions')
          .child('pending')
          .child(subscriptionId)
          .update({
        'status': newStatus,
        'verificationStatus': newStatus == 'approved' ? 'verified' : 'rejected',
      });
      
      // 2. In the user's subscriptions
      await _database
          .child('users')
          .child(userId)
          .child('muganga_subscriptions')
          .child('current')
          .update({
        'status': newStatus,
        'verificationStatus': newStatus == 'approved' ? 'verified' : 'rejected',
      });
      
      // 3. If approved, add an expiry date (30 days from now)
      if (newStatus == 'approved') {
        final expiresAt = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
        
        await _database
            .child('users')
            .child(userId)
            .child('muganga_subscriptions')
            .child('current')
            .update({
          'expiresAt': expiresAt,
        });
        
        // Also add to the all subscriptions collection for record keeping
        await _database
            .child('muganga_subscriptions')
            .child('all')
            .child(subscriptionId)
            .set({
          ...subscription,
          'status': newStatus,
          'verificationStatus': 'verified',
          'expiresAt': expiresAt,
        });
        
        // If approved, remove from pending
        await _database
            .child('muganga_subscriptions')
            .child('pending')
            .child(subscriptionId)
            .remove();
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the list
      _loadSubscriptions();
      
    } catch (e) {
      debugPrint('Error updating subscription status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubscriptions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_subscriptions.isEmpty) {
      return Center(
        child: Text(
          widget.statusFilter == 'pending'
              ? 'No pending subscriptions'
              : 'No subscriptions found',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      itemBuilder: (context, index) {
        final subscription = _subscriptions[index];
        
        // Format creation date
        final createdAt = DateTime.fromMillisecondsSinceEpoch(
          subscription['createdAt'] as int
        );
        final createdAtFormatted = '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}';
        
        // Determine card color based on status
        Color cardColor;
        if (isDarkMode) {
          // Dark mode colors
          if (subscription['status'] == 'approved') {
            cardColor = Colors.green.withOpacity(0.1);
          } else if (subscription['status'] == 'rejected') {
            cardColor = Colors.red.withOpacity(0.1);
          } else {
            cardColor = Colors.orange.withOpacity(0.1);
          }
        } else {
          // Light mode colors
          if (subscription['status'] == 'approved') {
            cardColor = Colors.green.withOpacity(0.05);
          } else if (subscription['status'] == 'rejected') {
            cardColor = Colors.red.withOpacity(0.05);
          } else {
            cardColor = Colors.orange.withOpacity(0.05);
          }
        }
        
        return Card(
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getStatusColor(subscription['status']).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(subscription['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getStatusColor(subscription['status']).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    subscription['status'].toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(subscription['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isDarkMode 
                          ? const Color(0xFF1E293B) 
                          : const Color(0xFFF1F5F9),
                      radius: 20,
                      child: Text(
                        subscription['username'].isNotEmpty 
                            ? subscription['username'][0].toUpperCase() 
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription['username'] ?? 'Unknown User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'User ID: ${subscription['userId']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Payment info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Transaction ID',
                        subscription['transactionId'],
                        isDarkMode,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Amount',
                        '${subscription['amount']} ${subscription['currency']}',
                        isDarkMode,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Payment Method',
                        subscription['paymentMethod'],
                        isDarkMode,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Created At',
                        createdAtFormatted,
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                if (subscription['status'] == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateSubscriptionStatus(subscription, 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateSubscriptionStatus(subscription, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  )
                else if (subscription['status'] == 'rejected')
                  ElevatedButton.icon(
                    onPressed: () => _updateSubscriptionStatus(subscription, 'pending'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Move Back to Pending'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      // Add code to extend subscription
                      _showExtendSubscriptionDialog(context, subscription);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.update),
                    label: const Text('Extend Subscription'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
  
  void _showExtendSubscriptionDialog(BuildContext context, Map<String, dynamic> subscription) {
    int extensionDays = 30; // Default 30 days
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Extend Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Extend the subscription duration by:'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: extensionDays.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Days',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        extensionDays = int.tryParse(value) ?? 30;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _extendSubscription(subscription, extensionDays);
              },
              child: const Text('Extend'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _extendSubscription(Map<String, dynamic> subscription, int days) async {
    try {
      final userId = subscription['userId'];
      final subscriptionId = subscription['id'];
      
      // Calculate new expiry date
      int? currentExpiryTimestamp = subscription['expiresAt'] as int?;
      DateTime baseDate;
      
      if (currentExpiryTimestamp != null) {
        // Extend from current expiry date
        baseDate = DateTime.fromMillisecondsSinceEpoch(currentExpiryTimestamp);
      } else {
        // No expiry date, start from now
        baseDate = DateTime.now();
      }
      
      // Calculate new expiry date
      final newExpiryDate = baseDate.add(Duration(days: days));
      final newExpiryTimestamp = newExpiryDate.millisecondsSinceEpoch;
      
      // Update in user's subscriptions
      await _database
          .child('users')
          .child(userId)
          .child('muganga_subscriptions')
          .child('current')
          .update({
        'expiresAt': newExpiryTimestamp,
        'lastExtended': ServerValue.timestamp,
        'extensionDays': days,
      });
      
      // Update in all subscriptions
      await _database
          .child('muganga_subscriptions')
          .child('all')
          .child(subscriptionId)
          .update({
        'expiresAt': newExpiryTimestamp,
        'lastExtended': ServerValue.timestamp,
        'extensionDays': days,
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription extended by $days days'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the list
      _loadSubscriptions();
      
    } catch (e) {
      debugPrint('Error extending subscription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to extend subscription: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 