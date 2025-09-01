import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../config/app_config.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseService(this._firestore, this._storage);

  // Firestore Operations
  CollectionReference get users => _firestore.collection(AppConfig.usersCollection);
  CollectionReference get posts => _firestore.collection(AppConfig.postsCollection);
  CollectionReference get comments => _firestore.collection(AppConfig.commentsCollection);
  CollectionReference get tips => _firestore.collection(AppConfig.tipsCollection);
  CollectionReference get videos => _firestore.collection(AppConfig.videosCollection);
  CollectionReference get chats => _firestore.collection(AppConfig.chatsCollection);

  // User Operations
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await users.doc(uid).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await users.doc(uid).get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return users.doc(uid).snapshots();
  }

  // Posts Operations
  Future<String> createPost(Map<String, dynamic> postData) async {
    final docRef = await posts.add({
      ...postData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'commentsCount': 0,
    });
    return docRef.id;
  }

  Future<QuerySnapshot> getPosts({
    int limit = AppConfig.postsPerPage,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = posts
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return await query.get();
  }

  Future<DocumentSnapshot> getPost(String postId) async {
    return await posts.doc(postId).get();
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await posts.doc(postId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    await posts.doc(postId).delete();
  }

  Future<void> likePost(String postId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final postRef = posts.doc(postId);
      final postDoc = await transaction.get(postRef);

      if (!postDoc.exists) return;

      final data = postDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        likedBy.add(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  // Comments Operations
  Future<String> addComment(String postId, Map<String, dynamic> commentData) async {
    final batch = _firestore.batch();

    // Add comment
    final commentRef = comments.doc();
    batch.set(commentRef, {
      ...commentData,
      'postId': postId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update post comments count
    final postRef = posts.doc(postId);
    batch.update(postRef, {
      'commentsCount': FieldValue.increment(1),
    });

    await batch.commit();
    return commentRef.id;
  }

  Future<QuerySnapshot> getComments(String postId) async {
    return await comments
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .get();
  }

  // Videos Operations
  Future<QuerySnapshot> getVideosByCategory(String category) async {
    return await videos
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot> getAllVideos() async {
    return await videos.orderBy('createdAt', descending: true).get();
  }

  // Tips Operations
  Future<DocumentSnapshot> getTodaysTip() async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return await tips.doc(dateKey).get();
  }

  Future<QuerySnapshot> getAllTips() async {
    return await tips.orderBy('date', descending: true).get();
  }

  // Chat Operations
  Future<String> createChat(List<String> participants) async {
    final docRef = await chats.add({
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
    });
    return docRef.id;
  }

  Future<QuerySnapshot> getUserChats(String userId) async {
    return await chats
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .get();
  }

  Future<String> sendMessage(String chatId, Map<String, dynamic> messageData) async {
    final batch = _firestore.batch();

    // Add message to subcollection
    final messageRef = chats.doc(chatId).collection(AppConfig.messagesCollection).doc();
    batch.set(messageRef, {
      ...messageData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update chat with last message
    final chatRef = chats.doc(chatId);
    batch.update(chatRef, {
      'lastMessage': messageData['content'],
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return messageRef.id;
  }

  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return chats
        .doc(chatId)
        .collection(AppConfig.messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Storage Operations
  Future<String> uploadFile(File file, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfilePicture(File file, String userId) async {
    final path = '${AppConfig.profilePicturesPath}/$userId.jpg';
    return await uploadFile(file, path);
  }

  Future<String> uploadPostImage(File file, String postId) async {
    final path = '${AppConfig.postImagesPath}/$postId.jpg';
    return await uploadFile(file, path);
  }

  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  // Batch Operations
  WriteBatch batch() {
    return _firestore.batch();
  }

  Future<T> runTransaction<T>(TransactionHandler<T> updateFunction) {
    return _firestore.runTransaction<T>(updateFunction);
  }
}