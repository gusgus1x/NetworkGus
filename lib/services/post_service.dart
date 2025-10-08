import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _postsCollection = FirebaseFirestore.instance.collection('posts');

  // Create a new post
  Future<String> createPost({
    required String userId,
    required String content,
    required String userDisplayName,
    required String username,
    String? userProfileImageUrl,
    bool isUserVerified = false,
    List<File>? imageFiles,
    List<String>? imageUrls,
    String? groupId,
  }) async {
    try {
      List<String> uploadedImageUrls = [];

      // Upload images if provided
      if (imageFiles != null && imageFiles.isNotEmpty) {
        uploadedImageUrls = await _uploadPostImages(imageFiles);
      } else if (imageUrls != null) {
        uploadedImageUrls = imageUrls;
      }

      // Create post document
      final DocumentReference postRef = _postsCollection.doc();
      final Post post = Post(
        id: postRef.id,
        userId: userId,
        content: content,
        imageUrls: uploadedImageUrls.isNotEmpty ? uploadedImageUrls : null,
        createdAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        isLiked: false,
        isBookmarked: false,
        userDisplayName: userDisplayName,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        isUserVerified: isUserVerified,
        groupId: groupId,
      );

      await postRef.set(post.toJson());

      // Update user's posts count
      await _firestore.collection('users').doc(userId).update({
        'postsCount': FieldValue.increment(1),
      });

      // ถ้าเป็นโพสต์ในกลุ่ม ให้เพิ่ม postId เข้า group.postIds
      if (groupId != null && groupId.isNotEmpty) {
        await _firestore.collection('groups').doc(groupId).update({
          'postIds': FieldValue.arrayUnion([postRef.id]),
        });
      }

      return postRef.id;
    } catch (e) {
      print('Create post error: $e');
      throw Exception('Failed to create post');
    }
  }

  // Upload post images to Firebase Storage
  Future<List<String>> _uploadPostImages(List<File> imageFiles) async {
    try {
      final List<String> downloadUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final Reference ref = _storage.ref().child('posts').child(fileName);
        
        final UploadTask uploadTask = ref.putFile(imageFiles[i]);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        downloadUrls.add(downloadUrl);
      }
      
      return downloadUrls;
    } catch (e) {
      print('Upload images error: $e');
      throw Exception('Failed to upload images');
    }
  }

  // Get posts feed stream (real-time posts from followed users)
  Stream<List<Post>> getFeedPostsStream(String currentUserId, {int limit = 20}) {
    try {
      // Get all posts with reasonable limit
      return _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .asyncMap((snapshot) async {
        print('PostService: Stream received ${snapshot.docs.length} documents');
        final List<Post> posts = [];

        for (var doc in snapshot.docs) {
          final post = Post.fromJson(doc.data() as Map<String, dynamic>);
          
          // Check if current user liked/bookmarked this post
          final bool isLiked = await _isPostLikedByUser(post.id, currentUserId);
          final bool isBookmarked = await _isPostBookmarkedByUser(post.id, currentUserId);
          
          posts.add(post.copyWith(isLiked: isLiked, isBookmarked: isBookmarked));
        }

        print('PostService: Returning ${posts.length} posts from stream');
        return posts;
      });
    } catch (e) {
      print('Get feed posts stream error: $e');
      throw Exception('Failed to get feed posts stream');
    }
  }

  // Keep the original method for compatibility
  Future<List<Post>> getFeedPosts(String currentUserId, {DocumentSnapshot? lastDocument, int limit = 10}) async {
    try {
      // Get following list
      final QuerySnapshot followingQuery = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .get();

      final List<String> followingIds = followingQuery.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String)
          .toList();

      // Add current user to see their own posts
      followingIds.add(currentUserId);

      Query query;
      
      if (followingIds.length == 1) {
        // Only current user, get all posts
        query = _postsCollection
            .orderBy('createdAt', descending: true)
            .limit(limit);
      } else {
        // Query posts from followed users
        query = _postsCollection
            .where('userId', whereIn: followingIds)
            .orderBy('createdAt', descending: true)
            .limit(limit);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot querySnapshot = await query.get();
      final List<Post> posts = [];

      for (var doc in querySnapshot.docs) {
        final post = Post.fromJson(doc.data() as Map<String, dynamic>);
        
        // Check if current user liked this post
        final bool isLiked = await _isPostLikedByUser(post.id, currentUserId);
        final bool isBookmarked = await _isPostBookmarkedByUser(post.id, currentUserId);
        
        posts.add(post.copyWith(isLiked: isLiked, isBookmarked: isBookmarked));
      }

      return posts;
    } catch (e) {
      print('Get feed posts error: $e');
      throw Exception('Failed to get feed posts');
    }
  }

  // Get user's posts
  Future<List<Post>> getUserPosts(String userId, {DocumentSnapshot? lastDocument, int limit = 12}) async {
    try {
      Query query = _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot querySnapshot = await query.get();
      final List<Post> posts = [];

      for (var doc in querySnapshot.docs) {
        posts.add(Post.fromJson(doc.data() as Map<String, dynamic>));
      }

      return posts;
    } catch (e) {
      print('Get user posts error: $e');
      throw Exception('Failed to get user posts');
    }
  }

  // Get post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      final DocumentSnapshot doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
        return Post.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get post by ID error: $e');
      throw Exception('Failed to get post');
    }
  }

  // Like post
  Future<void> likePost(String postId, String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();

      // Add like document
      final DocumentReference likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId);
      batch.set(likeRef, {
        'userId': userId,
        'likedAt': FieldValue.serverTimestamp(),
      });

      // Update likes count
      final DocumentReference postRef = _postsCollection.doc(postId);
      batch.update(postRef, {
        'likesCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Like post error: $e');
      throw Exception('Failed to like post');
    }
  }

  // Unlike post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();

      // Remove like document
      final DocumentReference likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId);
      batch.delete(likeRef);

      // Update likes count
      final DocumentReference postRef = _postsCollection.doc(postId);
      batch.update(postRef, {
        'likesCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Unlike post error: $e');
      throw Exception('Failed to unlike post');
    }
  }

  // Check if post is liked by user
  Future<bool> _isPostLikedByUser(String postId, String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Check like error: $e');
      return false;
    }
  }

  // Bookmark post
  Future<void> bookmarkPost(String postId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(postId)
          .set({
        'postId': postId,
        'bookmarkedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Bookmark post error: $e');
      throw Exception('Failed to bookmark post');
    }
  }

  // Remove bookmark
  Future<void> removeBookmark(String postId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(postId)
          .delete();
    } catch (e) {
      print('Remove bookmark error: $e');
      throw Exception('Failed to remove bookmark');
    }
  }

  // Check if post is bookmarked by user
  Future<bool> _isPostBookmarkedByUser(String postId, String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(postId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Check bookmark error: $e');
      return false;
    }
  }

  // Get bookmarked posts
  Future<List<Post>> getBookmarkedPosts(String userId) async {
    try {
      final QuerySnapshot bookmarksQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .orderBy('bookmarkedAt', descending: true)
          .get();

      final List<String> postIds = bookmarksQuery.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['postId'] as String)
          .toList();

      if (postIds.isEmpty) {
        return [];
      }

      final List<Post> posts = [];
      for (String postId in postIds) {
        final Post? post = await getPostById(postId);
        if (post != null) {
          posts.add(post.copyWith(isBookmarked: true));
        }
      }

      return posts;
    } catch (e) {
      print('Get bookmarked posts error: $e');
      throw Exception('Failed to get bookmarked posts');
    }
  }

  // Delete post
  Future<void> deletePost(String postId, String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();

      // Delete post document
      final DocumentReference postRef = _postsCollection.doc(postId);
      batch.delete(postRef);

      // Update user's posts count
      final DocumentReference userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'postsCount': FieldValue.increment(-1),
      });

      await batch.commit();

      // Delete subcollections (likes, comments) - This would typically be done with Cloud Functions
      // For now, we'll leave them as they'll be cleaned up eventually
    } catch (e) {
      print('Delete post error: $e');
      throw Exception('Failed to delete post');
    }
  }

  // Add comment to post
  Future<String> addComment({
    required String postId,
    required String userId,
    required String content,
    required String userDisplayName,
    required String username,
    String? userProfileImageUrl,
    bool isUserVerified = false,
    String? replyToCommentId,
  }) async {
    try {
      final DocumentReference commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();

      final Comment comment = Comment(
        id: commentRef.id,
        postId: postId,
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
        likesCount: 0,
        userDisplayName: userDisplayName,
        username: username,
        userProfileImageUrl: userProfileImageUrl,
        isUserVerified: isUserVerified,
        replyToCommentId: replyToCommentId,
        isLiked: false,
      );

      final WriteBatch batch = _firestore.batch();

      // Add comment
      batch.set(commentRef, comment.toJson());

      // Update post's comments count
      final DocumentReference postRef = _postsCollection.doc(postId);
      batch.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });

      await batch.commit();
      return commentRef.id;
    } catch (e) {
      print('Add comment error: $e');
      throw Exception('Failed to add comment');
    }
  }

  // Get post comments stream for real-time updates
  Stream<List<Comment>> getPostCommentsStream(String postId, {int limit = 50}) {
    try {
      print('PostService: Setting up comments stream for post $postId');
      
      return _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        print('PostService: Stream received ${snapshot.docs.length} comment documents');
        
        final List<Comment> comments = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          // Only include top-level comments (no replyToCommentId)
          if (data['replyToCommentId'] == null) {
            comments.add(Comment.fromJson(data));
          }
        }

        print('PostService: Stream returning ${comments.length} top-level comments');
        return comments;
      });
    } catch (e) {
      print('Get comments stream error: $e');
      throw Exception('Failed to get comments stream');
    }
  }

  // Get post comments
  Future<List<Comment>> getPostComments(String postId, {int limit = 20}) async {
    try {
      print('PostService: Loading comments for post: $postId');
      final QuerySnapshot query = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      print('PostService: Found ${query.docs.length} comment documents');
      
      final List<Comment> comments = [];
      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('PostService: Comment data: $data');
        // Only include top-level comments (no replyToCommentId)
        if (data['replyToCommentId'] == null) {
          comments.add(Comment.fromJson(data));
        }
      }

      print('PostService: Returning ${comments.length} top-level comments');
      return comments;
    } catch (e) {
      print('Get comments error: $e');
      throw Exception('Failed to get comments');
    }
  }

  // Search posts
  Future<List<Post>> searchPosts(String query, {int limit = 20}) async {
    try {
      final QuerySnapshot querySnapshot = await _postsCollection
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('content')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final List<Post> posts = [];
      for (var doc in querySnapshot.docs) {
        posts.add(Post.fromJson(doc.data() as Map<String, dynamic>));
      }

      return posts;
    } catch (e) {
      print('Search posts error: $e');
      throw Exception('Failed to search posts');
    }
  }

  // Get trending posts (most liked in last 24 hours)
  Future<List<Post>> getTrendingPosts({int limit = 20}) async {
    try {
      final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      final QuerySnapshot querySnapshot = await _postsCollection
          .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .orderBy('createdAt')
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();

      final List<Post> posts = [];
      for (var doc in querySnapshot.docs) {
        posts.add(Post.fromJson(doc.data() as Map<String, dynamic>));
      }

      return posts;
    } catch (e) {
      print('Get trending posts error: $e');
      throw Exception('Failed to get trending posts');
    }
  }

  // Get group posts
  Future<List<Post>> getGroupPosts(String groupId, {int limit = 20}) async {
    try {
      final querySnapshot = await _postsCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return querySnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get group posts error: $e');
      return [];
    }
  }
}