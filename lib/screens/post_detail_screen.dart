import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/posts_provider.dart';
import '../providers/auth_provider.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../widgets/user_avatar.dart';


class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Load comments when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postsProvider = context.read<PostsProvider>();
      print('PostDetailScreen: Loading comments for post: ${widget.postId}');
      postsProvider.loadCommentsForPost(widget.postId);
    });
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Post', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<PostsProvider, AuthProvider>(
        builder: (context, postsProvider, authProvider, child) {
          final post = postsProvider.getPostById(widget.postId);
          final comments = postsProvider.getCommentsForPost(widget.postId);
          final isCommentsLoading = postsProvider.isCommentsLoading(widget.postId);
          
          // Ensure comments are loaded
          if (!isCommentsLoading && comments.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              print('PostDetailScreen: Force loading comments');
              postsProvider.loadCommentsForPost(widget.postId);
            });
          }
          
          if (post == null) {
            return const Center(
              child: Text(
                'Post not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post content
                      _buildPostHeader(post),
                      _buildPostContent(post),
                      _buildPostActions(post),
                      
                      const Divider(thickness: 8),
                      
                      // Comments section
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      // Comments list
                      if (isCommentsLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return _buildCommentTile(comments[index]);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              // Comment input
              _buildCommentInput(authProvider.currentUser),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    return ListTile(
      leading: UserAvatar(
        imageUrl: post.userProfileImageUrl,
        displayName: post.userDisplayName,
        radius: 25,
      ),
      title: Row(
        children: [
          Text(
            post.userDisplayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (post.isUserVerified) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.verified,
              color: Colors.blue.shade600,
              size: 16,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${post.username}'),
          Text(
            _formatTimestamp(post.createdAt),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post.content,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
          ),
        
        if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
          Container(
            height: 300,
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 64,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPostActions(Post post) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: post.isLiked ? Colors.red : Colors.grey,
            ),
            onPressed: () {
              final currentUserId = context.read<AuthProvider>().currentUser?.id;
              if (currentUserId != null) {
                context.read<PostsProvider>().likePost(post.id, currentUserId);
              }
            },
          ),
          Text('${post.likesCount}'),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.comment_outlined, color: Colors.grey),
            onPressed: () {
              // Scroll to comment input
            },
          ),
          Text('${post.commentsCount}'),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.grey),
            onPressed: () {
              // TODO: Implement share
            },
          ),
          Text('${post.sharesCount}'),
          const Spacer(),
          IconButton(
            icon: Icon(
              post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: post.isBookmarked ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              final currentUserId = context.read<AuthProvider>().currentUser?.id;
              if (currentUserId != null) {
                context.read<PostsProvider>().bookmarkPost(post.id, currentUserId);
              }
            },
          ),
        ],
      ),
    );
  }



  Widget _buildCommentTile(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            imageUrl: comment.userProfileImageUrl,
            displayName: comment.userDisplayName,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userDisplayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (comment.isUserVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 14,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '@${comment.username}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_formatTimestamp(comment.createdAt)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement comment like
                      },
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: comment.isLiked ? Colors.red : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likesCount}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement reply
                      },
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(user) {
    if (user == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Color(0xFF333333)),
        ),
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user.profileImageUrl,
            displayName: user.displayName,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF333333)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.send,
              color: Colors.blue,
            ),
            onPressed: () {
              _postComment();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    try {
      await context.read<PostsProvider>().addComment(
        postId: widget.postId,
        userId: user.id,
        content: content,
        userDisplayName: user.displayName,
        username: user.username,
        userProfileImageUrl: user.profileImageUrl,
        isUserVerified: user.isVerified,
      );
      
      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment posted!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}