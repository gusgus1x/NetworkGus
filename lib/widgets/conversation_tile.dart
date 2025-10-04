import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../providers/user_provider.dart';
import 'user_avatar.dart';

class ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  String? _displayName;
  String? _displayImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.conversation.type == ConversationType.group) {
      setState(() {
        _displayName = widget.conversation.name.isNotEmpty 
            ? widget.conversation.name 
            : 'Group Chat';
        _displayImage = widget.conversation.imageUrl;
      });
      return;
    }

    // For direct messages, get the other participant's info
    final otherParticipantId = widget.conversation.participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => widget.currentUserId,
    );

    // First try to get from conversation data
    String? name = widget.conversation.participantNames[otherParticipantId];
    String? image = widget.conversation.participantAvatars[otherParticipantId];

    // If not available, fetch from UserProvider
    if (name == null || name.isEmpty || name == 'Unknown User') {
      try {
        final userProvider = context.read<UserProvider>();
        final user = await userProvider.getUserById(otherParticipantId);
        name = user?.displayName ?? 'User ${otherParticipantId.substring(0, 8)}...';
        image = user?.profileImageUrl;
      } catch (e) {
        name = 'User ${otherParticipantId.substring(0, 8)}...';
      }
    }

    if (mounted) {
      setState(() {
        _displayName = name;
        _displayImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName ?? 'Loading...';
    final displayImage = _displayImage;
    final lastMessage = widget.conversation.lastMessage;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          UserAvatar(
            imageUrl: displayImage,
            displayName: displayName,
            radius: 28,
          ),
          if (widget.conversation.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    widget.conversation.unreadCount > 99 
                        ? '99+' 
                        : widget.conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: widget.conversation.unreadCount > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.conversation.isPinned)
            Icon(
              Icons.push_pin,
              size: 16,
              color: Colors.grey.shade600,
            ),
          if (widget.conversation.isMuted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.volume_off,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
      subtitle: lastMessage != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (lastMessage.senderId == widget.currentUserId)
                      Icon(
                        lastMessage.isRead ? Icons.done_all : Icons.done,
                        size: 16,
                        color: lastMessage.isRead 
                            ? Colors.blue.shade600 
                            : Colors.grey.shade600,
                      ),
                    if (lastMessage.senderId == widget.currentUserId)
                      const SizedBox(width: 4),
                    if (widget.conversation.type == ConversationType.group && 
                        lastMessage.senderId != widget.currentUserId)
                      Text(
                        '${_getSenderName(lastMessage.senderId)}: ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _getMessagePreview(lastMessage),
                        style: TextStyle(
                          color: widget.conversation.unreadCount > 0 
                              ? Colors.black87 
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: widget.conversation.unreadCount > 0 
                              ? FontWeight.w500 
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTimestamp(widget.conversation.lastActivity),
            style: TextStyle(
              color: widget.conversation.unreadCount > 0 
                  ? Colors.blue.shade600 
                  : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: widget.conversation.unreadCount > 0 
                  ? FontWeight.bold 
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }

  String _getSenderName(String senderId) {
    return widget.conversation.participantNames[senderId] ?? 'Unknown';
  }

  String _getMessagePreview(Message lastMessage) {
    switch (lastMessage.type) {
      case MessageType.text:
        return lastMessage.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 File';
      case MessageType.emoji:
        return lastMessage.content;
      case MessageType.system:
        return lastMessage.content;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}