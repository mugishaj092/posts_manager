// lib/screens/post_list_screen.dart

import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/api_exception.dart';
import '../widgets/error_display.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

const _kPrimary = Color(0xFF12BFA2);
const _kSecondary = Color(0xFFFF6584);
const _kDark = Color(0xFF0D2B26);

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final PostService _service = PostService();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    final future = _service.fetchAllPosts();
    setState(() { _postsFuture = future; });
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete "${post.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _kSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deletePost(post.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Post deleted'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _loadPosts();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.message}'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF8),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: _kDark,
            expandedHeight: 130,
            forceElevated: innerBoxIsScrolled,
            shadowColor: Colors.black26,
            title: innerBoxIsScrolled
                ? const Text(
                    'Posts Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _kPrimary.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DASHBOARD',
                                  style: TextStyle(
                                    color: Color(0xFF7EEBD9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Posts Manager',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                            tooltip: 'Refresh',
                            onPressed: _loadPosts,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _kPrimary),
                    SizedBox(height: 16),
                    Text('Loading posts…', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error;
              String message = 'Something went wrong.';
              if (error is NetworkException) message = error.message;
              else if (error is ApiException) message = error.message;
              return ErrorDisplay(message: message, onRetry: _loadPosts);
            }

            final posts = snapshot.data ?? [];
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('No posts yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PostCard(
                    post: post,
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
                      _loadPosts();
                    },
                    onDelete: () { _deletePost(post); },
                    onEdit: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PostFormScreen(post: post)));
                      _loadPosts();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PostFormScreen()));
          _loadPosts();
        },
      ),
    );
  }
}

// Accent colors cycling per post
const _kAccents = [
  Color(0xFF12BFA2),
  Color(0xFFFF6584),
  Color(0xFF6C63FF),
  Color(0xFFFFB347),
  Color(0xFF4FC3F7),
];

class _PostCard extends StatelessWidget {
  final Post post;
  final Future<void> Function() onTap;
  final VoidCallback onDelete;
  final Future<void> Function() onEdit;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _kAccents[(post.id ?? 0) % _kAccents.length];
    final initials = post.title.isNotEmpty
        ? post.title.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD0F0EB), width: 1.5),
          ),
          child: Row(
            children: [
              // Colored left accent bar
              Container(
                width: 5,
                height: 80,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Tag(label: '#${post.id}', color: accent),
                          const SizedBox(width: 6),
                          _Tag(label: 'User ${post.userId}', color: Colors.grey.shade400),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) async {
                  if (v == 'edit') await onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_rounded, size: 16, color: _kPrimary),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_rounded, size: 16, color: _kSecondary),
                      const SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: _kSecondary)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
