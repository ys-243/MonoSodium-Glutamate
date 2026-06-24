import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/events.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Event>> fetchCommunityEvents(String communityId) async {
    final currentUser = _supabase.auth.currentUser;

    final eventRows = await _supabase
        .from('events')
        .select()
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
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
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

  Future<void> rsvpToEvent(String eventId) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    await _supabase.from('event_attendees').upsert(
      {
        'event_id': eventId,
        'user_id': currentUser.id,
        'status': 'registered',
      },
      onConflict: 'event_id,user_id',
    );
  }

  Future<void> cancelRsvp(String eventId) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    await _supabase
        .from('event_attendees')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', currentUser.id);
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
        .select()
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