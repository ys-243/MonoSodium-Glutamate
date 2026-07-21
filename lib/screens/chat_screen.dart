import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plannus/services/chat_service.dart'; // Make sure this matches your project name!

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String? friendAvatarUrl; 

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    required this.friendAvatarUrl, 
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId = Supabase.instance.client.auth.currentUser!.id;

  bool _isFriendOnline = false;
  RealtimeChannel? _presenceChannel;

  @override
  void initState() {
    super.initState();
    _setupPresenceChannel();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  void _setupPresenceChannel() {
    _presenceChannel = Supabase.instance.client.channel('online-users');
    
    _presenceChannel!.onPresenceSync((_) {
      final presenceState = _presenceChannel!.presenceState();
      bool friendFound = false;

      // Safely loop through the presence state to look for the friend's ID
      for (var state in presenceState) {
        final presenceList = state as List<dynamic>;
        for (var presence in presenceList) {
          if (presence['user_id'] == widget.friendId) {
            friendFound = true;
            break;
          }
        }
        if (friendFound) break;
      }

      // Update the UI if the friend's status changes
      if (mounted && _isFriendOnline != friendFound) {
        setState(() {
          _isFriendOnline = friendFound;
        });
      }

    }).subscribe((status, [error]) async {
      // standard subscribe handler
    });
  }
  
  // Sends the message and instantly clears the text box after sending. 
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return; // end as no message to send
    }

    _messageController.clear(); // Clear instantly since we have already saved the message.
    
    try {
      await _chatService.sendMessage(widget.friendId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0, // Removes extra gap between the back button and the avatar
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // TODO: Route to your friend's profile screen here!
            // Example:
            // Navigator.push(
            //   context, 
            //   MaterialPageRoute(
            //     builder: (context) => ProfileScreen(userId: widget.friendId),
            //   ),
            // );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    // 1. Show the image if the URL exists
                    backgroundImage: (widget.friendAvatarUrl != null && widget.friendAvatarUrl!.isNotEmpty)
                        ? NetworkImage(widget.friendAvatarUrl!)
                        : null,
                    // 2. Only show the text initial if there is no image
                    child: (widget.friendAvatarUrl != null && widget.friendAvatarUrl!.isNotEmpty)
                        ? null
                        : Text(
                            widget.friendName.isNotEmpty ? widget.friendName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.friendName,
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          // Optional: A tiny dot next to the text for extra visual flair
                          if (_isFriendOnline) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            _isFriendOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isFriendOnline 
                                  ? Colors.green 
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: _isFriendOnline ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'View Profile',
            onPressed: () {
              // Same routing logic as the InkWell onTap above
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Real-time Chat Area
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>( // Listen to the real-time chat stream
              stream: _chatService.getChatStream(widget.friendId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hi! 👋', 
                      style: TextStyle(color: Colors.grey, fontSize: 16)
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender_id'] == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : null,
                            bottomLeft: !isMe ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: Text(
                          message['content'],
                          style: TextStyle(
                            color: isMe 
                                ? Theme.of(context).colorScheme.onPrimary 
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // The Text Input Area
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}