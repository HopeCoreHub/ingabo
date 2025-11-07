import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../accessibility_provider.dart';
import '../services/content_reporting_service.dart';

class ContentReportDialog extends StatefulWidget {
  final String contentId;
  final ContentType contentType;
  final String contentPreview; // First few words of the content being reported

  const ContentReportDialog({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.contentPreview,
  });

  @override
  State<ContentReportDialog> createState() => _ContentReportDialogState();
}

class _ContentReportDialogState extends State<ContentReportDialog> {
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final ContentReportingService _reportingService = ContentReportingService();

  ReportReason? _selectedReason;
  bool _isSubmitting = false;
  bool _hasAlreadyReported = false;
  bool _isCheckingReportStatus = true;
  String? _initializationError;

  final Map<ReportReason, String> _reasonLabels = {
    ReportReason.inappropriate: 'Inappropriate Content',
    ReportReason.harmful: 'Harmful or Dangerous',
    ReportReason.spam: 'Spam',
    ReportReason.misinformation: 'Misinformation',
    ReportReason.harassment: 'Harassment or Bullying',
    ReportReason.other: 'Other',
  };

  final Map<ReportReason, String> _reasonDescriptions = {
    ReportReason.inappropriate: 'Content that violates community guidelines',
    ReportReason.harmful: 'Content that could cause harm to users',
    ReportReason.spam: 'Unwanted or repetitive content',
    ReportReason.misinformation: 'False or misleading information',
    ReportReason.harassment: 'Content that targets or bullies users',
    ReportReason.other: 'Other concerns not listed above',
  };

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyReported();
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadyReported() async {
    try {
      debugPrint('🔍 CHECKING REPORT STATUS');
      debugPrint('🔍 Content ID: ${widget.contentId}');
      debugPrint(
        '🔍 Querying Firebase Realtime Database for existing reports...',
      );

      final hasReported = await _reportingService.hasUserReportedContent(
        widget.contentId,
      );

      debugPrint(
        '🔍 Report check result: ${hasReported ? "User has already reported this content" : "User has not reported this content"}',
      );

      if (mounted) {
        setState(() {
          _hasAlreadyReported = hasReported;
          _isCheckingReportStatus = false;
          _initializationError = null;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking report status from Realtime Database: $e');
      if (mounted) {
        setState(() {
          _hasAlreadyReported = false;
          _isCheckingReportStatus = false;
          _initializationError =
              'Failed to load report status. You can still submit a report.';
        });
      }
    }
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      _showErrorSnackBar('Please select a reason for reporting this content.');
      return;
    }

    if (_selectedReason == ReportReason.other &&
        _customReasonController.text.trim().isEmpty) {
      _showErrorSnackBar('Please provide a custom reason.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Enhanced logging to track data flow
      debugPrint('📋 CONTENT REPORT SUBMISSION STARTED');
      debugPrint('📋 Content ID: ${widget.contentId}');
      debugPrint('📋 Content Type: ${widget.contentType.name}');
      debugPrint('📋 Report Reason: ${_selectedReason!.name}');
      debugPrint(
        '📋 Custom Reason: ${_selectedReason == ReportReason.other ? _customReasonController.text.trim() : "N/A"}',
      );
      debugPrint(
        '📋 Additional Details: ${_detailsController.text.trim().isNotEmpty ? _detailsController.text.trim() : "None"}',
      );
      debugPrint('📋 Content Preview: "${widget.contentPreview}"');

      final success = await _reportingService.submitReport(
        contentId: widget.contentId,
        contentType: widget.contentType,
        reason: _selectedReason!,
        customReason:
            _selectedReason == ReportReason.other
                ? _customReasonController.text.trim()
                : null,
        additionalDetails:
            _detailsController.text.trim().isNotEmpty
                ? _detailsController.text.trim()
                : null,
      );

      if (mounted) {
        if (success) {
          debugPrint('✅ CONTENT REPORT SUBMITTED SUCCESSFULLY');
          debugPrint(
            '✅ Report data has been saved to Firebase Realtime Database under "content_reports" node',
          );
          debugPrint('✅ User report history updated (if authenticated)');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Report submitted successfully. Thank you for helping keep our community safe.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

          // Close the dialog and return true to indicate successful report
          Navigator.of(context).pop(true);
        } else {
          debugPrint('❌ CONTENT REPORT SUBMISSION FAILED');
          _showErrorSnackBar('Failed to submit report. Please try again.');
        }
      }
    } catch (e) {
      debugPrint('❌ CONTENT REPORT SUBMISSION ERROR: $e');
      if (mounted) {
        _showErrorSnackBar('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getContentTypeLabel() {
    switch (widget.contentType) {
      case ContentType.aiMessage:
        return 'AI Message';
      case ContentType.forumPost:
        return 'Forum Post';
      case ContentType.forumReply:
        return 'Forum Reply';
      case ContentType.other:
        return 'Other Content';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    // Show loading dialog while checking report status
    if (_isCheckingReportStatus) {
      return _buildLoadingDialog(isDarkMode, highContrastMode);
    }

    if (_hasAlreadyReported) {
      return _buildAlreadyReportedDialog(isDarkMode, highContrastMode);
    }

    return AlertDialog(
      backgroundColor:
          highContrastMode
              ? (isDarkMode ? Colors.black : Colors.white)
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            highContrastMode
                ? BorderSide(
                  color: isDarkMode ? Colors.white : Colors.black,
                  width: 2,
                )
                : BorderSide.none,
      ),
      title: Row(
        children: [
          Icon(Icons.flag, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Report Content',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? Colors.grey.shade800.withOpacity(0.3)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      highContrastMode
                          ? Border.all(
                            color: isDarkMode ? Colors.white : Colors.black,
                          )
                          : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reporting: ${_getContentTypeLabel()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${widget.contentPreview}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Show initialization error if any
              if (_initializationError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _initializationError!,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Database structure info (for development/demonstration)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage, color: Colors.blue, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Database Storage Info',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reports are stored in Firebase Realtime Database:',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Main report: /content_reports/{reportId}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '• User history: /users/{userId}/reports/{reportId}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Report reason selection
              Text(
                'Why are you reporting this content?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              ..._reasonLabels.entries.map((entry) {
                return _buildReasonOption(
                  entry.key,
                  entry.value,
                  isDarkMode,
                  highContrastMode,
                );
              }),

              // Custom reason input for "Other"
              if (_selectedReason == ReportReason.other) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customReasonController,
                  decoration: InputDecoration(
                    labelText: 'Please specify',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            highContrastMode
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : Colors.grey,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            highContrastMode
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 16),

              // Additional details (optional)
              Text(
                'Additional details (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                decoration: InputDecoration(
                  hintText: 'Provide any additional context...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          highContrastMode
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color:
                          highContrastMode
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.grey.shade300,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed:
              _isSubmitting || _selectedReason == null ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text('Submit Report'),
        ),
      ],
    );
  }

  Widget _buildReasonOption(
    ReportReason reason,
    String label,
    bool isDarkMode,
    bool highContrastMode,
  ) {
    final isSelected = _selectedReason == reason;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReason = reason;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? Colors.red
                      : (highContrastMode
                          ? (isDarkMode ? Colors.white : Colors.black)
                          : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            color:
                isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.grey,
                    width: 2,
                  ),
                  color: isSelected ? Colors.red : Colors.transparent,
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color:
                            isSelected
                                ? Colors.red
                                : (isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                    Text(
                      _reasonDescriptions[reason] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDialog(bool isDarkMode, bool highContrastMode) {
    return AlertDialog(
      backgroundColor:
          highContrastMode
              ? (isDarkMode ? Colors.black : Colors.white)
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            highContrastMode
                ? BorderSide(
                  color: isDarkMode ? Colors.white : Colors.black,
                  width: 2,
                )
                : BorderSide.none,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyReportedDialog(bool isDarkMode, bool highContrastMode) {
    return AlertDialog(
      backgroundColor:
          highContrastMode
              ? (isDarkMode ? Colors.black : Colors.white)
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            highContrastMode
                ? BorderSide(
                  color: isDarkMode ? Colors.white : Colors.black,
                  width: 2,
                )
                : BorderSide.none,
      ),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 8),
          Text(
            'Already Reported',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'You have already reported this content. Our moderation team will review it and take appropriate action.',
        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Quick report button widget that can be embedded in content cards
class QuickReportButton extends StatelessWidget {
  final String contentId;
  final ContentType contentType;
  final String contentPreview;
  final VoidCallback? onReported;

  const QuickReportButton({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.contentPreview,
    this.onReported,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accessibilityProvider = Provider.of<AccessibilityProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final highContrastMode = accessibilityProvider.highContrastMode;

    return IconButton(
      onPressed: () => _showReportDialog(context),
      icon: Icon(
        Icons.flag_outlined,
        size: 16,
        color:
            highContrastMode
                ? (isDarkMode ? Colors.white : Colors.black)
                : (isDarkMode ? Colors.white54 : Colors.black54),
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      tooltip: 'Report this content',
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => ContentReportDialog(
            contentId: contentId,
            contentType: contentType,
            contentPreview: contentPreview,
          ),
    );

    if (result == true && onReported != null) {
      onReported!();
    }
  }
}

/// Report menu option for overflow menus
class ReportMenuOption extends StatelessWidget {
  final String contentId;
  final ContentType contentType;
  final String contentPreview;
  final VoidCallback? onReported;

  const ReportMenuOption({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.contentPreview,
    this.onReported,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return PopupMenuItem(
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            'Report Content',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
      onTap: () => _showReportDialog(context),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    // Use a post frame callback to avoid showing dialog during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (context) => ContentReportDialog(
              contentId: contentId,
              contentType: contentType,
              contentPreview: contentPreview,
            ),
      );

      if (result == true && onReported != null) {
        onReported!();
      }
    });
  }
}
