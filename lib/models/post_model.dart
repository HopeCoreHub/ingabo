class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  int likes;
  final List<String> replies;
  final bool isAnonymous;
  final Set<String> likedBy;
  final bool isSyncedWithCloud; // New field to track sync status

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likes = 0,
    List<String>? replies,
    this.isAnonymous = true,
    Set<String>? likedBy,
    this.isSyncedWithCloud = false, // Default to false (not synced)
  }) : replies = replies ?? [],
       likedBy = likedBy ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'replies': replies,
      'isAnonymous': isAnonymous,
      'likedBy': likedBy.toList(),
      'isSyncedWithCloud': isSyncedWithCloud,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: json['likes'] as int,
      replies: List<String>.from(json['replies'] as List),
      isAnonymous: json['isAnonymous'] as bool,
      likedBy:
          json.containsKey('likedBy')
              ? Set<String>.from(json['likedBy'] as List)
              : {},
      isSyncedWithCloud: json['isSyncedWithCloud'] as bool? ?? false,
    );
  }

  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    int? likes,
    List<String>? replies,
    bool? isAnonymous,
    Set<String>? likedBy,
    bool? isSyncedWithCloud,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      likedBy: likedBy ?? this.likedBy,
      isSyncedWithCloud: isSyncedWithCloud ?? this.isSyncedWithCloud,
    );
  }
}
