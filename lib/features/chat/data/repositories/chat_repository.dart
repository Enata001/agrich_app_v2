// lib/features/chat/data/repositories/chat_repository.dart

import 'dart:async';
import 'dart:io';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/config/app_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository {
  final FirebaseService _firebaseService;

  ChatRepository(this._firebaseService);

  // Get user's chats - ENHANCED with real-time updates
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) {
    try {
      return _firebaseService.getUserChatsStream(userId).asyncMap((snapshot) async {
        final chats = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final participants = List<String>.from(data['participants'] ?? []);

          // Get the other participant (not current user)
          final otherParticipant = participants.firstWhere(
                (id) => id != userId,
            orElse: () => '',
          );

          if (otherParticipant.isNotEmpty) {
            // Get other user's profile
            final userDoc = await _firebaseService.getUser(otherParticipant);
            final userData = userDoc.data() as Map<String, dynamic>? ?? {};

            // Get unread message count
            final unreadCount = await _getUnreadMessageCount(doc.id, userId);

            chats.add({
              'id': doc.id,
              'recipientId': otherParticipant,
              'recipientName': userData['username'] ?? userData['displayName'] ?? 'Unknown User',
              'recipientAvatar': userData['profilePictureUrl'] ?? userData['photoURL'] ?? '',
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': (data['lastMessageTime'] as Timestamp?)?.toDate(),
              'lastMessageSenderId': data['lastMessageSenderId'] ?? '',
              'unreadCount': unreadCount,
              'isOnline': userData['isOnline'] ?? false,
              'lastSeen': (userData['lastSeen'] as Timestamp?)?.toDate(),
              'participants': participants,
              'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
              'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate(),
            });
          }
        }

        // Sort by last message time
        chats.sort((a, b) {
          final timeA = a['lastMessageTime'] as DateTime?;
          final timeB = b['lastMessageTime'] as DateTime?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA);
        });

        return chats;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Get chat messages stream - ENHANCED implementation
  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    try {
      return _firebaseService.getChatMessagesStream(chatId).map((snapshot) {
        final messages = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          messages.add({
            'id': doc.id,
            'content': data['content'] ?? '',
            'senderId': data['senderId'] ?? '',
            'senderName': data['senderName'] ?? '',
            'senderAvatar': data['senderAvatar'] ?? '',
            'type': data['type'] ?? 'text',
            'imageUrl': data['imageUrl'] ?? '',
            'timestamp': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                DateTime.now().toIso8601String(),
            'isRead': data['isRead'] ?? false,
            'readBy': List<String>.from(data['readBy'] ?? []),
            'deliveredAt': (data['deliveredAt'] as Timestamp?)?.toDate(),
            'readAt': (data['readAt'] as Timestamp?)?.toDate(),
          });
        }

        // Sort by creation time (newest last for chat display)
        messages.sort((a, b) {
          final timeA = DateTime.tryParse(a['timestamp'] ?? '');
          final timeB = DateTime.tryParse(b['timestamp'] ?? '');
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return -1;
          if (timeB == null) return 1;
          return timeA.compareTo(timeB);
        });

        return messages;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Send message - ENHANCED with better error handling
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
        'readBy': [senderId], // Sender has read it
        'deliveredAt': FieldValue.serverTimestamp(),
        'readAt': null,
      };

      // Add message to chat
      await _firebaseService.addMessage(chatId, enhancedMessageData);

      // Update chat's last message info
      await _firebaseService.updateChat(chatId, {
        'lastMessage': type == 'image' ? '📷 Photo' : content,
        'lastMessageType': type,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });

      // Send notification to other participants
      await _sendMessageNotification(chatId, senderId, enhancedMessageData);

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Upload image for chat - ENHANCED with proper error handling
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      return await _firebaseService.uploadChatImage(imageFile.path, fileName);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create or get existing chat - ENHANCED implementation
  Future<String> createOrGetChat(List<String> participantIds) async {
    try {
      // Sort participant IDs for consistent ordering
      participantIds.sort();

      // Check if chat already exists using existing method
      final existingChat = await _firebaseService.findChatByParticipants(participantIds);
      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chatData = {
        'participants': participantIds,
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'isActive': true,
      };

      final chatRef = await _firebaseService.createChat(chatData);
      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Mark messages as read - ENHANCED implementation
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await _firebaseService.getUnreadMessages(chatId, userId);

      final batch = FirebaseFirestore.instance.batch();
      final readTimestamp = FieldValue.serverTimestamp();

      for (final doc in unreadMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final readBy = List<String>.from(data['readBy'] ?? []);

        if (!readBy.contains(userId)) {
          readBy.add(userId);

          batch.update(doc.reference, {
            'readBy': readBy,
            'isRead': readBy.length >= 2, // Both participants have read
            'readAt': readTimestamp,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<void> sendTypingIndicator(String chatId, String userId, bool isTyping) async {
    try {
      await _firebaseService.sendTypingIndicator(chatId, userId, isTyping);
    } catch (e) {
      // Typing indicator failure shouldn't block the app
      print('Failed to send typing indicator: $e');
    }
  }
  // Get typing indicators - NEW IMPLEMENTATION
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

  // Delete chat - ENHANCED implementation
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat
      final messages = await _firebaseService.getChatMessages(chatId);
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in messages.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Delete image from storage if exists
        if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty) {
          try {
            await _firebaseService.deleteFile(data['imageUrl']);
          } catch (e) {
            // Image deletion failed, continue with message deletion
          }
        }

        batch.delete(doc.reference);
      }

      // Delete typing indicators
      final typingSnapshot = await FirebaseFirestore.instance
          .collection(AppConfig.chatsCollection)
          .doc(chatId)
          .collection('typing')
          .get();

      for (final doc in typingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete the chat document
      await _firebaseService.deleteChat(chatId);
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Block/Unblock user - NEW IMPLEMENTATION
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _firebaseService.blockUser(userId, blockedUserId);

      // Also delete any existing chats between these users
      final chats = await _firebaseService.getUserChatsFuture(userId);
      for (final chatDoc in chats.docs) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(blockedUserId)) {
          await deleteChat(chatDoc.id);
        }
      }
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _firebaseService.unblockUser(userId, blockedUserId);
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  // Check if user is blocked - NEW IMPLEMENTATION
  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      return await _firebaseService.isUserBlocked(userId, otherUserId);
    } catch (e) {
      return false;
    }
  }

  // Get blocked users - NEW IMPLEMENTATION
  Stream<List<Map<String, dynamic>>> getBlockedUsers(String userId) {
    try {
      return _firebaseService.getBlockedUsersStream(userId).asyncMap((snapshot) async {
        final blockedUsers = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final blockedUserId = data['blockedUserId'] as String;

          try {
            final userDoc = await _firebaseService.getUser(blockedUserId);
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              blockedUsers.add({
                'id': blockedUserId,
                'displayName': userData['username'] ?? userData['displayName'] ?? 'Unknown User',
                'photoURL': userData['profilePictureUrl'] ?? userData['photoURL'] ?? '',
                'blockedAt': (data['blockedAt'] as Timestamp?)?.toDate(),
              });
            }
          } catch (e) {
            // Skip users that can't be loaded
          }
        }

        return blockedUsers;
      });
    } catch (e) {
      return Stream.value([]);
    }
  }

  // Search users for new chats - NEW IMPLEMENTATION
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      // Search by username
      final usernameResults = await _firebaseService.searchUsersByUsername(query);

      // Search by display name
      final displayNameResults = await _firebaseService.searchUsersByDisplayName(query);

      // Combine and deduplicate results
      final Map<String, Map<String, dynamic>> usersMap = {};

      for (final doc in [...usernameResults.docs, ...displayNameResults.docs]) {
        final data = doc.data() as Map<String, dynamic>;
        usersMap[doc.id] = {
          'id': doc.id,
          'username': data['username'] ?? '',
          'displayName': data['displayName'] ?? data['username'] ?? 'User',
          'photoURL': data['profilePictureUrl'] ?? data['photoURL'] ?? '',
          'bio': data['bio'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': (data['lastSeen'] as Timestamp?)?.toDate(),
        };
      }

      return usersMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  // Get chat info - NEW IMPLEMENTATION
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

  // Get chat statistics - NEW IMPLEMENTATION
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

  // Update user online status - NEW IMPLEMENTATION
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firebaseService.updateUser(userId, {
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Online status update failure shouldn't block the app
      print('Failed to update online status: $e');
    }
  }

  // Helper method to get unread message count for a specific chat
  Future<int> _getUnreadMessageCount(String chatId, String userId) async {
    try {
      final unreadMessages = await _firebaseService.getUnreadMessages(chatId, userId);
      return unreadMessages.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Helper method to get total unread message count across all chats
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

  // Helper method to send push notifications for new messages
  Future<void> _sendMessageNotification(
      String chatId,
      String senderId,
      Map<String, dynamic> messageData
      ) async {
    try {
      // Get chat participants
      final chatDoc = await _firebaseService.getChat(chatId);
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final recipientIds = participants.where((id) => id != senderId).toList();

      // Get sender info
      final senderDoc = await _firebaseService.getUser(senderId);
      final senderName = senderDoc.exists
          ? ((senderDoc.data() as Map<String, dynamic>)['displayName'] ??
          (senderDoc.data() as Map<String, dynamic>)['username'] ?? 'Someone')
          : 'Someone';

      // Create notification for each recipient
      for (final recipientId in recipientIds) {
        // Check if recipient has blocked the sender
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
      // Notification failure shouldn't block message sending
      print('Failed to send message notification: $e');
    }
  }
}