import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/posts_provider.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../widgets/user_avatar.dart';
import '../widgets/post_card.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId; // Made optional - null means current user's profile

  const UserProfileScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  List<Post> _userPosts = [];
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isFollowing = false;
  bool _isFollowingLoading = false;
  String? _actualUserId; // Will be set in initState

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  void _initializeUserId() {
    final currentUser = context.read<AuthProvider>().currentUser;
    _actualUserId = widget.userId ?? currentUser?.id;
    
    if (_actualUserId != null) {
      _loadUserProfile();
      _loadUserPosts();
    } else {
      setState(() {
        _isLoading = false;
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    if (_actualUserId == null) return;
    
    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      
      // If viewing own profile, use current user data
      if (widget.userId == null && currentUser != null) {
        setState(() {
          _user = currentUser;
          _isLoading = false;
        });
        return;
      }
      
      // Otherwise, fetch user data
      final userProvider = context.read<UserProvider>();
      final user = await userProvider.getUserById(_actualUserId!);
      
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        
        // Check if current user is following this user (only for other users)
        if (widget.userId != null) {
          _checkFollowStatus();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _loadUserPosts() async {
    if (_actualUserId == null) return;
    
    try {
      final postsProvider = context.read<PostsProvider>();
      final posts = await postsProvider.getUserPosts(_actualUserId!);
      
      if (mounted) {
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || _actualUserId == null) return;

    try {
      final userProvider = context.read<UserProvider>();
      final isFollowing = await userProvider.isFollowing(currentUser.id, _actualUserId!);
      
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || _user == null) return;

    setState(() {
      _isFollowingLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      
      if (_isFollowing) {
        await userProvider.unfollowUser(currentUser.id, _user!.id);
      } else {
        await userProvider.followUser(currentUser.id, _user!.id);
      }

      setState(() {
        _isFollowing = !_isFollowing;
        if (_user != null) {
          _user = _user!.copyWith(
            followersCount: _isFollowing 
                ? _user!.followersCount + 1
                : _user!.followersCount - 1,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'Following ${_user!.displayName}' : 'Unfollowed ${_user!.displayName}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'}: $e')),
      );
    } finally {
      setState(() {
        _isFollowingLoading = false;
      });
    }
  }

  Future<void> _startChat() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || _user == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create or get existing conversation
      final conversationId = await context.read<ChatProvider>().createOrGetConversation(
        currentUser.id,
        _user!.id,
      );

      Navigator.of(context).pop(); // Close loading dialog

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            conversationName: _user!.displayName,
            targetUserId: _user!.id,
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isOwnProfile = widget.userId == null || currentUser?.id == widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          children: [
            Text(
              _user?.username ?? 'Profile',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            if (_user?.isVerified == true) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.verified,
                color: Colors.blue.shade400,
                size: 18,
              ),
            ],
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: isOwnProfile ? [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              // Navigate to create post
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.menu),
            color: const Color(0xFF2A2A2A),
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthProvider>().logout();
              } else if (value == 'edit') {
                _showEditProfileDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Edit Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ] : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'User not found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadUserProfile();
                    await _loadUserPosts();
                  },
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(isOwnProfile),
                      
                      // Posts Section
                      Expanded(
                        child: _isLoadingPosts
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _userPosts.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_camera_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No posts yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No posts to show.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _userPosts.length,
                                    itemBuilder: (context, index) {
                                      final post = _userPosts[index];
                                      return PostCard(post: post);
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture and stats
          Row(
            children: [
              // Profile picture with Instagram-like border
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _user!.isVerified 
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFE1306C),
                            Color(0xFFFA7E1E),
                          ],
                        )
                      : null,
                  color: _user!.isVerified ? null : Colors.grey.shade600,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF121212),
                  ),
                  child: UserAvatar(
                    imageUrl: _user!.profileImageUrl,
                    displayName: _user!.displayName,
                    radius: 40,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Posts', _user!.postsCount.toString()),
                    _buildStatColumn('Followers', _formatNumber(_user!.followersCount)),
                    _buildStatColumn('Following', _user!.followingCount.toString()),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name and bio
          Text(
            _user!.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _user!.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          if (isOwnProfile) ...[
            // Edit Profile button for own profile
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditProfileDialog(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Edit profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // Share profile
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    minimumSize: const Size(44, 32),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Follow and Message buttons for other users
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isFollowingLoading ? null : _toggleFollow,
                    icon: _isFollowingLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                    label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.grey.shade700 : Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Posts grid tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF333333)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: const Icon(
                      Icons.grid_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    } else {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    if (_user == null) return;
    
    final displayNameController = TextEditingController(text: _user!.displayName);
    final bioController = TextEditingController(text: _user!.bio ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: displayNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Display Name',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Bio',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<AuthProvider>().updateProfile(
                  displayName: displayNameController.text.trim(),
                  bio: bioController.text.trim(),
                );
                Navigator.pop(dialogContext);
                _loadUserProfile(); // Reload profile data
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}