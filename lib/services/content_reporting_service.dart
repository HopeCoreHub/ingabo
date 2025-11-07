import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'auth_service.dart';

enum ContentType { aiMessage, forumPost, forumReply, other }

enum ReportReason {
  inappropriate,
  harmful,
  spam,
  misinformation,
  harassment,
  other,
}

class ContentReport {
  final String id;
  final String contentId;
  final ContentType contentType;
  final String reportedBy;
  final ReportReason reason;
  final String? customReason;
  final String? additionalDetails;
  final DateTime reportedAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? moderatorNotes;

  ContentReport({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.reportedBy,
    required this.reason,
    this.customReason,
    this.additionalDetails,
    required this.reportedAt,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.moderatorNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'contentType': contentType.name,
      'reportedBy': reportedBy,
      'reason': reason.name,
      'customReason': customReason,
      'additionalDetails': additionalDetails,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'moderatorNotes': moderatorNotes,
    };
  }

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      id: json['id'] as String,
      contentId: json['contentId'] as String,
      contentType: ContentType.values.firstWhere(
        (e) => e.name == json['contentType'],
        orElse: () => ContentType.other,
      ),
      reportedBy: json['reportedBy'] as String,
      reason: ReportReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => ReportReason.other,
      ),
      customReason: json['customReason'] as String?,
      additionalDetails: json['additionalDetails'] as String?,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt:
          json['reviewedAt'] != null
              ? DateTime.parse(json['reviewedAt'] as String)
              : null,
      moderatorNotes: json['moderatorNotes'] as String?,
    );
  }
}

class ContentReportingService {
  static final ContentReportingService _instance =
      ContentReportingService._internal();
  DatabaseReference? _database;
  final uuid = const Uuid();

  DatabaseReference? get db {
    try {
      _database ??= FirebaseDatabase.instance.ref();
      return _database;
    } catch (e) {
      debugPrint('Firebase Realtime Database not available: $e');
      return null;
    }
  }

  factory ContentReportingService() {
    return _instance;
  }

  ContentReportingService._internal();

  /// Submit a content report
  Future<bool> submitReport({
    required String contentId,
    required ContentType contentType,
    required ReportReason reason,
    String? customReason,
    String? additionalDetails,
  }) async {
    try {
      final database = db;
      if (database == null) {
        debugPrint(
          'Firebase Realtime Database not available, cannot submit report',
        );
        return false;
      }

      final authService = AuthService();
      final userId = authService.userId ?? 'anonymous';

      final report = ContentReport(
        id: uuid.v4(),
        contentId: contentId,
        contentType: contentType,
        reportedBy: userId,
        reason: reason,
        customReason: customReason,
        additionalDetails: additionalDetails,
        reportedAt: DateTime.now(),
      );

      // Save to Firebase Realtime Database under 'content_reports' node
      await database
          .child('content_reports')
          .child(report.id)
          .set(report.toJson());

      // Also save to user's report history for tracking
      if (userId != 'anonymous') {
        await database
            .child('users')
            .child(userId)
            .child('reports')
            .child(report.id)
            .set({
              'reportId': report.id,
              'contentId': contentId,
              'contentType': contentType.name,
              'reason': reason.name,
              'reportedAt': report.reportedAt.toIso8601String(),
              'status': 'pending',
            });
      }

      debugPrint(
        'Content report submitted successfully to Realtime Database: ${report.id}',
      );
      return true;
    } catch (e) {
      debugPrint('Error submitting content report to Realtime Database: $e');
      return false;
    }
  }

  /// Check if user has already reported specific content
  Future<bool> hasUserReportedContent(String contentId) async {
    try {
      final database = db;
      if (database == null) {
        debugPrint(
          'Firebase Realtime Database not available, cannot check report status',
        );
        return false;
      }

      final authService = AuthService();
      final userId = authService.userId ?? 'anonymous';

      if (userId == 'anonymous') return false;

      // Query content_reports where contentId matches and reportedBy matches userId
      final snapshot =
          await database
              .child('content_reports')
              .orderByChild('contentId')
              .equalTo(contentId)
              .get();

      if (snapshot.exists) {
        final reports = snapshot.value as Map<dynamic, dynamic>;
        // Check if any report was made by current user
        for (var report in reports.values) {
          if (report['reportedBy'] == userId) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking if user reported content: $e');
      return false;
    }
  }

  /// Get user's report history
  Future<List<ContentReport>> getUserReports(String userId) async {
    try {
      final database = db;
      if (database == null) return [];

      final snapshot =
          await database
              .child('content_reports')
              .orderByChild('reportedBy')
              .equalTo(userId)
              .get();

      if (snapshot.exists) {
        final reports = snapshot.value as Map<dynamic, dynamic>;
        final List<ContentReport> result = [];

        reports.forEach((key, value) {
          try {
            result.add(
              ContentReport.fromJson(Map<String, dynamic>.from(value)),
            );
          } catch (e) {
            debugPrint('Error parsing report: $e');
          }
        });

        // Sort by date (newest first)
        result.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
        return result.take(50).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting user reports: $e');
      return [];
    }
  }

  /// Get all pending reports (for admin/moderator use)
  Future<List<ContentReport>> getPendingReports() async {
    try {
      final database = db;
      if (database == null) return [];

      final snapshot =
          await database
              .child('content_reports')
              .orderByChild('status')
              .equalTo('pending')
              .get();

      if (snapshot.exists) {
        final reports = snapshot.value as Map<dynamic, dynamic>;
        final List<ContentReport> result = [];

        reports.forEach((key, value) {
          try {
            result.add(
              ContentReport.fromJson(Map<String, dynamic>.from(value)),
            );
          } catch (e) {
            debugPrint('Error parsing pending report: $e');
          }
        });

        // Sort by date (newest first)
        result.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
        return result;
      }

      return [];
    } catch (e) {
      debugPrint('Error getting pending reports: $e');
      return [];
    }
  }

  /// Update report status (for admin/moderator use)
  Future<bool> updateReportStatus({
    required String reportId,
    required String status,
    String? reviewedBy,
    String? moderatorNotes,
  }) async {
    try {
      final database = db;
      if (database == null) return false;

      await database.child('content_reports').child(reportId).update({
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewedAt': DateTime.now().toIso8601String(),
        'moderatorNotes': moderatorNotes,
      });

      debugPrint(
        'Report status updated successfully in Realtime Database: $reportId',
      );
      return true;
    } catch (e) {
      debugPrint('Error updating report status in Realtime Database: $e');
      return false;
    }
  }

  /// Get report statistics
  Future<Map<String, int>> getReportStats() async {
    try {
      final database = db;
      if (database == null)
        return {'total': 0, 'pending': 0, 'reviewed': 0, 'resolved': 0};

      final snapshot = await database.child('content_reports').get();

      if (!snapshot.exists) {
        return {'total': 0, 'pending': 0, 'reviewed': 0, 'resolved': 0};
      }

      final reports = snapshot.value as Map<dynamic, dynamic>;
      final stats = <String, int>{
        'total': reports.length,
        'pending': 0,
        'reviewed': 0,
        'resolved': 0,
      };

      for (var report in reports.values) {
        final status = report['status'] as String? ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting report stats from Realtime Database: $e');
      return {'total': 0, 'pending': 0, 'reviewed': 0, 'resolved': 0};
    }
  }
}
