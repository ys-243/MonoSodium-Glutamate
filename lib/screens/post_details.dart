import 'package:flutter/material.dart';
import 'package:plannus/models/post.dart';
import 'package:plannus/models/post_reply.dart';
import 'package:plannus/services/post_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final TextEditingController _replyController = TextEditingController();
  
  List<PostReply> _replies = [];
  bool _isLoading = true;
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }
  
  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    try {
      final replies = await _postService.fetchReplies(widget.post.id);
      if (!mounted) return;
      setState(() {
        _replies = replies;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isReplying = true);
    try {
      await _postService.createReply(widget.post.id, content);
      _replyController.clear();
      FocusScope.of(context).unfocus(); 
      await _loadReplies(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post.title,
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold
          )
        )
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: (widget.post.creatorAvatarUrl != null && widget.post.creatorAvatarUrl!.isNotEmpty)
                          ? NetworkImage(widget.post.creatorAvatarUrl!)
                          : null,
                      child: (widget.post.creatorAvatarUrl != null && widget.post.creatorAvatarUrl!.isNotEmpty)
                          ? null
                          : Text(widget.post.creatorName[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.post.creatorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(widget.post.content, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _replies.length,
                    itemBuilder: (context, index) {
                      final reply = _replies[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: (widget.post.creatorAvatarUrl != null && widget.post.creatorAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(widget.post.creatorAvatarUrl!)
                                  : null,
                              child: (widget.post.creatorAvatarUrl != null && widget.post.creatorAvatarUrl!.isNotEmpty)
                                  ? null
                                  : Text(widget.post.creatorName[0].toUpperCase()),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reply.creatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(reply.content),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'Add a reply...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isReplying ? null : _handleReply,
                  icon: _isReplying 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}