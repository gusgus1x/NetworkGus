import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'user_avatar.dart';

class ConversationTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final displayName = conversation.getDisplayName(currentUserId);
    final displayImage = conversation.getDisplayImage(currentUserId);
    final lastMessage = conversation.lastMessage;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          UserAvatar(
            imageUrl: displayImage,
            displayName: displayName,
            radius: 28,
          ),
          if (conversation.unreadCount > 0)
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
                    conversation.unreadCount > 99 
                        ? '99+' 
                        : conversation.unreadCount.toString(),
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
                fontWeight: conversation.unreadCount > 0 
                    ? FontWeight.bold 
                    : FontWeight.normal,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.isPinned)
            Icon(
              Icons.push_pin,
              size: 16,
              color: Colors.grey.shade600,
            ),
          if (conversation.isMuted)
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
                    if (lastMessage.senderId == currentUserId)
                      Icon(
                        lastMessage.isRead ? Icons.done_all : Icons.done,
                        size: 16,
                        color: lastMessage.isRead 
                            ? Colors.blue.shade600 
                            : Colors.grey.shade600,
                      ),
                    if (lastMessage.senderId == currentUserId)
                      const SizedBox(width: 4),
                    if (conversation.type == ConversationType.group && 
                        lastMessage.senderId != currentUserId)
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
                          color: conversation.unreadCount > 0 
                              ? Colors.black87 
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: conversation.unreadCount > 0 
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
            _formatTimestamp(conversation.lastActivity),
            style: TextStyle(
              color: conversation.unreadCount > 0 
                  ? Colors.blue.shade600 
                  : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: conversation.unreadCount > 0 
                  ? FontWeight.bold 
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _getSenderName(String senderId) {
    return conversation.participantNames[senderId] ?? 'Unknown';
  }

  String _getMessagePreview(lastMessage) {
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
    return lastMessage.content; // fallback
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