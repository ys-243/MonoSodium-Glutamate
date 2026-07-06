import 'package:flutter_test/flutter_test.dart';
import 'package:plannus/models/events.dart'; // Ensure this matches your app's name

void main() {
  group('Event Model Tests', () {
    
    test('Event.fromSupabase parses perfectly populated JSON correctly', () {
      // Mock JSON response from Supabase with all fields correctly populated
      final mockJson = {
        'id': 'event-123',
        'community_id': 'comm-456',
        'created_by': 'user-789',
        'title': 'Flutter Study Session',
        'description': 'Learning Riverpod and Testing',
        'location': 'COM1',
        'category': 'Academic',
        'capacity': 30,
        'start_time': '2026-07-15T10:00:00.000Z', // 10:00 AM UTC
        'end_time': '2026-07-15T12:00:00.000Z',   // 12:00 PM UTC
        'created_at': '2026-07-01T08:00:00.000Z', // 8:00 AM UTC
        'communities': {
          'name': 'NUS Hackers',
          'level': 'open',
        },
        'profiles': {
          'user_name': 'flutter_dev',
          'first_name': 'Ada',
          'last_name': 'Lovelace',
        }
      };

      // Create an Event instance using our fromSupabase factory method.
      final event = Event.fromSupabase(mockJson, attendees: 12, isRegistered: true);

      // Verify
      expect(event.id, 'event-123');
      expect(event.title, 'Flutter Study Session');

      // Should prioritize user_name over first/last name
      expect(event.organiser, 'flutter_dev'); 

      expect(event.communityName, 'NUS Hackers');
      expect(event.attendees, 12);
      expect(event.isRegistered, isTrue);

      // It should successfully format the time range (e.g. "6:00 PM - 8:00 PM" depending on local timezone)
      expect(event.time, contains('-')); 
    });

    test('Event.fromSupabase applies safe fallbacks for missing nested data', () {
      // Bad response
      final mockJson = {
        'id': 'event-999',
        'community_id': 'comm-111',
        'created_by': 'user-222',
        'title': 'Mystery Event',
        'start_time': '2026-08-01T14:00:00.000Z',
        // Purposely omit end_time, created_at, communities, and profiles
      };

      final event = Event.fromSupabase(mockJson, attendees: 0, isRegistered: false);

      // Check Fallbacks
      expect(event.organiser, 'Community Member'); // Fallback for missing profile
      expect(event.communityName, 'Unknown Community'); // Fallback for missing community data
      expect(event.communityLevel, 'open'); 
      
      // Because end_time is null, the time string should NOT contain a dash (-)
      expect(event.time.contains('-'), isFalse); 

      // Because created_at was missing, it should fallback to exactly now
      final differenceInSeconds = event.createdAt.difference(DateTime.now()).inSeconds.abs();
      expect(differenceInSeconds, lessThan(2)); // Should be generated within the last 2 seconds
    });

    test('Event.fromSupabase falls back to first and last name if user_name is blank', () {
      final mockJson = {
        'id': 'event-555',
        'community_id': 'comm-456',
        'created_by': 'user-789',
        'start_time': '2026-07-10T10:00:00.000Z',
        'profiles': {
          'user_name': '', // Blank username
          'first_name': 'Grace',
          'last_name': 'Hopper',
        }
      };

      final event = Event.fromSupabase(mockJson, attendees: 5, isRegistered: false);
      
      // should skip the empty user_name and combine the first and last name
      expect(event.organiser, 'Grace Hopper');
    });
    
  });
}