import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class ChatProvider with ChangeNotifier {
  final Map<String, List<Message>> _messages = {};
  final List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _activeConversationId;

  List<Conversation> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  String? get activeConversationId => _activeConversationId;

  // Mock data for demonstration
  static final List<Conversation> _mockConversations = [
    Conversation(
      id: 'conv_1',
      participantIds: ['1', '2'],
      type: ConversationType.direct,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
      unreadCount: 2,
      participantNames: {'1': 'John Doe', '2': 'Jane Smith'},
      participantAvatars: {'1': null, '2': null},
      lastMessage: Message(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderId: '2',
        content: 'Hey! How are you doing?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ),
    Conversation(
      id: 'conv_2',
      participantIds: ['1', '3'],
      type: ConversationType.direct,
      lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      participantNames: {'1': 'John Doe', '3': 'Alex Johnson'},
      participantAvatars: {'1': null, '3': null},
      lastMessage: Message(
        id: 'msg_2',
        conversationId: 'conv_2',
        senderId: '1',
        content: 'Thanks for your help with the project!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ),
    Conversation(
      id: 'conv_3',
      participantIds: ['1', '2', '3', '4'],
      type: ConversationType.group,
      name: 'Flutter Developers',
      lastActivity: DateTime.now().subtract(const Duration(hours: 5)),
      unreadCount: 1,
      participantNames: {
        '1': 'John Doe',
        '2': 'Jane Smith',
        '3': 'Alex Johnson',
        '4': 'Sarah Wilson'
      },
      participantAvatars: {'1': null, '2': null, '3': null, '4': null},
      lastMessage: Message(
        id: 'msg_3',
        conversationId: 'conv_3',
        senderId: '4',
        content: 'Anyone available for code review?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ),
  ];

  static final Map<String, List<Message>> _mockMessages = {
    'conv_1': [
      Message(
        id: 'msg_1_1',
        conversationId: 'conv_1',
        senderId: '2',
        content: 'Hello John!',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      Message(
        id: 'msg_1_2',
        conversationId: 'conv_1',
        senderId: '1',
        content: 'Hi Jane! How have you been?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
        isRead: true,
      ),
      Message(
        id: 'msg_1_3',
        conversationId: 'conv_1',
        senderId: '2',
        content: 'I\'ve been great! Working on some exciting projects.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: true,
      ),
      Message(
        id: 'msg_1_4',
        conversationId: 'conv_1',
        senderId: '2',
        content: 'Hey! How are you doing?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      Message(
        id: 'msg_1_5',
        conversationId: 'conv_1',
        senderId: '2',
        content: 'Are you free for a quick call later?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: false,
      ),
    ],
    'conv_2': [
      Message(
        id: 'msg_2_1',
        conversationId: 'conv_2',
        senderId: '3',
        content: 'Thanks for helping with the Flutter project!',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      Message(
        id: 'msg_2_2',
        conversationId: 'conv_2',
        senderId: '1',
        content: 'No problem! It was fun working together.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        isRead: true,
      ),
      Message(
        id: 'msg_2_3',
        conversationId: 'conv_2',
        senderId: '1',
        content: 'Thanks for your help with the project!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
    ],
    'conv_3': [
      Message(
        id: 'msg_3_1',
        conversationId: 'conv_3',
        senderId: '2',
        content: 'Hey everyone! Welcome to our Flutter dev group 🚀',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        isRead: true,
      ),
      Message(
        id: 'msg_3_2',
        conversationId: 'conv_3',
        senderId: '3',
        content: 'Thanks for creating this group!',
        timestamp: DateTime.now().subtract(const Duration(hours: 7)),
        isRead: true,
      ),
      Message(
        id: 'msg_3_3',
        conversationId: 'conv_3',
        senderId: '1',
        content: 'Great to be here! Looking forward to collaborating.',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      Message(
        id: 'msg_3_4',
        conversationId: 'conv_3',
        senderId: '4',
        content: 'Anyone available for code review?',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
      ),
    ],
  };

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    _conversations.clear();
    _conversations.addAll(_mockConversations);
    _conversations.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Message>> getMessages(String conversationId) async {
    if (_messages.containsKey(conversationId)) {
      return _messages[conversationId]!;
    }

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    final messages = _mockMessages[conversationId] ?? [];
    _messages[conversationId] = List.from(messages);
    
    return _messages[conversationId]!;
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;

    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: '1', // Current user ID
      content: content.trim(),
      timestamp: DateTime.now(),
      isRead: true,
    );

    // Add to messages list
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(newMessage);

    // Update conversation last message and activity
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        lastMessage: newMessage,
        lastActivity: DateTime.now(),
      );
      
      // Sort conversations by last activity
      _conversations.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    }

    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> markAsRead(String conversationId) async {
    // Mark all messages in conversation as read
    if (_messages.containsKey(conversationId)) {
      for (int i = 0; i < _messages[conversationId]!.length; i++) {
        _messages[conversationId]![i] = _messages[conversationId]![i].copyWith(isRead: true);
      }
    }

    // Update conversation unread count
    final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
        unreadCount: 0,
      );
    }

    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
    if (conversationId != null) {
      markAsRead(conversationId);
    }
    notifyListeners();
  }

  Conversation? getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  int get totalUnreadCount {
    return _conversations.fold(0, (total, conversation) => total + conversation.unreadCount);
  }

  Future<String?> createConversation(List<String> participantIds, {String? groupName}) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    
    final newConversation = Conversation(
      id: conversationId,
      participantIds: participantIds,
      name: groupName ?? '',
      type: participantIds.length > 2 ? ConversationType.group : ConversationType.direct,
      lastActivity: DateTime.now(),
      participantNames: {
        for (String id in participantIds) id: 'User $id'
      },
      participantAvatars: {
        for (String id in participantIds) id: null
      },
    );

    _conversations.insert(0, newConversation);
    _messages[conversationId] = [];

    _isLoading = false;
    notifyListeners();

    return conversationId;
  }

  void clearMessages() {
    _messages.clear();
    _conversations.clear();
    _activeConversationId = null;
    notifyListeners();
  }
}