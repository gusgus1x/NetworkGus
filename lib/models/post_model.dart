class Post {
  final String id;
  final String userId;
  final String content;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final bool isBookmarked;
  final String userDisplayName;
  final String username;
  final String? userProfileImageUrl;
  final bool isUserVerified;
  final String? groupId;

  Post({
  required this.id,
  required this.userId,
  required this.content,
  this.imageUrls,
  required this.createdAt,
  this.updatedAt,
  this.likesCount = 0,
  this.commentsCount = 0,
  this.sharesCount = 0,
  this.isLiked = false,
  this.isBookmarked = false,
  required this.userDisplayName,
  required this.username,
  this.userProfileImageUrl,
  this.isUserVerified = false,
  this.groupId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      userDisplayName: json['userDisplayName'],
      username: json['username'],
      userProfileImageUrl: json['userProfileImageUrl'],
      isUserVerified: json['isUserVerified'] ?? false,
      groupId: json['groupId'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
      'userDisplayName': userDisplayName,
      'username': username,
      'userProfileImageUrl': userProfileImageUrl,
      'isUserVerified': isUserVerified,
      'groupId': groupId,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isBookmarked,
    String? userDisplayName,
    String? username,
    String? userProfileImageUrl,
    bool? isUserVerified,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      username: username ?? this.username,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      isUserVerified: isUserVerified ?? this.isUserVerified,
    );
  }
}