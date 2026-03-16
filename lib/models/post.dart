// lib/models/post.dart

class Post {
  final int? id;
  final int userId;
  final String title;
  final String body;

  Post({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// Creates a Post from a JSON map (API response)
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  /// Converts this Post to a JSON map (for API requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'body': body,
    };
  }

  /// Returns a copy of this Post with modified fields
  Post copyWith({int? id, int? userId, String? title, String? body}) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  @override
  String toString() =>
      'Post(id: $id, userId: $userId, title: $title, body: $body)';
}
