// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/api_exception.dart';
import 'post_form_screen.dart';

const _kPrimary = Color(0xFF12BFA2);
const _kSecondary = Color(0xFFFF6584);
const _kDark = Color(0xFF0D2B26);

const _kAccents = [
  Color(0xFF12BFA2),
  Color(0xFFFF6584),
  Color(0xFF6C63FF),
  Color(0xFFFFB347),
  Color(0xFF4FC3F7),
];

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _service = PostService();
  late Future<Post> _postFuture;

  @override
  void initState() {
    super.initState();
    _postFuture = _service.fetchPost(widget.post.id!);
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure? This action cannot be undone.'),
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
      Navigator.pop(context);
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
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF8),
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(snapshot),
              SliverToBoxAdapter(child: _buildBody(snapshot)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AsyncSnapshot<Post> snapshot) {
    final post = snapshot.data;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: _kDark,
      foregroundColor: Colors.white,
      shadowColor: Colors.black26,
      title: snapshot.connectionState != ConnectionState.waiting
          ? const Text(
              'Post Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            )
          : null,
      actions: snapshot.hasData
          ? [
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  tooltip: 'Edit',
                  onPressed: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => PostFormScreen(post: post!)));
                    final f = _service.fetchPost(post!.id!);
                    setState(() { _postFuture = f; });
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _kSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kSecondary.withOpacity(0.25)),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_rounded, size: 18, color: _kSecondary),
                  tooltip: 'Delete',
                  onPressed: () { _deletePost(post!); },
                ),
              ),
            ]
          : null,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'READING',
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
                'Post Details',
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
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<Post> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (snapshot.hasError) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kSecondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, size: 40, color: _kSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Failed to load post.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  onPressed: () {
                    final f = _service.fetchPost(widget.post.id!);
                    setState(() => _postFuture = f);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final post = snapshot.data!;
    final accent = _kAccents[(post.id ?? 0) % _kAccents.length];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta chips row
          Row(
            children: [
              _Chip(label: 'Post #${post.id}', color: accent),
              const SizedBox(width: 8),
              _Chip(label: 'User ${post.userId}', color: Colors.grey.shade500),
            ],
          ),
          const SizedBox(height: 16),
          // Title card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0F0EB), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.title_rounded, color: accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Title',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: _kDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Body card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0F0EB), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.article_rounded, color: _kPrimary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'CONTENT',
                      style: TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  post.body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
