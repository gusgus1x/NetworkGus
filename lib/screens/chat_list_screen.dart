import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search not implemented yet')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showNewChatDialog(),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Start a new chat to begin messaging!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => chatProvider.loadConversations(),
            child: ListView.builder(
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  currentUserId: currentUser?.id ?? '1',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: conversation.id,
                          conversationName: conversation.getDisplayName(currentUser?.id ?? '1'),
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showConversationOptions(conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Start Direct Chat'),
              onTap: () {
                Navigator.pop(context);
                _showUserSelectionDialog(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('Create Group Chat'),
              onTap: () {
                Navigator.pop(context);
                _showUserSelectionDialog(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserSelectionDialog(bool isGroup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGroup ? 'Create Group Chat' : 'Start Direct Chat'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              if (isGroup) ...[
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: ListView(
                  children: [
                    _buildUserTile('Jane Smith', 'jane_smith', '2'),
                    _buildUserTile('Alex Johnson', 'alex_codes', '3'),
                    _buildUserTile('Sarah Wilson', 'sarah_dev', '4'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isGroup ? 'Group chat created!' : 'Direct chat started!'),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(String name, String username, String userId) {
    return ListTile(
      leading: UserAvatar(
        imageUrl: null,
        displayName: name,
        radius: 20,
      ),
      title: Text(name),
      subtitle: Text('@$username'),
      trailing: Checkbox(
        value: false,
        onChanged: (value) {
          // TODO: Implement user selection logic
        },
      ),
      onTap: () {
        // TODO: Handle user selection
      },
    );
  }

  void _showConversationOptions(conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conversation.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(conversation.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      conversation.isPinned ? 'Conversation unpinned' : 'Conversation pinned',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                conversation.isMuted ? Icons.notifications : Icons.notifications_off,
              ),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      conversation.isMuted ? 'Conversation unmuted' : 'Conversation muted',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}