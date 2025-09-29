import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final Map<String, User> _users = {};
  bool _isLoading = false;

  Map<String, User> get users => _users;
  bool get isLoading => _isLoading;

  // Mock users data
  final List<User> _mockUsers = [
    User(
      id: '1',
      username: 'john_doe',
      email: 'john@example.com',
      displayName: 'John Doe',
      profileImageUrl: null,
      bio: 'Flutter Developer & Social Media Enthusiast',
      followersCount: 1250,
      followingCount: 890,
      postsCount: 42,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      isVerified: true,
    ),
    User(
      id: '2',
      username: 'jane_smith',
      email: 'jane@example.com',
      displayName: 'Jane Smith',
      profileImageUrl: null,
      bio: 'Photographer | Nature Lover | Coffee Addict ☕',
      followersCount: 2340,
      followingCount: 567,
      postsCount: 89,
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      isVerified: false,
    ),
    User(
      id: '3',
      username: 'alex_codes',
      email: 'alex@example.com',
      displayName: 'Alex Johnson',
      profileImageUrl: null,
      bio: 'Full Stack Developer | Tech Enthusiast | Digital Nomad',
      followersCount: 890,
      followingCount: 1200,
      postsCount: 156,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      isVerified: true,
    ),
    User(
      id: '4',
      username: 'sarah_dev',
      email: 'sarah@example.com',
      displayName: 'Sarah Wilson',
      profileImageUrl: null,
      bio: 'UI/UX Designer | Web Developer | Creative Mind',
      followersCount: 1580,
      followingCount: 743,
      postsCount: 67,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      isVerified: false,
    ),
  ];

  Future<User?> getUserById(String userId) async {
    if (_users.containsKey(userId)) {
      return _users[userId];
    }

    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Find user in mock data
    try {
      final user = _mockUsers.firstWhere((u) => u.id == userId);
      _users[userId] = user;
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<User>> searchUsers(String query) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    final results = _mockUsers.where((user) =>
      user.displayName.toLowerCase().contains(query.toLowerCase()) ||
      user.username.toLowerCase().contains(query.toLowerCase())
    ).toList();

    _isLoading = false;
    notifyListeners();

    return results;
  }

  Future<List<User>> getSuggestedUsers() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Return a subset of mock users as suggestions
    final suggestions = _mockUsers.take(3).toList();

    _isLoading = false;
    notifyListeners();

    return suggestions;
  }

  Future<bool> followUser(String userId) async {
    final user = _users[userId];
    if (user == null) return false;

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    _users[userId] = user.copyWith(
      followersCount: user.followersCount + 1,
    );
    
    notifyListeners();
    return true;
  }

  Future<bool> unfollowUser(String userId) async {
    final user = _users[userId];
    if (user == null) return false;

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 300));

    _users[userId] = user.copyWith(
      followersCount: user.followersCount - 1,
    );
    
    notifyListeners();
    return true;
  }

  List<User> getAllUsers() {
    return _mockUsers;
  }

  void clearUsers() {
    _users.clear();
    notifyListeners();
  }
}