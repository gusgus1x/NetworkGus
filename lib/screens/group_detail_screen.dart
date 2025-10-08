import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_model.dart';
import '../providers/posts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_dialog.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;
  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    final isOwner = currentUserId == group.ownerId;
    // โหลดโพสต์กลุ่มเมื่อเปิดหน้ากลุ่ม
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostsProvider>(context, listen: false).fetchGroupPosts(group.id);
    });
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            actions: isOwner
                ? [
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.white),
                      tooltip: 'Delete Group',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Delete Group'),
                            content: Text('Are you sure you want to delete this group? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () => Navigator.of(ctx).pop(false),
                              ),
                              ElevatedButton(
                                child: Text('Delete'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.of(ctx).pop(true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await Provider.of<GroupProvider>(context, listen: false).deleteGroup(group.id);
                          Navigator.of(context).pop();
                        }
                      },
                    )
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.group, color: Color(0xFF6C5CE7), size: 40),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  group.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF6C5CE7)),
                  const SizedBox(width: 6),
                  Text('${group.members.length} members', style: TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: Icon(Icons.add),
                    label: Text(group.members.contains('currentUserId') ? 'Leave Group' : 'Join Group'),
                    onPressed: () {
                      // TODO: Join/Leave group logic
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Posts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: Icon(Icons.edit),
                    label: Text('Create Post'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CreatePostDialog(groupId: group.id),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Consumer<PostsProvider>(
            builder: (context, postsProvider, child) {
              final groupPosts = postsProvider.groupPosts;
              if (groupPosts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No posts in this group yet', style: TextStyle(color: Colors.grey))),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = groupPosts[index];
                    return PostCard(post: post);
                  },
                  childCount: groupPosts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
