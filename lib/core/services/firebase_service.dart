import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/app_config.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService(this._firestore, this._storage);


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

  Future<QuerySnapshot> getUserByPhone(String phoneNumber) async {
    return await _firestore
        .collection(AppConfig.usersCollection)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
  }

  Future<QuerySnapshot> getUserByEmail(String email) async {
    return await _firestore
        .collection(AppConfig.usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection(AppConfig.usersCollection).doc(uid).update({
      ...userData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    return _firestore
        .collection(AppConfig.chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> chats = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        // Find the other participant
        final otherUserId = participants.firstWhere(
              (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          // Get other user's details
          final otherUserDoc = await _firestore
              .collection('users')
              .doc(otherUserId)
              .get();

          final otherUserData = otherUserDoc.data() ?? {};

          // Get unread message count
          final unreadCount = await _getUnreadMessageCount(doc.id, userId);

          chats.add({
            'id': doc.id,
            'recipientId': otherUserId,
            'recipientName': otherUserData['displayName'] ?? otherUserData['username'] ?? 'Unknown User',
            'recipientAvatar': otherUserData['photoURL'] ?? otherUserData['profilePictureUrl'],
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageType': data['lastMessageType'] ?? 'text',
            'lastMessageTimestamp': data['lastMessageTimestamp'],
            'lastMessageSenderId': data['lastMessageSenderId'],
            'unreadCount': unreadCount,
            'isOnline': otherUserData['isOnline'] ?? false,
            'lastSeen': otherUserData['lastSeen'],
            'createdAt': data['createdAt'],
          });
        }
      }

      return chats;
    });
  }

  Future<QuerySnapshot> getUserChatsFuture(String userId) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
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
        .add({
      ...messageData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> _getUnreadMessageCount(String chatId, String userId) async {
    try {
      final unreadQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return unreadQuery.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<QuerySnapshot> getUnreadMessages(String chatId, String userId) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
  }

  Future<QuerySnapshot> getComments(String postId) async {
    return await _firestore
        .collection(AppConfig.commentsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .get();
  }

  Future<DocumentReference> addComment(Map<String, dynamic> commentData) async {
    return await _firestore.collection(AppConfig.commentsCollection).add({
      ...commentData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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

  Future<QuerySnapshot> getTipsByCategory(String category) async {
    return await _firestore
        .collection(AppConfig.tipsCollection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot> getAllVideos() async {
    return await _firestore
        .collection(AppConfig.videosCollection)
        .orderBy('uploadDate', descending: true)
        .get();
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection(AppConfig.usersCollection).doc(uid).delete();
  }

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
          likedBy.remove(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': likesCount - 1,
          });
        } else {
          likedBy.add(userId);
          transaction.update(postRef, {
            'likedBy': likedBy,
            'likesCount': likesCount + 1,
          });
        }
      }
    });
  }

  Future<QuerySnapshot> getPostComments(String postId) async {
    return await _firestore
        .collection(AppConfig.commentsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .get();
  }

  Future<DocumentReference> createComment(Map<String, dynamic> commentData) async {
    return await _firestore.collection(AppConfig.commentsCollection).add({
      ...commentData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateComment(String commentId, Map<String, dynamic> commentData) async {
    await _firestore.collection(AppConfig.commentsCollection).doc(commentId).update({
      ...commentData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String commentId) async {
    await _firestore.collection(AppConfig.commentsCollection).doc(commentId).delete();
  }

  Future<QuerySnapshot> getTips() async {
    return await _firestore
        .collection(AppConfig.tipsCollection)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<DocumentSnapshot> getDailyTip() async {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays + 1;

    final snapshot = await _firestore
        .collection(AppConfig.tipsCollection)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final totalTips = snapshot.size;
      final tipIndex = dayOfYear % totalTips;

      final tipsSnapshot = await _firestore
          .collection(AppConfig.tipsCollection)
          .orderBy('createdAt')
          .limit(tipIndex + 1)
          .get();

      return tipsSnapshot.docs.last;
    }

    throw Exception('No tips available');
  }

  Future<QuerySnapshot> getVideos() async {
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
      'uploadDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'views': 0,
      'likes': 0,
    });
  }

  Future<void> updateVideo(String videoId, Map<String, dynamic> videoData) async {
    await _firestore.collection(AppConfig.videosCollection).doc(videoId).update({
      ...videoData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVideo(String videoId) async {
    await _firestore.collection(AppConfig.videosCollection).doc(videoId).delete();
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

  Future<QuerySnapshot> getChatMessages(String chatId) async {
    return await _firestore
        .collection(AppConfig.messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
  }

  Future<DocumentReference> createMessage(Map<String, dynamic> messageData) async {
    return await _firestore.collection(AppConfig.messagesCollection).add({
      ...messageData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMessage(String messageId, Map<String, dynamic> messageData) async {
    await _firestore.collection(AppConfig.messagesCollection).doc(messageId).update({
      ...messageData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot> searchChatMessages(String chatId, String query) async {
    return await _firestore
        .collection(AppConfig.messagesCollection)
        .where('chatId', isEqualTo: chatId)
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('content')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
  }

  Future<QuerySnapshot> findChatByParticipants(List<String> participants) async {
    return await _firestore
        .collection(AppConfig.chatsCollection)
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();
  }

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

  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    final fileName = '${userId}_profile.jpg';
    final ref = _storage.ref().child('${AppConfig.profilePicturesPath}/$fileName');

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});

    return await snapshot.ref.getDownloadURL();
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
      where.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
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

  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();

    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final docId = operation['docId'] as String?;
      final data = operation['data'] as Map<String, dynamic>?;

      switch (type) {
        case 'create':
          if (docId != null) {
            final docRef = _firestore.collection(collection).doc(docId);
            batch.set(docRef, {
              ...?data,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            final docRef = _firestore.collection(collection).doc();
            batch.set(docRef, {
              ...?data,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          break;
        case 'update':
          if (docId != null) {
            final docRef = _firestore.collection(collection).doc(docId);
            batch.update(docRef, {
              ...?data,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          break;
        case 'delete':
          if (docId != null) {
            final docRef = _firestore.collection(collection).doc(docId);
            batch.delete(docRef);
          }
          break;
      }
    }

    await batch.commit();
  }

  Future<DocumentReference> savePost(String userId, String postId) async {
    return await _firestore.collection('saved_posts').add({
      'userId': userId,
      'postId': postId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsavePost(String savedPostId) async {
    await _firestore.collection('saved_posts').doc(savedPostId).delete();
  }

  Future<QuerySnapshot> getSavedPosts(String userId) async {
    return await _firestore
        .collection('saved_posts')
        .where('userId', isEqualTo: userId)
        .get();
  }

  Future<DocumentReference> createNotification(String userId, Map<String, dynamic> notificationData) async {
    return await _firestore
        .collection(AppConfig.usersCollection)
        .doc(userId)
        .collection('notifications')
        .add({
      ...notificationData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUserChatsStream(String userId) {
    return _firestore
        .collection(AppConfig.chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatMessagesStream(String chatId) {
    return _firestore
        .collection(AppConfig.chatsCollection)
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots();
  }


  Future<QuerySnapshot> searchUsersByUsername(String query) async {
    return await _firestore
        .collection(AppConfig.usersCollection)
        .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .limit(10)
        .get();
  }

  Future<QuerySnapshot> searchUsersByDisplayName(String query) async {
    return await _firestore
        .collection(AppConfig.usersCollection)
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
  }

  Future<void> blockUser(String userId, String blockedUserId) async {
    await _firestore
        .collection(AppConfig.usersCollection)
        .doc(userId)
        .collection('blocked')
        .doc(blockedUserId)
        .set({
      'blockedUserId': blockedUserId,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String userId, String blockedUserId) async {
    await _firestore
        .collection(AppConfig.usersCollection)
        .doc(userId)
        .collection('blocked')
        .doc(blockedUserId)
        .delete();
  }

  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    final doc = await _firestore
        .collection(AppConfig.usersCollection)
        .doc(userId)
        .collection('blocked')
        .doc(otherUserId)
        .get();
    return doc.exists;
  }

  Stream<QuerySnapshot> getBlockedUsersStream(String userId) {
    return _firestore
        .collection(AppConfig.usersCollection)
        .doc(userId)
        .collection('blocked')
        .orderBy('blockedAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getTip(String tipId) async {
    return await _firestore.collection(AppConfig.tipsCollection).doc(tipId).get();
  }

  Future<DocumentReference> createTip(Map<String, dynamic> tipData) async {
    return await _firestore.collection(AppConfig.tipsCollection).add({
      ...tipData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTip(String tipId, Map<String, dynamic> tipData) async {
    await _firestore.collection(AppConfig.tipsCollection).doc(tipId).update({
      ...tipData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot> getSavedTips(String userId) async {
    return await _firestore
        .collection('saved_tips')
        .where('userId', isEqualTo: userId)
        .get();
  }

  Future<DocumentReference> saveTip(String userId, String tipId) async {
    return await _firestore.collection('saved_tips').add({
      'userId': userId,
      'tipId': tipId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsaveTip(String savedTipId) async {
    await _firestore.collection('saved_tips').doc(savedTipId).delete();
  }



}