class Event {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final String location;
  final String organizer;
  final int attendees;
  final int capacity;
  final String category;
  final String description;
  final bool isRegistered;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.organizer,
    required this.attendees,
    required this.capacity,
    required this.category,
    required this.description,
    required this.isRegistered,
  });
}