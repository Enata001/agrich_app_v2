// lib/features/admin/data/repositories/admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/config/app_config.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final FirebaseService _firebaseService;
  final FirebaseFirestore _firestore;

  AdminRepository(this._firebaseService, this._firestore);

  // ================ STATISTICS ================

  Future<AdminStats> getAdminStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Get basic counts
      final totalUsers = await _getUsersCount();
      final totalPosts = await _getPostsCount();
      final totalTips = await _getTipsCount();
      final totalVideos = await _getVideosCount();
      final totalComments = await _getCommentsCount();

      // Get new users by date ranges
      final newUsersToday = await _getNewUsersCount(todayStart, null);
      final newUsersWeek = await _getNewUsersCount(weekStart, null);
      final newUsersMonth = await _getNewUsersCount(monthStart, null);

      // Get active users
      final activeUsersToday = await _getActiveUsersCount(todayStart);
      final activeUsersWeek = await _getActiveUsersCount(weekStart);

      // Get pending reports
      final pendingReports = await _getPendingReportsCount();

      // Get category breakdowns
      final usersByCountry = await _getUsersByCountry();
      final postsByCategory = await _getPostsByCategory();
      final tipsByCategory = await _getTipsByCategory();
      final videosByCategory = await _getVideosByCategory();

      return AdminStats(
        totalUsers: totalUsers,
        totalPosts: totalPosts,
        totalTips: totalTips,
        totalVideos: totalVideos,
        totalComments: totalComments,
        newUsersToday: newUsersToday,
        newUsersWeek: newUsersWeek,
        newUsersMonth: newUsersMonth,
        activeUsersToday: activeUsersToday,
        activeUsersWeek: activeUsersWeek,
        pendingReports: pendingReports,
        usersByCountry: usersByCountry,
        postsByCategory: postsByCategory,
        tipsByCategory: tipsByCategory,
        videosByCategory: videosByCategory,
      );
    } catch (e) {
      throw Exception('Failed to get admin stats: $e');
    }
  }

  // Helper methods for statistics
  Future<int> _getUsersCount() async {
    final snapshot = await _firestore.collection(AppConfig.usersCollection).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPostsCount() async {
    final snapshot = await _firestore.collection(AppConfig.postsCollection).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getTipsCount() async {
    final snapshot = await _firestore.collection(AppConfig.tipsCollection).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getVideosCount() async {
    final snapshot = await _firestore.collection(AppConfig.videosCollection).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getCommentsCount() async {
    final snapshot = await _firestore.collection(AppConfig.commentsCollection).count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getNewUsersCount(DateTime start, DateTime? end) async {
    Query query = _firestore
        .collection(AppConfig.usersCollection)
        .where('joinedAt', isGreaterThanOrEqualTo: start);

    if (end != null) {
      query = query.where('joinedAt', isLessThan: end);
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _getActiveUsersCount(DateTime since) async {
    final snapshot = await _firestore
        .collection(AppConfig.usersCollection)
        .where('lastActiveAt', isGreaterThanOrEqualTo: since)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPendingReportsCount() async {
    final snapshot = await _firestore
        .collection(AppConfig.reportedContentCollection)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, int>> _getUsersByCountry() async {
    final snapshot = await _firestore.collection(AppConfig.usersCollection).get();
    final Map<String, int> result = {};

    for (final doc in snapshot.docs) {
      final location = doc.data()['location'] as String? ?? 'Unknown';
      result[location] = (result[location] ?? 0) + 1;
    }

    return result;
  }

  Future<Map<String, int>> _getPostsByCategory() async {
    final snapshot = await _firestore.collection(AppConfig.postsCollection).get();
    final Map<String, int> result = {};

    for (final doc in snapshot.docs) {
      final tags = List<String>.from(doc.data()['tags'] ?? []);
      for (final tag in tags) {
        result[tag] = (result[tag] ?? 0) + 1;
      }
    }

    return result;
  }

  Future<Map<String, int>> _getTipsByCategory() async {
    final snapshot = await _firestore.collection(AppConfig.tipsCollection).get();
    final Map<String, int> result = {};

    for (final doc in snapshot.docs) {
      final category = doc.data()['category'] as String? ?? 'general';
      result[category] = (result[category] ?? 0) + 1;
    }

    return result;
  }

  Future<Map<String, int>> _getVideosByCategory() async {
    final snapshot = await _firestore.collection(AppConfig.videosCollection).get();
    final Map<String, int> result = {};

    for (final doc in snapshot.docs) {
      final category = doc.data()['category'] as String? ?? 'general';
      result[category] = (result[category] ?? 0) + 1;
    }

    return result;
  }

  // ================ USER MANAGEMENT ================

  Stream<List<AdminUserView>> getUsers({
    String searchQuery = '',
    UserFilterType filter = UserFilterType.all,
    int limit = 50,
  }) {
    Query query = _firestore.collection(AppConfig.usersCollection);

    // Apply filters
    switch (filter) {
      case UserFilterType.active:
        break;
      case UserFilterType.suspended:
        query = query.where('isSuspended', isEqualTo: true);
        break;
      case UserFilterType.unverified:
        query = query.where('isPhoneVerified', isEqualTo: false);
        break;
      case UserFilterType.all:
      break;
    }

    query = query.orderBy('joinedAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      List<AdminUserView> users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AdminUserView.fromMap(data);
      }).toList();

      // Apply search filter if provided
      if (searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        users = users.where((user) {
          return user.username.toLowerCase().contains(lowercaseQuery) ||
              user.email.toLowerCase().contains(lowercaseQuery) ||
              (user.phoneNumber?.contains(searchQuery) ?? false);
        }).toList();
      }

      return users;
    });
  }

  Future<AdminUserView?> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection(AppConfig.usersCollection).doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      userData['id'] = userId;

      // Get additional stats
      final postsCount = await _getUserPostsCount(userId);
      final commentsCount = await _getUserCommentsCount(userId);
      final likesReceived = await _getUserLikesReceived(userId);

      userData['postsCount'] = postsCount;
      userData['commentsCount'] = commentsCount;
      userData['likesReceived'] = likesReceived;

      return AdminUserView.fromMap(userData);
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  Future<void> suspendUser(String userId, String reason, String adminId) async {
    try {
      await _firestore.collection(AppConfig.usersCollection).doc(userId).update({
        'isSuspended': true,
        'suspensionReason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
      });

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.userSuspended,
        targetId: userId,
        description: 'User suspended: $reason',
      );
    } catch (e) {
      throw Exception('Failed to suspend user: $e');
    }
  }

  Future<void> activateUser(String userId, String adminId) async {
    try {
      await _firestore.collection(AppConfig.usersCollection).doc(userId).update({
        'isSuspended': false,
        'isActive': true,
        'suspensionReason': FieldValue.delete(),
        'suspendedAt': FieldValue.delete(),
      });

      // Log admin action
      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.userActivated,
        targetId: userId,
        description: 'User activated',
      );
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConfig.postsCollection)
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user posts: $e');
    }
  }

  Future<int> _getUserPostsCount(String userId) async {
    final snapshot = await _firestore
        .collection(AppConfig.postsCollection)
        .where('authorId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getUserCommentsCount(String userId) async {
    final snapshot = await _firestore
        .collection(AppConfig.commentsCollection)
        .where('authorId', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getUserLikesReceived(String userId) async {
    final postsSnapshot = await _firestore
        .collection(AppConfig.postsCollection)
        .where('authorId', isEqualTo: userId)
        .get();

    int totalLikes = 0;
    for (final doc in postsSnapshot.docs) {
      totalLikes += (doc.data()['likesCount'] as int? ?? 0);
    }

    return totalLikes;
  }

  // ================ CONTENT MANAGEMENT ================

  // Tips Management
  Future<String> createTip(Map<String, dynamic> tipData, String adminId) async {
    try {
      tipData['createdAt'] = FieldValue.serverTimestamp();
      tipData['updatedAt'] = FieldValue.serverTimestamp();
      tipData['isActive'] = true;

      final docRef = await _firestore.collection(AppConfig.tipsCollection).add(tipData);

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.tipCreated,
        targetId: docRef.id,
        description: 'Created tip: ${tipData['title']}',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create tip: $e');
    }
  }

  Future<void> updateTip(String tipId, Map<String, dynamic> updates, String adminId) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(AppConfig.tipsCollection).doc(tipId).update(updates);

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.tipUpdated,
        targetId: tipId,
        description: 'Updated tip',
      );
    } catch (e) {
      throw Exception('Failed to update tip: $e');
    }
  }

  Future<void> deleteTip(String tipId, String adminId) async {
    try {
      await _firestore.collection(AppConfig.tipsCollection).doc(tipId).delete();

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.tipDeleted,
        targetId: tipId,
        description: 'Deleted tip',
      );
    } catch (e) {
      throw Exception('Failed to delete tip: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAllTips({String category = ''}) {
    Query query = _firestore.collection(AppConfig.tipsCollection);

    if (category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Videos Management
  Future<String> createVideo(Map<String, dynamic> videoData, String adminId) async {
    try {
      videoData['createdAt'] = FieldValue.serverTimestamp();
      videoData['updatedAt'] = FieldValue.serverTimestamp();
      videoData['isActive'] = true;
      videoData['views'] = 0;
      videoData['likes'] = 0;
      videoData['commentsCount'] = 0;
      videoData['likedBy'] = [];

      final docRef = await _firestore.collection(AppConfig.videosCollection).add(videoData);

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.videoAdded,
        targetId: docRef.id,
        description: 'Created video: ${videoData['title']}',
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create video: $e');
    }
  }

  Future<void> updateVideo(String videoId, Map<String, dynamic> updates, String adminId) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(AppConfig.videosCollection).doc(videoId).update(updates);

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.videoUpdated,
        targetId: videoId,
        description: 'Updated video',
      );
    } catch (e) {
      throw Exception('Failed to update video: $e');
    }
  }

  Future<void> deleteVideo(String videoId, String adminId) async {
    try {
      await _firestore.collection(AppConfig.videosCollection).doc(videoId).delete();

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.videoDeleted,
        targetId: videoId,
        description: 'Deleted video',
      );
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAllVideos({String category = ''}) {
    Query query = _firestore.collection(AppConfig.videosCollection);

    if (category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Posts Management
  Future<void> deletePost(String postId, String adminId) async {
    try {
      await _firebaseService.deletePost(postId);

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.postDeleted,
        targetId: postId,
        description: 'Deleted post',
      );
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  Future<void> deleteComment(String commentId, String adminId) async {
    try {
      await _firebaseService.deleteComment(commentId);

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.commentDeleted,
        targetId: commentId,
        description: 'Deleted comment',
      );
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // ================ REPORTS MANAGEMENT ================

  Stream<List<ContentReport>> getReports({ReportStatus? status}) {
    Query query = _firestore.collection(AppConfig.reportedContentCollection);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContentReport.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> resolveReport(String reportId, String adminId, String adminNotes) async {
    try {
      await _firestore.collection(AppConfig.reportedContentCollection).doc(reportId).update({
        'status': 'resolved',
        'resolvedBy': adminId,
        'resolvedAt': FieldValue.serverTimestamp(),
        'adminNotes': adminNotes,
      });

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.reportResolved,
        targetId: reportId,
        description: 'Report resolved: $adminNotes',
      );
    } catch (e) {
      throw Exception('Failed to resolve report: $e');
    }
  }

  Future<void> dismissReport(String reportId, String adminId, String reason) async {
    try {
      await _firestore.collection(AppConfig.reportedContentCollection).doc(reportId).update({
        'status': 'dismissed',
        'resolvedBy': adminId,
        'resolvedAt': FieldValue.serverTimestamp(),
        'adminNotes': reason,
      });

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.reportResolved,
        targetId: reportId,
        description: 'Report dismissed: $reason',
      );
    } catch (e) {
      throw Exception('Failed to dismiss report: $e');
    }
  }

  Future<Map<String, dynamic>?> getReportedContent(String contentId, ContentType contentType) async {
    try {
      String collection;
      switch (contentType) {
        case ContentType.post:
          collection = AppConfig.postsCollection;
          break;
        case ContentType.comment:
          collection = AppConfig.commentsCollection;
          break;
        case ContentType.video:
          collection = AppConfig.videosCollection;
          break;
        case ContentType.tip:
          collection = AppConfig.tipsCollection;
          break;
        case ContentType.user:
          collection = AppConfig.usersCollection;
          break;
      }

      final doc = await _firestore.collection(collection).doc(contentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ================ ADMIN LOGS ================

  Future<void> _logAdminAction({
    required String adminId,
    required AdminActionType actionType,
    required String targetId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get admin name
      final adminDoc = await _firestore.collection(AppConfig.usersCollection).doc(adminId).get();
      final adminName = adminDoc.data()?['username'] ?? 'Unknown Admin';

      final log = AdminActionLog(
        id: '',
        adminId: adminId,
        adminName: adminName,
        actionType: actionType,
        targetId: targetId,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection(AppConfig.adminLogsCollection).add(log.toMap());
    } catch (e) {
      print('Failed to log admin action: $e');
    }
  }

  Stream<List<AdminActionLog>> getAdminLogs({
    String? adminId,
    AdminActionType? actionType,
    int limit = 100,
  }) {
    Query query = _firestore.collection(AppConfig.adminLogsCollection);

    if (adminId != null) {
      query = query.where('adminId', isEqualTo: adminId);
    }

    if (actionType != null) {
      query = query.where('actionType', isEqualTo: actionType.toString().split('.').last);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminActionLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // ================ SYSTEM CONFIGURATION ================

  Future<Map<String, dynamic>> getSystemConfig() async {
    try {
      final doc = await _firestore.collection(AppConfig.systemConfigCollection).doc('config').get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  Future<void> updateSystemConfig(Map<String, dynamic> config, String adminId) async {
    try {
      config['updatedAt'] = FieldValue.serverTimestamp();
      config['updatedBy'] = adminId;

      await _firestore.collection(AppConfig.systemConfigCollection).doc('config').set(config, SetOptions(merge: true));

      await _logAdminAction(
        adminId: adminId,
        actionType: AdminActionType.userSuspended, // We can add a new type for config updates
        targetId: 'system_config',
        description: 'Updated system configuration',
        metadata: config,
      );
    } catch (e) {
      throw Exception('Failed to update system config: $e');
    }
  }

  // ================ BULK OPERATIONS ================

  Future<void> bulkDeleteTips(List<String> tipIds, String adminId) async {
    final batch = _firestore.batch();

    for (final tipId in tipIds) {
      final docRef = _firestore.collection(AppConfig.tipsCollection).doc(tipId);
      batch.delete(docRef);
    }

    await batch.commit();

    await _logAdminAction(
      adminId: adminId,
      actionType: AdminActionType.tipDeleted,
      targetId: 'bulk_operation',
      description: 'Bulk deleted ${tipIds.length} tips',
      metadata: {'tipIds': tipIds},
    );
  }

  Future<void> bulkDeleteVideos(List<String> videoIds, String adminId) async {
    final batch = _firestore.batch();

    for (final videoId in videoIds) {
      final docRef = _firestore.collection(AppConfig.videosCollection).doc(videoId);
      batch.delete(docRef);
    }

    await batch.commit();

    await _logAdminAction(
      adminId: adminId,
      actionType: AdminActionType.videoDeleted,
      targetId: 'bulk_operation',
      description: 'Bulk deleted ${videoIds.length} videos',
      metadata: {'videoIds': videoIds},
    );
  }

  Future<void> bulkUpdateTipCategory(List<String> tipIds, String newCategory, String adminId) async {
    final batch = _firestore.batch();

    for (final tipId in tipIds) {
      final docRef = _firestore.collection(AppConfig.tipsCollection).doc(tipId);
      batch.update(docRef, {
        'category': newCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await _logAdminAction(
      adminId: adminId,
      actionType: AdminActionType.tipUpdated,
      targetId: 'bulk_operation',
      description: 'Bulk updated ${tipIds.length} tips to category: $newCategory',
      metadata: {'tipIds': tipIds, 'newCategory': newCategory},
    );
  }

  // ================ YOUTUBE VIDEO HELPERS ================

  Future<Map<String, dynamic>?> getYouTubeVideoInfo(String youtubeUrl) async {
    try {
      // Extract video ID from YouTube URL
      final videoId = _extractYouTubeVideoId(youtubeUrl);
      if (videoId == null) return null;

      return {
        'youtubeVideoId': videoId,
        'youtubeUrl': youtubeUrl,
        'embedUrl': 'https://www.youtube.com/embed/$videoId',
        'thumbnailUrl': 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
        'isYouTubeVideo': true,
      };
    } catch (e) {
      return null;
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }
}

// Enums for filtering
enum UserFilterType { all, active, suspended, unverified }