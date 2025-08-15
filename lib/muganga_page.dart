import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme_provider.dart';
import 'accessibility_provider.dart';

import 'localization/localized_text.dart';
import 'localization/base_screen.dart';
import 'services/auth_service.dart';
import 'utils/accessibility_utils.dart';

class MugangaPage extends BaseScreen {
  const MugangaPage({super.key});

  @override
  State<MugangaPage> createState() => _MugangaPageState();
}

class _MugangaPageState extends BaseScreenState<MugangaPage> {
  Map<String, dynamic>? _subscriptionData;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _subscriptionListener;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  @override
  void dispose() {
    _subscriptionListener?.cancel();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!authService.isLoggedIn || authService.userId == null) {
        setState(() {
          _subscriptionData = null;
          _isLoading = false;
        });
        return;
      }

      final userId = authService.userId!;
      final databaseRef = FirebaseDatabase.instance.ref();
      
      // Set up real-time listener for subscription data
      _subscriptionListener = databaseRef
          .child('users')
          .child(userId)
          .child('muganga_subscriptions')
          .child('current')
          .onValue
          .listen((event) {
        if (!mounted) return;
        
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _subscriptionData = Map<String, dynamic>.from(data);
            _isLoading = false;
          });
        } else {
          setState(() {
            _subscriptionData = null;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error loading subscription data: $e');
    }
  }

  @override
  Widget buildScreen(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;
    final accentColor = isDarkMode ? const Color(0xFF9667FF) : const Color(0xFFE53935);
    
    return Scaffold(
      backgroundColor: (highContrastMode && isDarkMode) 
          ? Colors.black 
          : (isDarkMode ? const Color(0xFF111827) : Colors.white),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState(isDarkMode, highContrastMode)
            : _error != null
                ? _buildErrorState(isDarkMode, highContrastMode, accentColor)
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(isDarkMode, accentColor, context, highContrastMode),
                        const SizedBox(height: 20),
                        _buildSubscriptionCard(context, isDarkMode, accentColor, highContrastMode),
                        const SizedBox(height: 20),
                        _buildFeatureCard(
                          icon: Icons.shield_outlined,
                          title: 'certifiedTherapists',
                          description: 'licensedMentalHealthProfessionals',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          context: context,
                          highContrastMode: highContrastMode,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.calendar_today_outlined,
                          title: 'flexibleScheduling',
                          description: 'bookSessionsAtYourConvenience',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          context: context,
                          highContrastMode: highContrastMode,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          icon: Icons.timer_outlined,
                          title: 'oneOnOneSessions',
                          description: 'privateConfidentialTherapySessions',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          context: context,
                          highContrastMode: highContrastMode,
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          color: isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                          thickness: 1,
                          height: 20,
                          indent: 20,
                          endIndent: 20,
                        ),
                        const SizedBox(height: 20),
                        _buildPaymentInfo(isDarkMode, accentColor, context, highContrastMode),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildHeader(bool isDarkMode, Color accentColor, BuildContext context, bool highContrastMode) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          LocalizedText(
            'mugangaTherapy',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: highContrastMode 
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : accentColor,
            ),
          ),
          const SizedBox(height: 8),
          LocalizedText(
            'professionalMentalHealthSupport',
            style: TextStyle(
              fontSize: 16,
              color: highContrastMode 
                  ? (isDarkMode ? Colors.white70 : Colors.black87)
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode, bool highContrastMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? const Color(0xFF9667FF) : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading subscription data...',
            style: TextStyle(
              color: highContrastMode 
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode, bool highContrastMode, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.error_outline,
              size: 64,
              color: highContrastMode 
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading subscription data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white70 : Colors.black54)
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadSubscriptionData,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, bool isDarkMode, Color accentColor, bool highContrastMode) {
    if (_subscriptionData == null) {
      return _buildNoSubscriptionCard(context, isDarkMode, accentColor, highContrastMode);
    }

    final status = _subscriptionData!['status'] as String?;

    switch (status) {
      case 'pending':
        return _buildPendingSubscriptionCard(context, isDarkMode, accentColor, highContrastMode);
      case 'approved':
        return _buildActiveSubscriptionCard(context, isDarkMode, accentColor, highContrastMode);
      case 'rejected':
        return _buildRejectedSubscriptionCard(context, isDarkMode, accentColor, highContrastMode);
      case 'expired':
        return _buildExpiredSubscriptionCard(context, isDarkMode, accentColor, highContrastMode);
      default:
        return _buildNoSubscriptionCard(context, isDarkMode, accentColor, highContrastMode);
    }
  }

  Widget _buildNoSubscriptionCard(BuildContext context, bool isDarkMode, Color accentColor, bool highContrastMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: highContrastMode 
            ? null 
            : LinearGradient(
                colors: [
                  isDarkMode 
                      ? const Color(0xFF2D3748).withOpacity(0.8) 
                      : const Color(0xFFF5F7FA),
                  isDarkMode 
                      ? const Color(0xFF1E293B).withOpacity(0.9) 
                      : const Color(0xFFEDF2F7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrastMode 
            ? (isDarkMode ? Colors.black : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: highContrastMode 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: highContrastMode 
              ? (isDarkMode ? Colors.white : Colors.black)
              : (isDarkMode 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05)),
          width: highContrastMode ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 32,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            LocalizedText(
              'monthlySubscription',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              '2000RWF',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white : Colors.black)
                    : (isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get access to professional mental health support',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: highContrastMode 
                    ? (isDarkMode ? Colors.white70 : Colors.black54)
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showMtnPaymentDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Subscribe Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSubscriptionCard(BuildContext context, bool isDarkMode, Color accentColor, bool highContrastMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: highContrastMode 
            ? null 
            : LinearGradient(
                colors: [
                  isDarkMode 
                      ? const Color(0xFF2D3748).withOpacity(0.8) 
                      : const Color(0xFFF5F7FA),
                  isDarkMode 
                      ? const Color(0xFF1E293B).withOpacity(0.9) 
                      : const Color(0xFFEDF2F7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: highContrastMode 
            ? (isDarkMode ? Colors.black : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: highContrastMode 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: highContrastMode 
              ? (isDarkMode ? Colors.white : Colors.black)
              : (isDarkMode 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05)),
          width: highContrastMode ? 2.0 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Pending badge at top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pending_outlined,
                  color: const Color(0xFFFF9800),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "Pending Approval",
                  style: TextStyle(
                    color: const Color(0xFFFF9800),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                LocalizedText(
                  'monthlySubscription',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: highContrastMode 
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 8),
                LocalizedText(
                  '2000RWF',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: highContrastMode 
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                // Divider
                Divider(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                // Status info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.2) 
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Your subscription is pending approval",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "We're currently verifying your payment. This usually takes less than 10 minutes during business hours.",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      if (_subscriptionData!['transactionId'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 16,
                                color: isDarkMode ? Colors.white54 : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Transaction ID: ${_subscriptionData!['transactionId']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatusItem(
                            icon: Icons.payments_outlined,
                            label: "Payment received",
                            isDone: true,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusItem(
                            icon: Icons.verified_outlined,
                            label: "Verification",
                            isDone: (_subscriptionData!['verificationStatus'] == 'verified'),
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusItem(
                            icon: Icons.check_circle_outline,
                            label: "Activated",
                            isDone: (_subscriptionData!['status'] == 'approved'),
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSubscriptionHistoryDialog(context),
                        icon: const Icon(Icons.history),
                        label: const Text("View History"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDarkMode ? Colors.white70 : Colors.black54,
                          side: BorderSide(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTransactionIdDialog(context),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text("Update ID"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentColor,
                          side: BorderSide(color: accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionCard(BuildContext context, bool isDarkMode, Color accentColor, bool highContrastMode) {
    final expiresAt = _subscriptionData!['expiresAt'];
    DateTime? expiryDate;
    if (expiresAt != null) {
      try {
        expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt as int);
      } catch (e) {
        debugPrint('Error parsing expiry date: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Active badge at top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "Active Subscription",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 32,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                LocalizedText(
                  'monthlySubscription',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                LocalizedText(
                  '2000RWF',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (expiryDate != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expires: ${_formatDate(expiryDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showContactSupportDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Book Therapy Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedSubscriptionCard(BuildContext context, bool isDarkMode, Color accentColor, bool highContrastMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Rejected badge at top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "Payment Rejected",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 32,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Subscription Rejected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unfortunately, your payment could not be verified. Please try again or contact support for assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showContactSupportDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Contact Support'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showMtnPaymentDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredSubscriptionCard(BuildContext context, bool isDarkMode, Color accentColor, bool highContrastMode) {
    final expiresAt = _subscriptionData!['expiresAt'];
    DateTime? expiryDate;
    if (expiresAt != null) {
      try {
        expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt as int);
      } catch (e) {
        debugPrint('Error parsing expiry date: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Expired badge at top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  "Subscription Expired",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule,
                    size: 32,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Subscription Expired',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (expiryDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Expired on: ${_formatDate(expiryDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Your subscription has expired. Renew now to continue accessing professional therapy services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showMtnPaymentDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Renew Subscription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help with your subscription? Contact our support team:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('+250 780 332 779'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('support@hopecore.rw'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Subscription History'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_subscriptionData != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Subscription',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_subscriptionData!['status'] as String?).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (_subscriptionData!['status'] as String? ?? 'unknown').toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(_subscriptionData!['status'] as String?),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildHistoryRow('Amount', '2,000 RWF'),
                      _buildHistoryRow('Payment Method', _subscriptionData!['paymentMethod'] as String? ?? 'N/A'),
                      if (_subscriptionData!['transactionId'] != null)
                        _buildHistoryRow('Transaction ID', _subscriptionData!['transactionId'] as String),
                      if (_subscriptionData!['createdAt'] != null)
                        _buildHistoryRow(
                          'Submitted',
                          _formatTimestamp(_subscriptionData!['createdAt']),
                        ),
                      if (_subscriptionData!['expiresAt'] != null)
                        _buildHistoryRow(
                          'Expires',
                          _formatTimestamp(_subscriptionData!['expiresAt']),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No subscription history found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.orange.shade800;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Unknown';
      }
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required bool isDone,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone 
                  ? Colors.green.withOpacity(0.1) 
                  : isDarkMode 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              color: isDone 
                  ? Colors.green 
                  : isDarkMode ? Colors.white54 : Colors.black54,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMtnPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF111827),
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          LocalizedText(
                            'mtnMobileMoneyPayment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF9667FF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF9667FF),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.smartphone,
                              size: 32,
                              color: Color(0xFF9667FF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          LocalizedText(
                            'payWithMtnMobileMoney',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LocalizedText(
                            'dialTheFollowingUssdCodeOnYourMtnPhone',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LocalizedText(
                                  'ussdCode',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF9667FF),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(const ClipboardData(
                                      text: '*182*1*1*0780332779*2000#',
                                    ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'USSD code copied to clipboard',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Color(0xFF1E293B),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.copy,
                                    color: Color(0xFF9667FF),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          LocalizedText(
                            'afterPaymentYouWillReceive',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildCheckItem('immediateConfirmationMessage'),
                          const SizedBox(height: 8),
                          _buildCheckItem('paymentReceiptFromOurTeam'),
                          const SizedBox(height: 8),
                          _buildCheckItem('accessToTherapyBooking'),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            'note',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LocalizedText(
                            'paymentGoesDirectlyToOurTeamAt250780332779TheNumberIsRegisteredToAlineIRADUKUNDAOurChiefOperationsOfficerSheWillBeContactingYouAsSoonAsThePaymentIsReceivedForAccountActivation',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showTransactionIdDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9667FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: LocalizedText(
                                'iveMadeThePayment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showTransactionIdDialog(BuildContext context) {
    TextEditingController transactionIdController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6E40C9), Color(0xFF8A4FFF)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A4FFF).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6E40C9).withOpacity(0.8),
                            const Color(0xFF8A4FFF).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          // Animated icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title with glowing effect
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE0CCFF)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: LocalizedText(
                              'confirmYourPayment',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Subtitle
                          LocalizedText(
                            'pleaseEnterTheFinancialTransactionId',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Transaction ID field with glass effect
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: transactionIdController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Transaction ID',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.receipt_long,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Confirmation message
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: LocalizedText(
                                    'pleaseWaitForOurTeamToConfirmYourTransaction',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Show error message if any
                          if (errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          // Submit button with glow effect
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : () async {
                                final transactionId = transactionIdController.text.trim();
                                
                                // Validate transaction ID
                                if (transactionId.isEmpty) {
                                  setDialogState(() {
                                    errorMessage = 'Please enter a transaction ID';
                                  });
                                  return;
                                }
                                
                                if (transactionId.length < 8) {
                                  setDialogState(() {
                                    errorMessage = 'Transaction ID must be at least 8 characters long';
                                  });
                                  return;
                                }
                                
                                // Check if transaction ID contains only valid characters
                                if (!RegExp(r'^[A-Z0-9]+$').hasMatch(transactionId.toUpperCase())) {
                                  setDialogState(() {
                                    errorMessage = 'Transaction ID can only contain letters and numbers';
                                  });
                                  return;
                                }
                                
                                setDialogState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });
                                
                                try {
                                  await _saveSubscriptionToDatabase(context, transactionId);
                                  
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: LocalizedText(
                                                'transactionIdSubmittedSuccessfully',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isSubmitting = false;
                                    errorMessage = 'Failed to submit transaction ID. Please check your connection and try again.';
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: const Color(0xFF8A4FFF),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSubmitting
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              const Color(0xFF8A4FFF),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Submitting...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF8A4FFF),
                                          ),
                                        ),
                                      ],
                                    )
                                  : LocalizedText(
                                      'confirmAndSubmit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Decorative elements
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  // Save subscription data to Firebase Realtime Database
  Future<void> _saveSubscriptionToDatabase(BuildContext context, String transactionId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Ensure the user is logged in
    if (!authService.isLoggedIn || authService.userId == null) {
      debugPrint('❌ User not logged in - cannot save subscription');
      throw Exception('Please log in to submit your payment details');
    }

    final userId = authService.userId!;
    final username = authService.username ?? 'Unknown User';
    
    // Create subscription data
    final subscriptionData = {
      'userId': userId,
      'username': username,
      'transactionId': transactionId,
      'amount': 2000,
      'currency': 'RWF',
      'status': 'pending',
      'paymentMethod': 'MTN Mobile Money',
      'createdAt': ServerValue.timestamp,
      'expiresAt': null, // Will be set when approved
      'verificationStatus': 'submitted',
    };
    
    try {
      // Get reference to the database
      final databaseRef = FirebaseDatabase.instance.ref();
      
      // Save data in two locations:
      // 1. User's subscriptions
      await databaseRef
          .child('users')
          .child(userId)
          .child('muganga_subscriptions')
          .child('current')
          .set(subscriptionData);
      
      // 2. All pending subscriptions (for admin to review)
      await databaseRef
          .child('muganga_subscriptions')
          .child('pending')
          .child(userId)
          .set(subscriptionData);
          
      debugPrint('✅ Subscription data saved successfully to Realtime Database');
      
    } catch (e) {
      debugPrint('❌ Error saving subscription data: $e');
      throw Exception('Failed to submit transaction ID. Please check your connection and try again.');
    }
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF9667FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        LocalizedText(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDarkMode,
    required Color accentColor,
    required BuildContext context,
    required bool highContrastMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(highContrastMode ? 18 : 16),
      decoration: BoxDecoration(
        color: highContrastMode 
            ? AccessibilityUtils.getAccessibleSurfaceColor(context)
            : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border: highContrastMode 
            ? Border.all(
                color: AccessibilityUtils.getAccessibleBorderColor(context),
                width: 2.0,
              )
            : null,
        boxShadow: highContrastMode 
            ? null // No shadows in high contrast mode
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: highContrastMode ? 52 : 48,
            height: highContrastMode ? 52 : 48,
            decoration: BoxDecoration(
              color: highContrastMode 
                  ? (isDarkMode ? Colors.white : Colors.black)
                  : (isDarkMode ? const Color(0xFF111827) : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: highContrastMode 
                  ? Border.all(
                      color: AccessibilityUtils.getAccessibleBorderColor(context),
                      width: 2.0,
                    )
                  : null,
            ),
            child: Icon(
              icon,
              color: highContrastMode 
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : accentColor,
              size: highContrastMode ? 26 : 24,
            ),
          ),
          SizedBox(width: highContrastMode ? 18 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  title,
                  style: AccessibilityUtils.getTextStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: highContrastMode 
                        ? AccessibilityUtils.getAccessibleColor(context, Colors.white)
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                SizedBox(height: highContrastMode ? 6 : 4),
                LocalizedText(
                  description,
                  style: AccessibilityUtils.getTextStyle(
                    context,
                    fontSize: 14,
                    color: highContrastMode 
                        ? AccessibilityUtils.getAccessibleColor(context, Colors.white70)
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(bool isDarkMode, Color accentColor, BuildContext context, bool highContrastMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(highContrastMode ? 18 : 16),
      decoration: BoxDecoration(
        color: highContrastMode 
            ? AccessibilityUtils.getAccessibleSurfaceColor(context)
            : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border: highContrastMode 
            ? Border.all(
                color: AccessibilityUtils.getAccessibleBorderColor(context),
                width: 2.0,
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            color: highContrastMode 
                ? AccessibilityUtils.getAccessibleColor(context, accentColor, isPrimary: true)
                : accentColor,
            size: highContrastMode ? 22 : 20,
          ),
          SizedBox(width: highContrastMode ? 14 : 12),
          Expanded(
            child: LocalizedText(
              'payEasilyWithMtnMobileMoneyAndGetInstantAccessToProfessionalTherapy',
              style: AccessibilityUtils.getTextStyle(
                context,
                fontSize: 14,
                color: highContrastMode 
                    ? AccessibilityUtils.getAccessibleColor(context, Colors.white70)
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 