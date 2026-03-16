// lib/screens/post_form_screen.dart

import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/api_exception.dart';

const _kPrimary = Color(0xFF12BFA2);
const _kSecondary = Color(0xFFFF6584);
const _kDark = Color(0xFF0D2B26);

class PostFormScreen extends StatefulWidget {
  final Post? post;
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PostService _service = PostService();

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  bool _isLoading = false;
  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _bodyController = TextEditingController(text: widget.post?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _service.updatePost(widget.post!.copyWith(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        ));
        if (!mounted) return;
        _showSuccess('Post updated successfully!');
      } else {
        await _service.createPost(
          userId: 1,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        );
        if (!mounted) return;
        _showSuccess('Post created successfully!');
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on NetworkException catch (e) {
      _showError('Network error: ${e.message}');
    } on ServerException catch (e) {
      _showError('Server error (${e.statusCode}): ${e.message}');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _kSecondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: _kDark,
            foregroundColor: Colors.white,
            shadowColor: Colors.black26,
            title: const Text(
              '',
              style: TextStyle(color: Colors.white),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed = constraints.maxHeight <= kToolbarHeight + MediaQuery.of(context).padding.top + 10;
                return FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  title: isCollapsed
                      ? Text(
                          _isEditing ? 'Edit Post' : 'New Post',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        )
                      : null,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
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
                          child: Text(
                            _isEditing ? 'EDITING' : 'COMPOSE',
                            style: const TextStyle(
                              color: Color(0xFF7EEBD9),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isEditing ? 'Edit Post' : 'New Post',
                          style: const TextStyle(
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
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldCard(
                      label: 'TITLE',
                      icon: Icons.title_rounded,
                      child: TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Enter post title…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 15, color: _kDark),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Title is required';
                          if (v.trim().length < 5) return 'At least 5 characters';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldCard(
                      label: 'CONTENT',
                      icon: Icons.article_rounded,
                      child: TextFormField(
                        controller: _bodyController,
                        minLines: 6,
                        maxLines: 14,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Write your post content here…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.7),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Body is required';
                          if (v.trim().length < 10) return 'At least 10 characters';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Gradient submit button
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimary, Color(0xFF0D9E87)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _isLoading ? null : _submit,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isEditing ? Icons.save_rounded : Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isEditing ? 'Save Changes' : 'Create Post',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _FieldCard({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0F0EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _kPrimary, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
