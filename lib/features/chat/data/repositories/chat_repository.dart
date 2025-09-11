import 'dart:async';
import 'dart:io';
import 'package:agrich_app_v2/core/services/local_storage_service.dart';
import 'package:agrich_app_v2/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final FirebaseService _firebaseService;
  final Ref _ref;
  final LocalStorageService _localStorage ;

  ChatRepository(this._firebaseService, this._ref, this._localStorage);


  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) {

        return await getAllUsers();
      }

      final queryLowerCase = query.toLowerCase().trim();


      final usernameResults = await _firebaseService.searchUsersByUsername(queryLowerCase);
      final displayNameResults = await _firebaseService.searchUsersByDisplayName(query);


      final Map<String, Map<String, dynamic>> usersMap = {};


      for (final doc in usernameResults.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] != false) {
            usersMap[doc.id] = _processUserData(doc.id, data);
          }
        } catch (e) {
          print('Error processing username result: $e');
        }
      }


      for (final doc in displayNameResults.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] != false && !usersMap.containsKey(doc.id)) {
            usersMap[doc.id] = _processUserData(doc.id, data);
          }
        } catch (e) {
          print('Error processing display name result: $e');
        }
      }

      return usersMap.values.toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final user = await _ref.read(currentUserProfileProvider.future);
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConfig.usersCollection)
          .where('id',isNotEqualTo: user?.id)
          .orderBy('username')
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _processUserData(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }


  Map<String, dynamic> _processUserData(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      'username': data['username'] ?? '',
      'displayName': data['displayName'] ?? data['username'] ?? 'User',
      'profilePictureUrl': data['profilePictureUrl'] ?? data['photoURL'] ?? '',
      'bio': data['bio'] ?? '',
      'isOnline': data['isOnline'] ?? false,
      'lastSeen': (data['lastSeen'] as Timestamp?)?.toDate(),
      'email': data['email'] ?? '',
      'joinedAt': (data['createdAt'] as Timestamp?)?.toDate(),
    };
  }


  Stream<List<Map<String, dynamic>>> getUserChats(String userId) async* {
    final cachedChats = await getCachedUserChats(userId);
    if (cachedChats.isNotEmpty) {
      yield cachedChats;
    }

    try {
      // Now getUserChatsStream returns enhanced data with recipient info
      final stream = _firebaseService.getUserChatsStream(userId).map((enhancedChats) {
        // The data is already enhanced, just process timestamps
        final chats = enhancedChats.map((chatData) {
          return {
            ...chatData,
            'lastMessageTime': chatData['lastMessageTime'] != null
                ? (chatData['lastMessageTime'] as Timestamp?)?.toDate()
                : null,
            'lastSeen': chatData['lastSeen'] != null
                ? (chatData['lastSeen'] as Timestamp?)?.toDate()
                : null,
            'createdAt': chatData['createdAt'] != null
                ? (chatData['createdAt'] as Timestamp?)?.toDate()
                : null,
            'updatedAt': chatData['updatedAt'] != null
                ? (chatData['updatedAt'] as Timestamp?)?.toDate()
                : null,
          };
        }).toList();

        _localStorage.setCachedUserChats(userId, chats);
        return chats;
      });

      yield* stream;
    } catch (e) {
      print('Error in getUserChats: $e');
      yield cachedChats;
    }
  }
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) async* {
    final cachedMessages = await getCachedMessages(chatId);
    if (cachedMessages.isNotEmpty) {
      yield cachedMessages;
    }

    yield* _firebaseService.getChatMessagesStream(chatId).map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      _localStorage.setCachedMessages(chatId, messages);
      return messages;
    }).handleError((e) {
      return cachedMessages;
    });
  }

// Add cached methods
  Future<List<Map<String, dynamic>>> getCachedUserChats(String userId) async {
    return _localStorage.getCachedUserChats(userId);
  }

  Future<List<Map<String, dynamic>>> getCachedMessages(String chatId) async {
    return _localStorage.getCachedMessages(chatId);
  }

  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    try {
      final chatId = messageData['chatId'] as String;
      final senderId = messageData['senderId'] as String;
      final content = messageData['content'] as String? ?? '';
      final type = messageData['type'] as String? ?? 'text';

      final enhancedMessageData = {
        'chatId': chatId,
        'senderId': senderId,
        'senderName': messageData['senderName'] ?? 'User',
        'senderAvatar': messageData['senderAvatar'] ?? '',
        'content': content,
        'type': type,
        'imageUrl': messageData['imageUrl'] ?? '',
        'isRead': false,
        'readBy': [senderId],
        'deliveredAt': FieldValue.serverTimestamp(),
        'readAt': null,
      };


      await _firebaseService.addMessage(chatId, enhancedMessageData);


      await _firebaseService.updateChat(chatId, {
        'lastMessage': type == 'image' ? '📷 Photo' : content,
        'lastMessageType': type,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });


      await _sendMessageNotification(chatId, senderId, enhancedMessageData);

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }


  Future<String> createOrGetChat(List<String> participantIds, {
    Map<String, dynamic>? recipientData, // Add optional recipient data
  }) async {
    try {
      participantIds.sort();
      final existingChat = await _firebaseService.findChatByParticipants(participantIds);
      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Enhanced chat data with optional recipient info for better initial display
      final chatData = {
        'participants': participantIds,
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'isActive': true,
        // Store recipient data if provided (for faster initial load)
        if (recipientData != null) ...{
          'recipientData': recipientData,
        },
      };

      final chatRef = await _firebaseService.createChat(chatData);
      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }


  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await FirebaseFirestore.instance
          .collection(AppConfig.chatsCollection)
          .doc(chatId)
          .collection(AppConfig.messagesCollection)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }


  Future<String> uploadChatImage(String imagePath, String chatId) async {
    try {
      return await _firebaseService.uploadChatImage(imagePath, chatId);
    } catch (e) {
      print('Error uploading chat image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }


  Future<void> deleteChat(String chatId) async {
    try {
      await _firebaseService.updateChat(chatId, {
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting chat: $e');
      throw Exception('Failed to delete chat: $e');
    }
  }


  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _firebaseService.blockUser(userId, blockedUserId);
    } catch (e) {
      print('Error blocking user: $e');
      throw Exception('Failed to block user: $e');
    }
  }


  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _firebaseService.unblockUser(userId, blockedUserId);
    } catch (e) {
      print('Error unblocking user: $e');
      throw Exception('Failed to unblock user: $e');
    }
  }



  Future<void> sendTypingIndicator(String chatId, String userId, bool isTyping) async {
    try {
      await _firebaseService.sendTypingIndicator(chatId, userId, isTyping);
    } catch (e) {

      print('Failed to send typing indicator: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getTypingIndicators(String chatId, String currentUserId) {
    try {
      return FirebaseFirestore.instance
          .collection(AppConfig.chatsCollection)
          .doc(chatId)
          .collection('typing')
          .where('userId', isNotEqualTo: currentUserId)
          .where('isTyping', isEqualTo: true)
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
    } catch (e) {
      return Stream.value([]);
    }
  }

  Future<void> _sendMessageNotification(
      String chatId,
      String senderId,
      Map<String, dynamic> messageData
      ) async {
    try {

      final chatDoc = await _firebaseService.getChat(chatId);
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final recipientIds = participants.where((id) => id != senderId).toList();


      final senderDoc = await _firebaseService.getUser(senderId);
      final senderName = senderDoc.exists
          ? ((senderDoc.data() as Map<String, dynamic>)['displayName'] ??
          (senderDoc.data() as Map<String, dynamic>)['username'] ?? 'Someone')
          : 'Someone';


      for (final recipientId in recipientIds) {

        final isBlocked = await isUserBlocked(recipientId, senderId);
        if (isBlocked) continue;

        final notificationContent = messageData['type'] == 'image'
            ? 'sent you a photo'
            : messageData['content'];

        await _firebaseService.createNotification(recipientId, {
          'type': 'message',
          'title': senderName,
          'message': notificationContent,
          'data': {
            'chatId': chatId,
            'senderId': senderId,
            'messageId': messageData['id'] ?? '',
          },
          'isRead': false,
        });

        // TODO: Send actual push notification using FCM
        // This would require implementing Firebase Cloud Messaging
      }
    } catch (e) {

      print('Failed to send message notification: $e');
    }
  }


  Future<Map<String, dynamic>?> getChatInfo(String chatId) async {
    try {
      final chatDoc = await _firebaseService.getChat(chatId);

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        return {
          'id': chatDoc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
          'lastMessageTime': (data['lastMessageTime'] as Timestamp?)?.toDate(),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<int> _getUnreadMessageCount(String chatId, String userId) async {
    try {
      final unreadMessages = await _firebaseService.getUnreadMessages(chatId, userId);
      return unreadMessages.docs.length;
    } catch (e) {
      return 0;
    }
  }


  Future<int> _getTotalUnreadMessageCount(String userId) async {
    try {
      int totalUnread = 0;

      final chatsSnapshot = await _firebaseService.getUserChatsFuture(userId);
      for (final chatDoc in chatsSnapshot.docs) {
        final unreadCount = await _getUnreadMessageCount(chatDoc.id, userId);
        totalUnread += unreadCount;
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }


  Future<Map<String, int>> getChatStats(String userId) async {
    try {
      final chatsSnapshot = await _firebaseService.getUserChatsFuture(userId);
      final totalUnreadCount = await _getTotalUnreadMessageCount(userId);

      return {
        'totalChats': chatsSnapshot.docs.length,
        'unreadMessages': totalUnreadCount,
      };
    } catch (e) {
      return {
        'totalChats': 0,
        'unreadMessages': 0,
      };
    }
  }


  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firebaseService.updateUser(userId, {
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {

      print('Failed to update online status: $e');
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      return await _firebaseService.uploadChatImage(imageFile.path, fileName);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }


  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      return await _firebaseService.isUserBlocked(userId, otherUserId);
    } catch (e) {
      return false;
    }
  }
}