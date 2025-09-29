import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';

class PostsProvider with ChangeNotifier {
  final PostService _postService = PostService();
  
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  
  // Comments state
  Map<String, List<Comment>> _postComments = {};
  Map<String, bool> _commentsLoading = {};

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  
  // Comment getters
  List<Comment> getCommentsForPost(String postId) => _postComments[postId] ?? [];
  bool isCommentsLoading(String postId) => _commentsLoading[postId] ?? false;

  // Remove mock data - use Firebase instead

  Future<void> fetchPosts({bool refresh = false, String? currentUserId}) async {
    print('PostsProvider: fetchPosts called with userId: $currentUserId'); // Debug
    
    if (refresh) {
      _posts.clear();
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (currentUserId != null) {
        print('PostsProvider: Fetching posts for user: $currentUserId'); // Debug
        // For now, try to get trending posts since feed might be empty
        List<Post> newPosts = [];
        
        try {
          // First try to get feed posts
          newPosts = await _postService.getFeedPosts(currentUserId, limit: 10);
        } catch (e) {
          print('Feed posts error: $e');
        }
        
        // If no feed posts, try trending posts
        if (newPosts.isEmpty) {
          try {
            newPosts = await _postService.getTrendingPosts(limit: 10);
          } catch (e) {
            print('Trending posts error: $e');
          }
        }
        
        print('PostsProvider: Got ${newPosts.length} posts'); // Debug
        
        if (newPosts.isEmpty) {
          _hasMore = false;
        } else {
          _posts.addAll(newPosts);
        }
      } else {
        print('PostsProvider: No user logged in'); // Debug
        // No user logged in, show empty
        _hasMore = false;
      }
    } catch (e) {
      print('Error fetching posts: $e');
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createPost({
    required String content,
    required String userId,
    required String userDisplayName,
    required String username,
    String? userProfileImageUrl,
    bool isUserVerified = false,
    List<String>? imageUrls,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _postService.createPost(
        userId: userId,
        content: content,
        userDisplayName: userDisplayName,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        isUserVerified: isUserVerified,
        imageUrls: imageUrls,
      );

      // Refresh posts to show the new post
      await fetchPosts(refresh: true, currentUserId: userId);
    } catch (e) {
      print('Error creating post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> likePost(String postId, String userId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final wasLiked = post.isLiked;
    
    // Update UI immediately
    _posts[postIndex] = post.copyWith(
      isLiked: !post.isLiked,
      likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    
    notifyListeners();

    try {
      if (wasLiked) {
        await _postService.unlikePost(postId, userId);
      } else {
        await _postService.likePost(postId, userId);
      }
    } catch (e) {
      // Revert on error
      _posts[postIndex] = post;
      notifyListeners();
      print('Error liking post: $e');
    }
  }

  Future<void> bookmarkPost(String postId, String userId) async {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final wasBookmarked = post.isBookmarked;
    
    // Update UI immediately
    _posts[postIndex] = post.copyWith(
      isBookmarked: !post.isBookmarked,
    );
    
    notifyListeners();

    try {
      if (wasBookmarked) {
        await _postService.removeBookmark(postId, userId);
      } else {
        await _postService.bookmarkPost(postId, userId);
      }
    } catch (e) {
      // Revert on error
      _posts[postIndex] = post;
      notifyListeners();
      print('Error bookmarking post: $e');
    }
  }

  Future<void> deletePost(String postId, String userId) async {
    // Remove from UI immediately
    final postToRemove = _posts.firstWhere((post) => post.id == postId);
    _posts.removeWhere((post) => post.id == postId);
    notifyListeners();

    try {
      await _postService.deletePost(postId, userId);
    } catch (e) {
      // Revert on error
      _posts.add(postToRemove);
      notifyListeners();
      print('Error deleting post: $e');
    }
  }

  Post? getPostById(String postId) {
    try {
      return _posts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
  }

  // Comment functionality
  Future<void> loadCommentsForPost(String postId) async {
    print('PostsProvider: Loading comments for post: $postId');
    if (_commentsLoading[postId] == true) {
      print('PostsProvider: Already loading comments for post: $postId');
      return;
    }

    _commentsLoading[postId] = true;
    notifyListeners();

    try {
      final comments = await _postService.getPostComments(postId);
      print('PostsProvider: Loaded ${comments.length} comments for post: $postId');
      _postComments[postId] = comments;
    } catch (e) {
      print('Error loading comments: $e');
      _postComments[postId] = [];
    }

    _commentsLoading[postId] = false;
    notifyListeners();
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
    required String userDisplayName,
    required String username,
    String? userProfileImageUrl,
    bool isUserVerified = false,
  }) async {
    try {
      final commentId = await _postService.addComment(
        postId: postId,
        userId: userId,
        content: content,
        userDisplayName: userDisplayName,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        isUserVerified: isUserVerified,
      );

      // Add comment to local state
      final newComment = Comment(
        id: commentId,
        postId: postId,
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
        userDisplayName: userDisplayName,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        isUserVerified: isUserVerified,
      );

      if (_postComments[postId] == null) {
        _postComments[postId] = [];
      }
      _postComments[postId]!.add(newComment);

      // Update post's comment count
      final postIndex = _posts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = post.copyWith(
          commentsCount: post.commentsCount + 1,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment');
    }
  }

  Future<void> likeComment(String commentId, String postId) async {
    // Find and update comment in local state
    final comments = _postComments[postId];
    if (comments != null) {
      final commentIndex = comments.indexWhere((c) => c.id == commentId);
      if (commentIndex != -1) {
        final comment = comments[commentIndex];
        comments[commentIndex] = comment.copyWith(
          isLiked: !comment.isLiked,
          likesCount: comment.isLiked ? comment.likesCount - 1 : comment.likesCount + 1,
        );
        notifyListeners();
      }
    }

    // TODO: Implement actual API call when comment liking is added to PostService
  }

  void clearCommentsForPost(String postId) {
    _postComments.remove(postId);
    _commentsLoading.remove(postId);
    notifyListeners();
  }
}