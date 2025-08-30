# Content Reporting Data Flow Summary

## Overview
This document explains how content reports are submitted and stored in the ingabo application, demonstrating the migration from Firestore to Firebase Realtime Database.

## Key Changes Made

### 1. Database Migration
- **Before**: Used Cloud Firestore (`cloud_firestore` package)
- **After**: Uses Firebase Realtime Database (`firebase_database` package)
- **Reason**: Maintains consistency with project architecture - all features use Realtime Database

### 2. Data Storage Structure

#### Firebase Realtime Database Schema:
```json
{
  "content_reports": {
    "{report-uuid}": {
      "id": "uuid-string",
      "contentId": "content-being-reported-id",
      "contentType": "aiMessage|forumPost|forumReply|other",
      "reportedBy": "user-id-or-anonymous",
      "reason": "inappropriate|harmful|spam|misinformation|harassment|other",
      "customReason": "string (if reason=other)",
      "additionalDetails": "optional-string",
      "reportedAt": "ISO-8601-timestamp",
      "status": "pending|reviewed|resolved",
      "reviewedBy": "moderator-id (optional)",
      "reviewedAt": "ISO-8601-timestamp (optional)",
      "moderatorNotes": "string (optional)"
    }
  },
  "users": {
    "{user-id}": {
      "reports": {
        "{report-uuid}": {
          "reportId": "uuid-string",
          "contentId": "content-id",
          "contentType": "content-type",
          "reason": "reason",
          "reportedAt": "timestamp",
          "status": "pending"
        }
      }
    }
  }
}
```

### 3. Database Rules Configuration
Updated `database.rules.json` to include indexing for content reports:
```json
{
  "content_reports": {
    ".indexOn": ["contentId", "reportedBy", "status", "reportedAt"]
  },
  "users": {
    "$uid": {
      "reports": {
        ".indexOn": ["reportedAt", "status"]
      }
    }
  }
}
```

## Data Flow Process

### Step 1: Report Dialog Initialization
1. User opens content report dialog via `ContentReportDialog`
2. Dialog checks if user has already reported the content:
   ```dart
   // Queries: /content_reports?orderBy=contentId&equalTo={contentId}
   // Filters by reportedBy={currentUserId}
   final hasReported = await _reportingService.hasUserReportedContent(contentId);
   ```

### Step 2: Report Submission
1. User fills out report form (reason, custom reason, additional details)
2. On submission, `ContentReportingService.submitReport()` is called:
   ```dart
   // Creates ContentReport object with UUID
   final report = ContentReport(
     id: uuid.v4(),
     contentId: contentId,
     contentType: contentType,
     reportedBy: userId,
     reason: reason,
     // ... other fields
   );
   
   // Saves to: /content_reports/{reportId}
   await database.child('content_reports').child(report.id).set(report.toJson());
   
   // Also saves to user history: /users/{userId}/reports/{reportId}
   await database.child('users').child(userId)
       .child('reports').child(report.id).set(userReportData);
   ```

### Step 3: Data Persistence
- Main report stored in `/content_reports/{reportId}`
- User report history stored in `/users/{userId}/reports/{reportId}`
- Both entries are linked by `reportId`
- Status defaults to "pending" for moderation

### Step 4: Query Operations
- **Check existing reports**: Query by `contentId` and `reportedBy`
- **Get user reports**: Query by `reportedBy`
- **Get pending reports**: Query by `status = "pending"`
- **Report statistics**: Count reports by status

## Service Methods Overview

### ContentReportingService Key Methods:
1. `submitReport()` - Stores new report in Realtime Database
2. `hasUserReportedContent()` - Checks for existing user reports
3. `getUserReports()` - Retrieves user's report history
4. `getPendingReports()` - Gets all pending reports for moderation
5. `updateReportStatus()` - Updates report status (for moderators)
6. `getReportStats()` - Gets report statistics

## Enhanced Logging
Added comprehensive logging to track data flow:
- 📋 Report submission start/completion
- 🔍 Database query operations
- ✅ Success confirmations
- ❌ Error tracking
- 💾 Database path information

## Testing the Data Flow
1. **Open the application** at `http://localhost:3001`
2. **Navigate to forum posts** or AI chat
3. **Click the report button** (flag icon) on any content
4. **Fill out the report form** and submit
5. **Check the browser console** for detailed logging showing:
   - Content ID and type being reported
   - Database paths being used
   - Submission success/failure
   - Data structure being saved

## Database Console Verification
After submitting a report, you can verify the data in Firebase Console:
1. Go to Firebase Console → Realtime Database
2. Navigate to `/content_reports` node
3. Find your report by ID
4. Verify all fields are correctly stored
5. Check `/users/{userId}/reports` for user history

## Error Handling
- Graceful fallback when database is unavailable
- User-friendly error messages
- Comprehensive logging for debugging
- Retry logic for network issues
- Form validation before submission

This migration ensures all content reporting functionality uses Firebase Realtime Database consistently with the rest of the application architecture.