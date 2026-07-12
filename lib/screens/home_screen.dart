import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:plannus/models/events.dart';
import 'package:plannus/services/event_service.dart';
import 'package:plannus/screens/events_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onTabSelected;
  const HomeScreen({super.key, required this.onTabSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Service to fetch events the user has registered for
  final EventService _eventService = EventService();

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  
  List<CalendarItem> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
  }

  // Loads both personal and community events for the current user and combines them into a unified list.
  Future<void> _loadUserEvents() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Fetch Personal Events (Classes, Manual Entries)
      final personalData = await Supabase.instance.client
          .from('personal_calendar_events')
          .select()
          .eq('user_id', currentUserId);

      // 2. Fetch Community Events (RSVPs)
      final communityEvents = await _eventService.fetchRegisteredEventsForCurrentUser();

      // 3. Combine them into our Unified Wrapper
      List<CalendarItem> combined = [];
      
      for (var ce in communityEvents) {
        combined.add(CalendarItem.community(ce));
      }
      for (var pe in personalData) {
        combined.add(CalendarItem.personal(pe));
      }

      if (mounted) {
        setState(() {
          _allEvents = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<CalendarItem> _getEventsForDay(DateTime day) {
    return _allEvents.where((item) =>
        item.date.year == day.year &&
        item.date.month == day.month &&
        item.date.day == day.day).toList();
  }

  List<CalendarItem> _getEventsOnSelectedDate() {
    return _getEventsForDay(_selectedDate);
  }

  // Helper function to format time for personal events
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'PN',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PlanNUS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Welcome to PlanNUS!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your all-in-one community platform for the NUS ecosystem. Connect, collaborate, and engage both online and offline in a unified space.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Calender Section
            const Text(
              'My Upcoming Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCalendarSection(),
            const SizedBox(height: 32),
            // Calender Section
            const Text(
              'Discover More!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureCard(
              context,
              icon: Icons.people,
              title: 'Communities',
              description:
                  'Join intimate, closed, or open communities tailored to your interests',
              color: Colors.blue,
              onTap: () {
                widget.onTabSelected(1); 
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.calendar_today,
              title: 'Events & Activities',
              description:
                  'Discover campus events, create activities, and manage RSVPs',
              color: Colors.green,
              onTap: () {
                widget.onTabSelected(2); 
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.forum,
              title: 'Forums & Discussions',
              description:
                  'Engage in meaningful conversations with your community',
              color: Colors.purple,
              onTap: () {
                widget.onTabSelected(1); 
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.person_add,
              title: 'Connect with Friends',
              description:
                  'Build your network and stay connected with classmates',
              color: Colors.orange,
              onTap: () {
                widget.onTabSelected(3); 
              },
            ),
            const SizedBox(height: 32),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Get Started Today',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join communities, discover events, and connect with the NUS community',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        widget.onTabSelected(1); 
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text('Browse Communities'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        widget.onTabSelected(2); 
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text('Explore Events'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final eventsOnSelectedDate = _getEventsOnSelectedDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar<CalendarItem>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              eventLoader: _getEventsForDay,
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
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, 
                titleCentered: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
         if (eventsOnSelectedDate.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No events scheduled for this date.',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          ...eventsOnSelectedDate.map((item) {
            
            // for personal events, we need to parse the start and end times and display them in a readable format.
            if (item.isPersonal) {
              final pe = item.personalEvent!;
              final startAt = DateTime.parse(pe['start_at']).toLocal();
              final endAt = DateTime.parse(pe['end_at']).toLocal();
              final title = pe['title'] ?? 'Busy';
              final venue = pe['venue'];
              final source = pe['source'];
              
              final timeString = '${_formatTime(startAt)} - ${_formatTime(endAt)}';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    source == 'nusmods' ? Icons.school : Icons.person, 
                    color: Colors.orange
                  ),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(venue != null && venue.toString().isNotEmpty ? '$timeString • $venue' : timeString),
                      const SizedBox(height: 4),
                      Text(
                        source == 'nusmods' ? 'NUSMods Class' : 'Personal Event',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            } 
            
            // standard UI for community events
            else {
              final event = item.communityEvent!;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${event.time} • ${event.location}'),
                      const SizedBox(height: 4),
                      Text(
                        event.communityName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventsScreen(
                          communityId: event.communityId,
                          communityName: event.communityName,
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          }),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class to combine the Community Events and Personal Events.
class CalendarItem {
  final bool isPersonal;
  final Event? communityEvent;
  final Map<String, dynamic>? personalEvent;
  final DateTime date;

  CalendarItem.community(this.communityEvent)
      : isPersonal = false,
        personalEvent = null,
        date = communityEvent!.date;

  CalendarItem.personal(this.personalEvent)
      : isPersonal = true,
        communityEvent = null,
        date = DateTime.parse(personalEvent!['start_at']).toLocal();
}