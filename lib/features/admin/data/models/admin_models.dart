import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/config/app_config.dart';

class AdminUser {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isActive,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map, String id) {
    return AdminUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: AdminRole.values.firstWhere(
            (role) => role.toString() == 'AdminRole.${map['role']}',
        orElse: () => AdminRole.moderator,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'isActive': isActive,
    };
  }
}

enum AdminRole {
  superAdmin,
  admin,
  moderator,
}

// Admin Statistics Model
class AdminStats {
  final int totalUsers;
  final int totalPosts;
  final int totalTips;
  final int totalVideos;
  final int totalComments;
  final int newUsersToday;
  final int newUsersWeek;
  final int newUsersMonth;
  final int activeUsersToday;
  final int activeUsersWeek;
  final int pendingReports;
  final Map<String, int> usersByCountry;
  final Map<String, int> postsByCategory;
  final Map<String, int> tipsByCategory;
  final Map<String, int> videosByCategory;

  AdminStats({
    required this.totalUsers,
    required this.totalPosts,
    required this.totalTips,
    required this.totalVideos,
    required this.totalComments,
    required this.newUsersToday,
    required this.newUsersWeek,
    required this.newUsersMonth,
    required this.activeUsersToday,
    required this.activeUsersWeek,
    required this.pendingReports,
    required this.usersByCountry,
    required this.postsByCategory,
    required this.tipsByCategory,
    required this.videosByCategory,
  });

  factory AdminStats.fromMap(Map<String, dynamic> map) {
    return AdminStats(
      totalUsers: map['totalUsers'] ?? 0,
      totalPosts: map['totalPosts'] ?? 0,
      totalTips: map['totalTips'] ?? 0,
      totalVideos: map['totalVideos'] ?? 0,
      totalComments: map['totalComments'] ?? 0,
      newUsersToday: map['newUsersToday'] ?? 0,
      newUsersWeek: map['newUsersWeek'] ?? 0,
      newUsersMonth: map['newUsersMonth'] ?? 0,
      activeUsersToday: map['activeUsersToday'] ?? 0,
      activeUsersWeek: map['activeUsersWeek'] ?? 0,
      pendingReports: map['pendingReports'] ?? 0,
      usersByCountry: Map<String, int>.from(map['usersByCountry'] ?? {}),
      postsByCategory: Map<String, int>.from(map['postsByCategory'] ?? {}),
      tipsByCategory: Map<String, int>.from(map['tipsByCategory'] ?? {}),
      videosByCategory: Map<String, int>.from(map['videosByCategory'] ?? {}),
    );
  }
}

// Content Report Model
class ContentReport {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedContentId;
  final ContentType contentType;
  final ReportReason reason;
  final String description;
  final DateTime createdAt;
  final ReportStatus status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? adminNotes;

  ContentReport({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedContentId,
    required this.contentType,
    required this.reason,
    required this.description,
    required this.createdAt,
    required this.status,
    this.resolvedBy,
    this.resolvedAt,
    this.adminNotes,
  });

  factory ContentReport.fromMap(Map<String, dynamic> map, String id) {
    return ContentReport(
      id: id,
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reportedContentId: map['reportedContentId'] ?? '',
      contentType: ContentType.values.firstWhere(
            (type) => type.toString() == 'ContentType.${map['contentType']}',
        orElse: () => ContentType.post,
      ),
      reason: ReportReason.values.firstWhere(
            (reason) => reason.toString() == 'ReportReason.${map['reason']}',
        orElse: () => ReportReason.inappropriate,
      ),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ReportStatus.values.firstWhere(
            (status) => status.toString() == 'ReportStatus.${map['status']}',
        orElse: () => ReportStatus.pending,
      ),
      resolvedBy: map['resolvedBy'],
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: map['adminNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedContentId': reportedContentId,
      'contentType': contentType.toString().split('.').last,
      'reason': reason.toString().split('.').last,
      'description': description,
      'createdAt': createdAt,
      'status': status.toString().split('.').last,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt,
      'adminNotes': adminNotes,
    };
  }
}

enum ContentType { post, comment, user, video, tip }
enum ReportReason { inappropriate, spam, harassment, misinformation, other }
enum ReportStatus { pending, resolved, dismissed }

// Admin Action Log Model
class AdminActionLog {
  final String id;
  final String adminId;
  final String adminName;
  final AdminActionType actionType;
  final String targetId;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AdminActionLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.actionType,
    required this.targetId,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory AdminActionLog.fromMap(Map<String, dynamic> map, String id) {
    return AdminActionLog(
      id: id,
      adminId: map['adminId'] ?? '',
      adminName: map['adminName'] ?? '',
      actionType: AdminActionType.values.firstWhere(
            (type) => type.toString() == 'AdminActionType.${map['actionType']}',
        orElse: () => AdminActionType.userSuspended,
      ),
      targetId: map['targetId'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'actionType': actionType.toString().split('.').last,
      'targetId': targetId,
      'description': description,
      'timestamp': timestamp,
      'metadata': metadata,
    };
  }
}

// Enhanced User Model for Admin View
class AdminUserView {
  final String id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? location;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isActive;
  final bool isSuspended;
  final int postsCount;
  final int commentsCount;
  final int likesReceived;
  final String? profilePictureUrl;
  final String? suspensionReason;
  final DateTime? suspendedAt;

  AdminUserView({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.location,
    required this.joinedAt,
    this.lastActiveAt,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.isActive,
    required this.isSuspended,
    required this.postsCount,
    required this.commentsCount,
    required this.likesReceived,
    this.profilePictureUrl,
    this.suspensionReason,
    this.suspendedAt,
  });

  factory AdminUserView.fromMap(Map<String, dynamic> map) {
    return AdminUserView(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      location: map['location'],
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (map['lastActiveAt'] as Timestamp?)?.toDate(),
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      isSuspended: map['isSuspended'] ?? false,
      postsCount: map['postsCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      likesReceived: map['likesReceived'] ?? 0,
      profilePictureUrl: map['profilePictureUrl'],
      suspensionReason: map['suspensionReason'],
      suspendedAt: (map['suspendedAt'] as Timestamp?)?.toDate(),
    );
  }
}