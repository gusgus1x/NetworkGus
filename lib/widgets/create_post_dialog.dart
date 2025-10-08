import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/posts_provider.dart';
import '../providers/auth_provider.dart';

class CreatePostDialog extends StatefulWidget {
  final String? groupId;
  const CreatePostDialog({Key? key, this.groupId}) : super(key: key);

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      await context.read<PostsProvider>().createPost(
        content: content,
        userId: currentUser.id,
        userDisplayName: currentUser.displayName,
        username: currentUser.username,
        userProfileImageUrl: currentUser.profileImageUrl,
        isUserVerified: currentUser.isVerified,
        groupId: widget.groupId,
      );
      // รีโหลดโพสต์กลุ่มทันทีหลังโพสต์
      if (widget.groupId != null && widget.groupId!.isNotEmpty) {
        await context.read<PostsProvider>().fetchGroupPosts(widget.groupId!);
      }
    }
    
    if (mounted) {
      Navigator.of(context, rootNavigator: false).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Post',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () {
                    // TODO: Implement image picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Image picker not implemented yet'),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.gif_box),
                  onPressed: () {
                    // TODO: Implement GIF picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('GIF picker not implemented yet'),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.poll),
                  onPressed: () {
                    // TODO: Implement poll creation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Poll creation not implemented yet'),
                      ),
                    );
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isPosting ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}