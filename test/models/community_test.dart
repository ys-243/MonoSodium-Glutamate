import 'package:flutter_test/flutter_test.dart';
import 'package:plannus/models/community.dart';

void main() {
  group('Community Model Tests', () {
    
    test('Community.fromJson correctly parses a valid Open Community', () {
      final mockJson = {
        'id': '123-abc',
        'name': 'Test Open Community',
        'description': 'A community for testing',
        'level': 'open',
        'member_count': [
          {'count': 42}
        ],
      };

      // Call fromJson method from the Community class, passing in the mock JSON and a role of 'member'.
      final community = Community.fromJson(mockJson, role: CommunityRole.member);

      // Verify the object properties match the JSON
      expect(community.id, '123-abc');
      expect(community.name, 'Test Open Community');
      expect(community.description, 'A community for testing');
      
      // Verify the enum helper function works
      expect(community.level, CommunityLevel.open);
      
      // Verify nested member count parsed correctly
      expect(community.members, 42);
      
      // Verify role logic 
      expect(community.currentUserRole, CommunityRole.member);
      expect(community.isJoined, isTrue); // since 'member', isJoined should be true
    });

    test('Community.fromJson correctly parses pending role logic', () {
      final mockJson = {
        'id': '456-def',
        'name': 'Test Closed Community',
        'description': 'A closed community',
        'level': 'closed',
        'member_count': [], // Testing fallback for empty count
      };

      // Create with a pending role
      final community = Community.fromJson(mockJson, role: CommunityRole.pending);

      // Assert
      expect(community.level, CommunityLevel.closed);
      
      // Because role is pending, isJoined should be FALSE
      expect(community.isJoined, isFalse);
      expect(community.members, 0); // Should fallback to 0 since member_count is empty.
    });

    test('Community.fromJson throws error on invalid community level', () {
      final mockJson = {
        'id': '789-ghi',
        'name': 'Broken Community',
        'description': 'Has an invalid level',
        'level': 'super_secret', // Invalid level
      };

      // Assert that calling fromJson with bad data throws an ArgumentError
      expect(
        () => Community.fromJson(mockJson), 
        throwsA(isA<ArgumentError>())
      );
    });
    
  });
}
