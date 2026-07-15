import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/events.dart';
import 'notif_service.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> createEvent({
    required String communityId,
    required String title,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required String description,
    required String category,
    required int capacity,

  }) async {

    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to create an event.');
    }

    final insertedEvent = await _supabase
        .from('events')
        .insert({
          'community_id': communityId,
          'title': title,
          'date': date.toIso8601String(),
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': endTime.toUtc().toIso8601String(),
          'location': location,
          'description': description,
          'category': category,
          'capacity': capacity,
          'created_by': user.id,
        })
        .select('id')
        .single();

    final eventId = insertedEvent['id'] as String;

    await _supabase.from('event_attendees').upsert(
      {
        'event_id': eventId,
        'user_id': user.id,
        'status': 'registered',
      },
      onConflict: 'event_id,user_id',
    );
  }

  Future<void> deleteEvent(String eventId) async {
    await _supabase
        .from('events')
        .delete()
        .eq('id', eventId);
  }
  
  Future<List<Event>> fetchCommunityEvents(String communityId) async {
    final currentUser = _supabase.auth.currentUser;

    final eventRows = await _supabase
        .from('events')
        .select('*, communities(name, level), profiles(first_name, last_name, user_name)')
        .eq('community_id', communityId)
        .order('start_time', ascending: true);

    final eventIds = eventRows
        .map<String>((event) => event['id'] as String)
        .toList();

    if (eventIds.isEmpty) {
      return [];
    }

    final attendeeRows = await _supabase
        .from('event_attendees')
        .select('event_id, user_id, status')
        .inFilter('event_id', eventIds)
        .eq('status', 'registered');

    final Map<String, int> attendeeCountByEvent = {};
    final Set<String> registeredEventIds = {};

    for (final attendee in attendeeRows) {
      final eventId = attendee['event_id'] as String;
      final userId = attendee['user_id'] as String;

      attendeeCountByEvent[eventId] =
          (attendeeCountByEvent[eventId] ?? 0) + 1;

      if (currentUser != null && userId == currentUser.id) {
        registeredEventIds.add(eventId);
      }
    }

    return eventRows.map<Event>((eventMap) {
      final eventId = eventMap['id'] as String;

      return Event.fromSupabase(
        eventMap,
        attendees: attendeeCountByEvent[eventId] ?? 0,
        isRegistered: registeredEventIds.contains(eventId),
      );
    }).toList();
  }

  // Fetches events from communities that the user is a member of or that are open to all users.
  Future<List<Event>> fetchGlobalEvents() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User is not logged in');

    // Fetch joined community IDs
    final joinedCommunities = await _supabase
        .from('community_members')
        .select('community_id')
        .eq('user_id', currentUser.id)
        .inFilter('role', ['member', 'admin', 'owner']);
    final joinedIds = (joinedCommunities as List).map((r) => r['community_id'] as String).toList();

    // Fetch open community IDs
    final openCommunities = await _supabase
        .from('communities')
        .select('id')
        .eq('level', 'open');
    final openIds = (openCommunities as List).map((r) => r['id'] as String).toList();

    // Combine
    final combinedCommunityIds = {...joinedIds, ...openIds}.toList();

    if (combinedCommunityIds.isEmpty) return [];

    // from these communities, fetch events
    final eventRows = await _supabase
        .from('events')
        .select('*, communities(name, level), profiles(first_name, last_name, user_name)')
        .inFilter('community_id', combinedCommunityIds)
        .order('start_time', ascending: true);

    // Fetch attendee counts and check if current user is registered
    final eventIds = (eventRows as List).map((e) => e['id'] as String).toList();
    final allAttendeeRows = eventIds.isEmpty ? [] : await _supabase
        .from('event_attendees')
        .select('event_id, user_id, status')
        .inFilter('event_id', eventIds)
        .eq('status', 'registered');

    final Map<String, int> attendeeCountByEvent = {};
    final Set<String> registeredEventIds = {};

    for (final attendee in allAttendeeRows) {
      final eventId = attendee['event_id'] as String;
      final userId = attendee['user_id'] as String;
      
      attendeeCountByEvent[eventId] = (attendeeCountByEvent[eventId] ?? 0) + 1;
      if (userId == currentUser.id) {
        registeredEventIds.add(eventId);
      }
    }

    return eventRows.map<Event>((eventMap) {
      final eventId = eventMap['id'] as String;
      return Event.fromSupabase(
        eventMap,
        attendees: attendeeCountByEvent[eventId] ?? 0,
        isRegistered: registeredEventIds.contains(eventId),
      );
    }).toList();
  }

  // Fetches a list of attendee names for a specific event
  Future<List<Map<String, String>>> fetchEventAttendees(String eventId) async {
    final response = await _supabase
        .from('event_attendees')
        .select('''
          user_id,
          profiles (
            first_name,
            last_name,
            user_name
          )
        ''')
        .eq('event_id', eventId)
        .eq('status', 'registered');

    return (response as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      if (profile == null) return {'name': 'Unknown User'};

      final userName = profile['user_name'] as String?;
      final firstName = profile['first_name'] as String? ?? '';
      final lastName = profile['last_name'] as String? ?? '';

      // Prefer user_name, fallback to first + last name
      final displayName = (userName != null && userName.isNotEmpty)
          ? userName
          : '$firstName $lastName'.trim();

      return {'name': displayName.isNotEmpty ? displayName : 'Unknown User'};
    }).toList();
  }

  // Returns true if the user was auto-joined to the community, false if they were already a member.
  // WILL ALWAYS RSVP the user to the event, regardless of their community membership status.
  Future<bool> rsvpToEvent(String eventId, String communityId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User is not logged in');

    // tell supabase that user is attending the event
    await _supabase.from('event_attendees').upsert(
      {
        'event_id': eventId,
        'user_id': currentUser.id,
        'status': 'registered',
      },
      onConflict: 'event_id,user_id',
    );

    final eventData = await _supabase
        .from('events')
        .select('title, start_time')
        .eq('id', eventId)
        .single();
      
    final String eventTitle = eventData['title'] as String;
    final DateTime eventStartTime = DateTime.parse(eventData['start_time'] as String);

    await NotificationService.instance.scheduleEventReminder(
      eventId: eventId,
      eventTitle: eventTitle,
      eventStartTime: eventStartTime.toLocal(),
      reminderBefore: const Duration(hours: 1),
    );
      
    // check if user is a member of the community.
    final membership = await _supabase
        .from('community_members')
        .select('role')
        .eq('community_id', communityId)
        .eq('user_id', currentUser.id)
        .maybeSingle();
    // If not, auto-join them as a member.

    if (membership == null) {
      await _supabase.from('community_members').insert({
        'community_id': communityId,
        'user_id': currentUser.id,
        'role': 'member',
      });
      return true; // Means auto-joined
    }
    
    return false; // Didn't auto-join, user was already a member.
  }

  Future<void> cancelRSVP(String eventId) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    await _supabase
        .from('event_attendees')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', currentUser.id);
    
    await NotificationService.instance.cancelEventReminder(eventId);
  }

  Future<List<Event>> fetchRegisteredEventsForCurrentUser() async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    final attendeeRows = await _supabase
        .from('event_attendees')
        .select('event_id')
        .eq('user_id', currentUser.id)
        .eq('status', 'registered');

    final eventIds = attendeeRows
        .map<String>((row) => row['event_id'] as String)
        .toList();

    if (eventIds.isEmpty) {
      return [];
    }

    final eventRows = await _supabase
        .from('events')
        .select('*, communities(name, level), profiles(first_name, last_name, user_name)')
        .inFilter('id', eventIds)
        .order('start_time', ascending: true);

    final allAttendeeRows = await _supabase
        .from('event_attendees')
        .select('event_id, user_id, status')
        .inFilter('event_id', eventIds)
        .eq('status', 'registered');

    final Map<String, int> attendeeCountByEvent = {};

    for (final attendee in allAttendeeRows) {
      final eventId = attendee['event_id'] as String;

      attendeeCountByEvent[eventId] =
          (attendeeCountByEvent[eventId] ?? 0) + 1;
    }

    return eventRows.map<Event>((eventMap) {
      final eventId = eventMap['id'] as String;

      return Event.fromSupabase(
        eventMap,
        attendees: attendeeCountByEvent[eventId] ?? 0,
        isRegistered: true,
      );
    }).toList();
  }
}