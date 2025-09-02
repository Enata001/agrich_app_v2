import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/app_config.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService(this._firestore, this._storage);

  // Users Collection Methods
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection(AppConfig.usersCollection).doc(uid).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _firestore
        .collection(AppConfig.usersCollection)
        .doc(uid)
        .get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection(AppConfig.usersCollection).doc(uid).update({
      ...userData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection(AppConfig.usersCollection).doc(uid).delete();
  }

  // Posts Collection Methods
  Future<QuerySnapshot> getPosts() async {
    return await _firestore
        .collection(AppConfig.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(AppConfig.postsPerPage)
        .get();
  }

  Future<DocumentSnapshot> getPost(String postId) async {
    return await _firestore
        .collection(AppConfig.postsCollection)
        .doc(postId)
        .get();
  }

  Future<DocumentReference> createPost(Map<String, dynamic> postData) async {
    return await _firestore.collection(AppConfig.postsCollection).add({
      ...postData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
      'likedBy': [],
    });
  }

  Future<void> updatePost(String postId, Map<String, dynamic> postData) async {
    await _firestore.collection(AppConfig.postsCollection).doc(postId).update({
      ...postData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection(AppConfig.postsCollection).doc(postId).delete();
  }

  Future<void> likePost(String postId, String userId) async {
    final postRef = _firestore
        .collection(AppConfig.postsCollection)
        .doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);

      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final likesCount = data['likesCount'] as int? ?? 0;

        if (likedBy.contains(userId)) {
          // Unlike
          likedBy.remove(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': likesCount - 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Like
          likedBy.add(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': likesCount + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  // Comments Collection Methods
  Future<QuerySnapshot> getComments(String postId) async {
    return await _firestore
        .collection(AppConfig.postsCollection)
        .doc(postId)
        .collection(AppConfig.commentsCollection)
        .orderBy('createdAt', descending: false)
        .get();
  }

  Future<DocumentReference> addComment(
    String postId,
    Map<String, dynamic> commentData,
  ) async {
    final batch = _firestore.batch();

    // Add comment
    final commentRef = _firestore
        .collection(AppConfig.postsCollection)
        .doc(postId)
        .collection(AppConfig.commentsCollection)
        .doc();

    batch.set(commentRef, {
      ...commentData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update post comments count
    final postRef = _firestore
        .collection(AppConfig.postsCollection)
        .doc(postId);
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return commentRef;
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _firestore.batch();

    // Delete comment
    final commentRef = _firestore
        .collection(AppConfig.postsCollection)
        .doc(postId)
        .collection(AppConfig.commentsCollection)
        .doc(commentId);

    batch.delete(commentRef);

    // Update post comments count
    final postRef = _firestore
        .collection(AppConfig.postsCollection)
        .doc(postId);
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Chat Collection Methods
  Future<QuerySnapshot> getUserChats(String userId) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .get();
  }

  Future<DocumentSnapshot> getChat(String chatId) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .get();
  }

  Future<DocumentReference> createChat(Map<String, dynamic> chatData) async {
    return await _firestore.collection(AppConfig.chatsCollection).add({
      ...chatData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChat(String chatId, Map<String, dynamic> chatData) async {
    await _firestore.collection(AppConfig.chatsCollection).doc(chatId).update({
      ...chatData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChat(String chatId) async {
    await _firestore.collection(AppConfig.chatsCollection).doc(chatId).delete();
  }

  Future<QuerySnapshot> findChatByParticipants(
    List<String> participants,
  ) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();
  }

  // Messages Collection Methods
  Stream<QuerySnapshot> getChatMessagesStream(String chatId) {
    return _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<QuerySnapshot> getChatMessages(String chatId) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .orderBy('createdAt', descending: false)
        .get();
  }

  Future<DocumentReference> addMessage(
    String chatId,
    Map<String, dynamic> messageData,
  ) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .add({...messageData, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateMessage(
    String messageId,
    Map<String, dynamic> messageData,
  ) async {
    // Note: This would require knowing the chat ID to construct the full path
    // For now, we'll implement a simple version
    final messagesQuery = await _firestore
        .collectionGroup(AppConfig.messagesCollection)
        .where(FieldPath.documentId, isEqualTo: messageId)
        .limit(1)
        .get();

    if (messagesQuery.docs.isNotEmpty) {
      await messagesQuery.docs.first.reference.update(messageData);
    }
  }

  Future<QuerySnapshot> getUnreadMessages(String chatId, String userId) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .where('readBy', whereNotIn: [userId])
        .get();
  }

  Future<QuerySnapshot> searchChatMessages(String chatId, String query) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('content')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
  }

  // Videos Collection Methods
  Future<QuerySnapshot> getAllVideos() async {
    return await _firestore
        .collection(AppConfig.videosCollection)
        .orderBy('uploadDate', descending: true)
        .limit(AppConfig.videosPerPage)
        .get();
  }

  Future<QuerySnapshot> getVideosByCategory(String category) async {
    return await _firestore
        .collection(AppConfig.videosCollection)
        .where('category', isEqualTo: category)
        .orderBy('uploadDate', descending: true)
        .limit(AppConfig.videosPerPage)
        .get();
  }

  Future<DocumentSnapshot> getVideo(String videoId) async {
    return await _firestore
        .collection(AppConfig.videosCollection)
        .doc(videoId)
        .get();
  }

  Future<DocumentReference> createVideo(Map<String, dynamic> videoData) async {
    return await _firestore.collection(AppConfig.videosCollection).add({
      ...videoData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'views': 0,
    });
  }

  Future<void> updateVideoViews(String videoId) async {
    await _firestore.collection(AppConfig.videosCollection).doc(videoId).update(
      {
        'views': FieldValue.increment(1),
        'lastViewed': FieldValue.serverTimestamp(),
      },
    );
  }

  // Tips Collection Methods
  Future<QuerySnapshot> getTips() async {
    return await _firestore
        .collection(AppConfig.tipsCollection)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot> getTipsByCategory(String category) async {
    return await _firestore
        .collection(AppConfig.tipsCollection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<DocumentSnapshot> getDailyTip() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final query = await _firestore
        .collection(AppConfig.tipsCollection)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('isDailyTip', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    // Fallback to random tip
    final randomTips = await _firestore
        .collection(AppConfig.tipsCollection)
        .limit(10)
        .get();

    if (randomTips.docs.isNotEmpty) {
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % randomTips.docs.length;
      return randomTips.docs[randomIndex];
    }

    throw Exception('No tips available');
  }

  Future<DocumentReference> createTip(Map<String, dynamic> tipData) async {
    return await _firestore.collection(AppConfig.tipsCollection).add({
      ...tipData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Storage Methods
  Future<String> uploadImage(
    String path,
    String fileName,
    String folder,
  ) async {
    final file = File(path);
    final ref = _storage.ref().child('$folder/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});

    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadPostImage(String imagePath, String postId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$postId.jpg';
    return await uploadImage(imagePath, fileName, AppConfig.postImagesPath);
  }

  Future<String> uploadProfilePicture(String imagePath, String userId) async {
    final fileName = '${userId}_profile.jpg';
    return await uploadImage(
      imagePath,
      fileName,
      AppConfig.profilePicturesPath,
    );
  }

  Future<String> uploadChatImage(String imagePath, String chatId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$chatId.jpg';
    return await uploadImage(imagePath, fileName, 'chat_images');
  }

  Future<String> uploadVideoThumbnail(String imagePath, String videoId) async {
    final fileName = '${videoId}_thumbnail.jpg';
    return await uploadImage(
      imagePath,
      fileName,
      AppConfig.videoThumbnailsPath,
    );
  }

  Future<String> uploadVideo(String videoPath, String videoId) async {
    final file = File(videoPath);
    final fileName = '${videoId}_video.mp4';
    final ref = _storage.ref().child('${AppConfig.videosPath}/$fileName');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});

    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // File might not exist or already deleted
    }
  }

  // Batch Operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final docId = operation['docId'] as String?;
      final data = operation['data'] as Map<String, dynamic>?;

      switch (type) {
        case 'create':
          if (docId != null && data != null) {
            batch.set(_firestore.collection(collection).doc(docId), data);
          }
          break;
        case 'update':
          if (docId != null && data != null) {
            batch.update(_firestore.collection(collection).doc(docId), data);
          }
          break;
        case 'delete':
          if (docId != null) {
            batch.delete(_firestore.collection(collection).doc(docId));
          }
          break;
      }
    }

    await batch.commit();
  }

  // Search Methods
  Future<QuerySnapshot> searchPosts(String query) async {
    return await _firestore
        .collection(AppConfig.postsCollection)
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('content')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
  }

  Future<QuerySnapshot> searchUsers(String query) async {
    return await _firestore
        .collection(AppConfig.usersCollection)
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('username')
        .limit(20)
        .get();
  }

  Future<QuerySnapshot> searchVideos(String query) async {
    return await _firestore
        .collection(AppConfig.videosCollection)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('title')
        .orderBy('uploadDate', descending: true)
        .limit(20)
        .get();
  }

  // Analytics Methods
  Future<void> logUserActivity(
    String userId,
    String activity,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('user_activities').add({
      'userId': userId,
      'activity': activity,
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserLastSeen(String userId) async {
    await _firestore.collection(AppConfig.usersCollection).doc(userId).update({
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  Future<void> setUserOffline(String userId) async {
    await _firestore.collection(AppConfig.usersCollection).doc(userId).update({
      'isOnline': false,
    });
  }

  // Pagination Methods
  Future<QuerySnapshot> getPostsPaginated({
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    Query query = _firestore
        .collection(AppConfig.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  Future<QuerySnapshot> getVideosPaginated({
    String? category,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    Query query = _firestore.collection(AppConfig.videosCollection);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('uploadDate', descending: true).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  // Notification Methods
  Future<void> sendNotification(
    String userId,
    Map<String, dynamic> notificationData,
  ) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': notificationData['type'],
      'title': notificationData['title'],
      'body': notificationData['body'],
      'data': notificationData['data'] ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot> getUserNotifications(String userId) async {
    return await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin Methods
  Future<QuerySnapshot> getReportedContent() async {
    return await _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<void> reportContent({
    required String contentType,
    required String contentId,
    required String reporterId,
    required String reason,
    Map<String, dynamic>? additionalData,
  }) async {
    await _firestore.collection('reports').add({
      'contentType': contentType,
      'contentId': contentId,
      'reporterId': reporterId,
      'reason': reason,
      'additionalData': additionalData ?? {},
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Utility Methods
  Future<bool> documentExists(String collection, String docId) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    return doc.exists;
  }

  Future<int> getCollectionCount(String collection) async {
    final snapshot = await _firestore.collection(collection).count().get();
    return snapshot.count ?? 0;
  }

  Stream<DocumentSnapshot> listenToDocument(String collection, String docId) {
    return _firestore.collection(collection).doc(docId).snapshots();
  }

  Stream<QuerySnapshot> listenToCollection(
    String collection, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (where != null) {
      where.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Backup and Restore Methods
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final userData = <String, dynamic>{};

    // Export user profile
    final userDoc = await getUser(userId);
    if (userDoc.exists) {
      userData['profile'] = userDoc.data();
    }

    // Export user posts
    final postsQuery = await _firestore
        .collection(AppConfig.postsCollection)
        .where('authorId', isEqualTo: userId)
        .get();
    userData['posts'] = postsQuery.docs.map((doc) => doc.data()).toList();

    // Export user comments
    final commentsQuery = await _firestore
        .collectionGroup(AppConfig.commentsCollection)
        .where('authorId', isEqualTo: userId)
        .get();
    userData['comments'] = commentsQuery.docs.map((doc) => doc.data()).toList();

    return userData;
  }

  Future<void> deleteUserData(String userId) async {
    final batch = _firestore.batch();

    // Delete user profile
    batch.delete(_firestore.collection(AppConfig.usersCollection).doc(userId));

    // Delete user posts
    final postsQuery = await _firestore
        .collection(AppConfig.postsCollection)
        .where('authorId', isEqualTo: userId)
        .get();

    for (final doc in postsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete user comments
    final commentsQuery = await _firestore
        .collectionGroup(AppConfig.commentsCollection)
        .where('authorId', isEqualTo: userId)
        .get();

    for (final doc in commentsQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete user chats (remove from participants)
    final chatsQuery = await _firestore
        .collection(AppConfig.chatsCollection)
        .where('participants', arrayContains: userId)
        .get();

    for (final doc in chatsQuery.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      participants.remove(userId);

      if (participants.isEmpty) {
        batch.delete(doc.reference);
      } else {
        batch.update(doc.reference, {'participants': participants});
      }
    }

    await batch.commit();
  }
}
