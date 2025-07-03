class Reply {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  int likes;
  final bool isAnonymous;

  Reply({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likes = 0,
    this.isAnonymous = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'isAnonymous': isAnonymous,
    };
  }

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'] as String,
      postId: json['postId'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: json['likes'] as int,
      isAnonymous: json['isAnonymous'] as bool,
    );
  }
} 