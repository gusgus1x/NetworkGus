import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get user by ID error: $e');
      throw Exception('Failed to get user');
    }
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    try {
      final QuerySnapshot query = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return User.fromMap(query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get user by username error: $e');
      throw Exception('Failed to get user');
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    try {
      final List<User> users = [];
      
      // Search by username
      final QuerySnapshot usernameQuery = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      for (var doc in usernameQuery.docs) {
        users.add(User.fromMap(doc.data() as Map<String, dynamic>));
      }

      // Search by display name
      final QuerySnapshot displayNameQuery = await _usersCollection
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      for (var doc in displayNameQuery.docs) {
        final user = User.fromMap(doc.data() as Map<String, dynamic>);
        // Avoid duplicates
        if (!users.any((u) => u.id == user.id)) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Search users error: $e');
      throw Exception('Failed to search users');
    }
  }

  // Follow user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final WriteBatch batch = _firestore.batch();

      // Add to current user's following list
      final DocumentReference followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      batch.set(followingRef, {
        'userId': targetUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Add to target user's followers list
      final DocumentReference followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);
      batch.set(followerRef, {
        'userId': currentUserId,
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Update following count for current user
      final DocumentReference currentUserRef = _usersCollection.doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(1),
      });

      // Update followers count for target user
      final DocumentReference targetUserRef = _usersCollection.doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Follow user error: $e');
      throw Exception('Failed to follow user');
    }
  }

  // Unfollow user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      final WriteBatch batch = _firestore.batch();

      // Remove from current user's following list
      final DocumentReference followingRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);
      batch.delete(followingRef);

      // Remove from target user's followers list
      final DocumentReference followerRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);
      batch.delete(followerRef);

      // Update following count for current user
      final DocumentReference currentUserRef = _usersCollection.doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
      });

      // Update followers count for target user
      final DocumentReference targetUserRef = _usersCollection.doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Unfollow user error: $e');
      throw Exception('Failed to unfollow user');
    }
  }

  // Check if user is following another user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Check following error: $e');
      return false;
    }
  }

  // Get user's followers
  Future<List<User>> getFollowers(String userId) async {
    try {
      final QuerySnapshot query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .orderBy('followedAt', descending: true)
          .get();

      final List<User> followers = [];
      for (var doc in query.docs) {
        final String followerId = (doc.data() as Map<String, dynamic>)['userId'];
        final User? follower = await getUserById(followerId);
        if (follower != null) {
          followers.add(follower);
        }
      }

      return followers;
    } catch (e) {
      print('Get followers error: $e');
      throw Exception('Failed to get followers');
    }
  }

  // Get user's following
  Future<List<User>> getFollowing(String userId) async {
    try {
      final QuerySnapshot query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .orderBy('followedAt', descending: true)
          .get();

      final List<User> following = [];
      for (var doc in query.docs) {
        final String followingId = (doc.data() as Map<String, dynamic>)['userId'];
        final User? followingUser = await getUserById(followingId);
        if (followingUser != null) {
          following.add(followingUser);
        }
      }

      return following;
    } catch (e) {
      print('Get following error: $e');
      throw Exception('Failed to get following');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    String? website,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (website != null) updateData['website'] = website;

      if (updateData.isNotEmpty) {
        await _usersCollection.doc(userId).update(updateData);
      }
    } catch (e) {
      print('Update user profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Get suggested users (users not followed by current user)
  Future<List<User>> getSuggestedUsers(String currentUserId, {int limit = 10}) async {
    try {
      // Get users with most followers (excluding current user)
      final QuerySnapshot query = await _usersCollection
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .orderBy('followersCount', descending: true)
          .limit(limit * 2) // Get more to filter out already followed users
          .get();

      final List<User> suggestedUsers = [];
      for (var doc in query.docs) {
        final user = User.fromMap(doc.data() as Map<String, dynamic>);
        
        // Check if current user is already following this user
        final bool isAlreadyFollowing = await isFollowing(currentUserId, user.id);
        if (!isAlreadyFollowing && suggestedUsers.length < limit) {
          suggestedUsers.add(user);
        }
      }

      return suggestedUsers;
    } catch (e) {
      print('Get suggested users error: $e');
      throw Exception('Failed to get suggested users');
    }
  }

  // Block user
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .doc(targetUserId)
          .set({
        'userId': targetUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // Also unfollow if following
      final bool isCurrentlyFollowing = await isFollowing(currentUserId, targetUserId);
      if (isCurrentlyFollowing) {
        await unfollowUser(currentUserId, targetUserId);
      }
    } catch (e) {
      print('Block user error: $e');
      throw Exception('Failed to block user');
    }
  }

  // Unblock user
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .doc(targetUserId)
          .delete();
    } catch (e) {
      print('Unblock user error: $e');
      throw Exception('Failed to unblock user');
    }
  }

  // Check if user is blocked
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Check blocked error: $e');
      return false;
    }
  }
}