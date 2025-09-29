import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _conversationsCollection = FirebaseFirestore.instance.collection('conversations');
  final CollectionReference _messagesCollection = FirebaseFirestore.instance.collection('messages');

  // Create or get existing conversation
  Future<String> createOrGetConversation({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // Create conversation ID based on user IDs (sorted to ensure consistency)
      final List<String> sortedUserIds = [userId1, userId2]..sort();
      final String conversationId = '${sortedUserIds[0]}_${sortedUserIds[1]}';

      // Check if conversation already exists
      final DocumentSnapshot conversationDoc = await _conversationsCollection.doc(conversationId).get();
      
      if (!conversationDoc.exists) {
        // Create new conversation
        final Conversation conversation = Conversation(
          id: conversationId,
          participantIds: [userId1, userId2],
          lastActivity: DateTime.now(),
          unreadCount: 0,
        );

        await _conversationsCollection.doc(conversationId).set(conversation.toJson());
      }

      return conversationId;
    } catch (e) {
      print('Create conversation error: $e');
      throw Exception('Failed to create conversation');
    }
  }

  // Send message
  Future<String> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? imageUrl,
  }) async {
    try {
      final DocumentReference messageRef = _messagesCollection.doc();
      final DateTime now = DateTime.now();

      final Message message = Message(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        type: type,
        timestamp: now,
        isRead: false,
        metadata: imageUrl != null ? {'imageUrl': imageUrl} : null,
      );

      final WriteBatch batch = _firestore.batch();

      // Add message
      batch.set(messageRef, message.toJson());

      // Update conversation
      final DocumentReference conversationRef = _conversationsCollection.doc(conversationId);
      batch.update(conversationRef, {
        'lastMessage': content,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageSenderId': senderId,
        'unreadCount.$receiverId': FieldValue.increment(1),
        'isActive': true,
      });

      await batch.commit();
      return messageRef.id;
    } catch (e) {
      print('Send message error: $e');
      throw Exception('Failed to send message');
    }
  }

  // Get messages for a conversation
  Stream<List<Message>> getMessages(String conversationId, {int limit = 50}) {
    return _messagesCollection
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get conversations for a user
  Stream<List<Conversation>> getUserConversations(String userId) {
    return _conversationsCollection
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();

      // Get unread messages
      final QuerySnapshot unreadMessages = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark messages as read
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Reset unread count in conversation
      final DocumentReference conversationRef = _conversationsCollection.doc(conversationId);
      batch.update(conversationRef, {
        'unreadCount.$userId': 0,
      });

      await batch.commit();
    } catch (e) {
      print('Mark messages as read error: $e');
      throw Exception('Failed to mark messages as read');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId, String conversationId) async {
    try {
      await _messagesCollection.doc(messageId).delete();

      // Update last message if this was the last message
      final QuerySnapshot lastMessageQuery = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastMessageQuery.docs.isNotEmpty) {
        final Message lastMessage = Message.fromJson(
          lastMessageQuery.docs.first.data() as Map<String, dynamic>
        );

        await _conversationsCollection.doc(conversationId).update({
          'lastMessage': lastMessage.content,
          'lastMessageTime': Timestamp.fromDate(lastMessage.timestamp),
          'lastMessageSenderId': lastMessage.senderId,
        });
      } else {
        // No messages left, set empty values
        await _conversationsCollection.doc(conversationId).update({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
        });
      }
    } catch (e) {
      print('Delete message error: $e');
      throw Exception('Failed to delete message');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId, String userId) async {
    try {
      // Instead of deleting, we'll mark as inactive for the user
      // In a real app, you might want to implement per-user conversation visibility
      await _conversationsCollection.doc(conversationId).update({
        'isActive': false,
      });

      // Optionally delete all messages in the conversation
      final QuerySnapshot messages = await _messagesCollection
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final WriteBatch batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Delete conversation error: $e');
      throw Exception('Failed to delete conversation');
    }
  }

  // Search conversations
  Future<List<Conversation>> searchConversations(String userId, String query) async {
    try {
      // Get user's conversations first
      final QuerySnapshot conversationsQuery = await _conversationsCollection
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      final List<Conversation> conversations = conversationsQuery.docs
          .map((doc) => Conversation.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter conversations that contain the query in last message
      final List<Conversation> filteredConversations = conversations
          .where((conversation) => 
              conversation.lastMessage?.content.toLowerCase().contains(query.toLowerCase()) ?? false)
          .toList();

      return filteredConversations;
    } catch (e) {
      print('Search conversations error: $e');
      throw Exception('Failed to search conversations');
    }
  }

  // Get unread messages count for user
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final QuerySnapshot conversationsQuery = await _conversationsCollection
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnreadCount = 0;
      for (var doc in conversationsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final Map<String, dynamic> unreadCount = data['unreadCount'] ?? {};
        totalUnreadCount += (unreadCount[userId] as int?) ?? 0;
      }

      return totalUnreadCount;
    } catch (e) {
      print('Get unread count error: $e');
      return 0;
    }
  }

  // Get online status (this would typically be implemented with presence system)
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return data['isOnline'] ?? false;
      }
      return false;
    });
  }

  // Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Update online status error: $e');
      throw Exception('Failed to update online status');
    }
  }

  // Get conversation info with user details
  Future<Map<String, dynamic>> getConversationInfo(String conversationId, String currentUserId) async {
    try {
      final DocumentSnapshot conversationDoc = await _conversationsCollection.doc(conversationId).get();
      
      if (!conversationDoc.exists) {
        throw Exception('Conversation not found');
      }

      final Conversation conversation = Conversation.fromJson(
        conversationDoc.data() as Map<String, dynamic>
      );

      // Get other participant's info
      final String otherUserId = conversation.participantIds
          .firstWhere((id) => id != currentUserId);

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();

      Map<String, dynamic> otherUserInfo = {};
      if (userDoc.exists) {
        otherUserInfo = userDoc.data() as Map<String, dynamic>;
      }

      return {
        'conversation': conversation,
        'otherUser': otherUserInfo,
      };
    } catch (e) {
      print('Get conversation info error: $e');
      throw Exception('Failed to get conversation info');
    }
  }
}