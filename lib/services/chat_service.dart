import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final _supabase = Supabase.instance.client;

  // Generates a consistent conversation ID regardless of who sends the message
  String _getConversationId(String currentUserId, String friendId) {
    final ids = [currentUserId, friendId];
    ids.sort(); // Sorts alphabetically
    return '${ids[0]}_${ids[1]}';
  }

  // Send a message
  Future<void> sendMessage(String friendId, String content) async {
    final currentUserId = _supabase.auth.currentUser!.id;
    final convoId = _getConversationId(currentUserId, friendId);

    // Make sure 'conversation_id' perfectly matches your Supabase column
    await _supabase.from('messages').insert({
      'sender_id': currentUserId,
      'receiver_id': friendId,
      'conversation_id': convoId, 
      'content': content,
    });
  }

  // Listen to a live stream of messages
  Stream<List<Map<String, dynamic>>> getChatStream(String friendId) {
    final currentUserId = _supabase.auth.currentUser!.id;
    final convoId = _getConversationId(currentUserId, friendId);

    // listens to the database in real-time. Any new insert triggers an update.
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', convoId)
        .order('created_at', ascending: true);
  }
}