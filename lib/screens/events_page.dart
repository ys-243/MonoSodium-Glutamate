import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/events.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  final List<Event> _events = [
    Event(
      id: '1',
      title: 'NUS Hackathon 2026',
      date: DateTime(2026, 5, 20),
      time: '9:00 AM - 9:00 PM',
      location: 'i3 Building',
      organizer: 'NUS Entrepreneurship Society',
      attendees: 156,
      capacity: 200,
      category: 'Technology',
      description: 'Annual hackathon for innovative solutions',
      isRegistered: true,
    ),
    Event(
      id: '2',
      title: 'Basketball Tournament Finals',
      date: DateTime(2026, 5, 18),
      time: '6:00 PM - 8:00 PM',
      location: 'MPSH 1',
      organizer: 'NUS Basketball Club',
      attendees: 89,
      capacity: 150,
      category: 'Sports',
      description: 'Watch the finals of the inter-faculty basketball tournament',
      isRegistered: false,
    ),
    Event(
      id: '3',
      title: 'Career Fair 2026',
      date: DateTime(2026, 5, 25),
      time: '10:00 AM - 5:00 PM',
      location: 'University Town',
      organizer: 'NUS Career Centre',
      attendees: 432,
      capacity: 500,
      category: 'Career',
      description: 'Meet top employers and explore career opportunities',
      isRegistered: true,
    ),
    Event(
      id: '4',
      title: 'Introduction to AI Workshop',
      date: DateTime(2026, 5, 16),
      time: '2:00 PM - 5:00 PM',
      location: 'COM1-0210',
      organizer: 'CS Study Group',
      attendees: 25,
      capacity: 30,
      category: 'Academic',
      description: 'Learn the fundamentals of artificial intelligence',
      isRegistered: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Event> _getFilteredEvents() {
    return _events.where((event) {
      final matchesSearch = event.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || event.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Activities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My Events'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  child: const Chip(
                    avatar: Icon(Icons.filter_list, size: 18),
                    label: Text('Filter'),
                  ),
                  onSelected: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  itemBuilder: (context) => [
                    'All',
                    'Technology',
                    'Sports',
                    'Career',
                    'Academic',
                    'Social'
                  ]
                      .map((category) => PopupMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(_getFilteredEvents()),
                _buildEventsList(
                    _getFilteredEvents().where((e) => e.isRegistered).toList()),
                _buildCalendarView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('No events found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildCategoryChip(event.category),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _buildEventInfo(Icons.calendar_today,
                '${event.date.day}/${event.date.month}/${event.date.year}'),
            const SizedBox(height: 4),
            _buildEventInfo(Icons.access_time, event.time),
            const SizedBox(height: 4),
            _buildEventInfo(Icons.location_on, event.location),
            const SizedBox(height: 4),
            _buildEventInfo(Icons.people,
                '${event.attendees} / ${event.capacity} attending'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'By ${event.organizer}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                event.isRegistered
                    ? const OutlinedButton(
                        onPressed: null,
                        child: Text('Registered'),
                      )
                    : FilledButton(
                        onPressed: () {},
                        child: const Text('RSVP'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    switch (category) {
      case 'Technology':
        color = Colors.blue;
        break;
      case 'Sports':
        color = Colors.green;
        break;
      case 'Career':
        color = Colors.purple;
        break;
      case 'Academic':
        color = Colors.orange;
        break;
      case 'Social':
        color = Colors.pink;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(category, style: TextStyle(color: color, fontSize: 12)),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildCalendarView() {
    final eventsOnSelectedDate = _events
        .where((event) =>
            event.date.year == _selectedDate.year &&
            event.date.month == _selectedDate.month &&
            event.date.day == _selectedDate.day)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Events on ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (eventsOnSelectedDate.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No events scheduled for this date'),
            ),
          )
        else
          ...eventsOnSelectedDate.map((event) => _buildEventCard(event)),
      ],
    );
  }
}
