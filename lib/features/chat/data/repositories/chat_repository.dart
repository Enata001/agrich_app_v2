import 'dart:async';
import '../../../../core/services/firebase_service.dart';


class ChatRepository {
  final FirebaseService _firebaseService;

  ChatRepository(this._firebaseService);

  // Get user's chats
  Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      final snapshot = await _firebaseService.getUserChats(userId);
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

          chats.add({
            'id': doc.id,
            'recipientId': otherParticipant,
            'recipientName': userData['username'] ?? 'Unknown User',
            'recipientAvatar': userData['profilePictureUrl'] ?? '',
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': data['lastMessageTime'],
            'lastMessageSenderId': data['lastMessageSenderId'] ?? '',
            'unreadCount': _getUnreadCount(data, userId),
            'isOnline': userData['isOnline'] ?? false,
            'participants': participants,
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
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
    } catch (e) {
      return [];
    }
  }

  // Get chat messages stream
  Stream<List<Map<String, dynamic>>> getChatMessagesStream(String chatId) {
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
            'type': data['type'] ?? 'text',
            'imageUrl': data['imageUrl'] ?? '',
            'createdAt': data['createdAt'],
            'isRead': data['isRead'] ?? false,
            'readBy': List<String>.from(data['readBy'] ?? []),
          });
        }

        // Sort by creation time (newest last)
        messages.sort((a, b) {
          final timeA = a['createdAt'] as DateTime?;
          final timeB = b['createdAt'] as DateTime?;
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

  // Send message
  Future<void> sendMessage(String chatId, Map<String, dynamic> messageData) async {
    try {
      final now = DateTime.now();
      final message = {
        ...messageData,
        'createdAt': now,
        'isRead': false,
        'readBy': [messageData['senderId']], // Sender has read it
      };

      // Add message to chat
      await _firebaseService.addMessage(chatId, message);

      // Update chat's last message info
      await _firebaseService.updateChat(chatId, {
        'lastMessage': messageData['content'],
        'lastMessageTime': now,
        'lastMessageSenderId': messageData['senderId'],
        'updatedAt': now,
      });

      // Update unread counts for participants
      await _updateUnreadCounts(chatId, messageData['senderId']);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Create or get existing chat
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    try {
      // Check if chat already exists
      final existingChat = await _findExistingChat(currentUserId, otherUserId);
      if (existingChat != null) {
        return existingChat;
      }

      // Create new chat
      final participants = [currentUserId, otherUserId];
      participants.sort(); // Ensure consistent ordering

      final chatData = {
        'participants': participants,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'lastMessage': '',
        'lastMessageTime': null,
        'lastMessageSenderId': '',
        'unreadCounts': {
          currentUserId: 0,
          otherUserId: 0,
        },
      };

      final chatRef = await _firebaseService.createChat(chatData);
      return chatRef.id;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await _firebaseService.getUnreadMessages(chatId, userId);

      for (final doc in unreadMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final readBy = List<String>.from(data['readBy'] ?? []);

        if (!readBy.contains(userId)) {
          readBy.add(userId);
          await _firebaseService.updateMessage(doc.id, {
            'readBy': readBy,
            'isRead': readBy.length >= 2, // Both participants have read
          });
        }
      }

      // Reset unread count for this user
      await _firebaseService.updateChat(chatId, {
        'unreadCounts.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat
      final messages = await _firebaseService.getChatMessages(chatId);
      for (final doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete the chat document
      await _firebaseService.deleteChat(chatId);
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Send image message
  Future<void> sendImageMessage(
      String chatId,
      String senderId,
      String senderName,
      String imagePath,
      ) async {
    try {
      // Upload image to Firebase Storage
      final imageUrl = await _firebaseService.uploadChatImage(imagePath, chatId);

      // Send message with image
      await sendMessage(chatId, {
        'content': 'Photo',
        'senderId': senderId,
        'senderName': senderName,
        'type': 'image',
        'imageUrl': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }

  // Search messages in chat
  Future<List<Map<String, dynamic>>> searchMessages(String chatId, String query) async {
    try {
      final messages = await _firebaseService.searchChatMessages(chatId, query);
      final results = <Map<String, dynamic>>[];

      for (final doc in messages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        results.add({
          'id': doc.id,
          'content': data['content'] ?? '',
          'senderId': data['senderId'] ?? '',
          'senderName': data['senderName'] ?? '',
          'type': data['type'] ?? 'text',
          'createdAt': data['createdAt'],
        });
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  // Private helper methods
  Future<String?> _findExistingChat(String user1, String user2) async {
    try {
      final participants = [user1, user2];
      participants.sort();

      final chats = await _firebaseService.findChatByParticipants(participants);
      return chats.docs.isNotEmpty ? chats.docs.first.id : null;
    } catch (e) {
      return null;
    }
  }

  int _getUnreadCount(Map<String, dynamic> chatData, String userId) {
    final unreadCounts = chatData['unreadCounts'] as Map<String, dynamic>? ?? {};
    return unreadCounts[userId] as int? ?? 0;
  }

  Future<void> _updateUnreadCounts(String chatId, String senderId) async {
    try {
      final chatDoc = await _firebaseService.getChat(chatId);
      final chatData = chatDoc.data() as Map<String, dynamic>? ?? {};
      final participants = List<String>.from(chatData['participants'] ?? []);
      final unreadCounts = Map<String, dynamic>.from(chatData['unreadCounts'] ?? {});

      // Increment unread count for all participants except sender
      for (final participantId in participants) {
        if (participantId != senderId) {
          unreadCounts[participantId] = (unreadCounts[participantId] as int? ?? 0) + 1;
        }
      }

      await _firebaseService.updateChat(chatId, {'unreadCounts': unreadCounts});
    } catch (e) {
      // Ignore errors in updating unread counts
    }
  }
}