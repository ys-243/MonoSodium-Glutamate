import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/events.dart';
import '../services/event_service.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventTimeController = TextEditingController();
  final TextEditingController _eventEndTimeController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();

  final EventService _eventService = EventService();

  List<Event> _events = [];
  bool _isLoadingEvents = true;
  String? _eventsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _eventTitleController.dispose();
    _eventDateController.dispose();
    _eventTimeController.dispose();
    _eventEndTimeController.dispose();
    _eventLocationController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  bool get _canEdit => 
    widget.community.currentUserRole == CommunityRole.owner || 
    widget.community.currentUserRole == CommunityRole.admin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Discussions'),
            Tab(text: 'Events'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_canEdit)
            Container(
              color: Colors.yellow.shade100,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.flag, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Content Moderation Active',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          'This community is moderated for hate speech, racism, and inappropriate content.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscussionsTab(),
                _buildEventsTab(),
                _buildMembersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: 'Share your thoughts with the community...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () {
                      _postController.clear();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recent Discussions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPostCard(
          author: 'Alice Tan',
          content: 'Hey everyone! What did you all think about the lecture today?',
          timestamp: '2 hours ago',
          replies: 5,
        ),
        const SizedBox(height: 12),
        _buildPostCard(
          author: 'Bob Chen',
          content:
              'Anyone up for a study session this weekend? We can cover chapters 5-7.',
          timestamp: '5 hours ago',
          replies: 12,
        ),
        const SizedBox(height: 12),
        _buildPostCard(
          author: 'Clara Wong',
          content:
              'Just finished the assignment! Happy to help if anyone has questions.',
          timestamp: '1 day ago',
          replies: 8,
        ),
      ],
    );
  }

  Widget _buildMembersTab() {
    // Fetch and display the list of members from the supabase.
    return Center(
      child: Text(
        'Members List Coming Soon!',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ); 
  }

  Widget _buildPostCard({
    required String author,
    required String content,
    required String timestamp,
    required int replies,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(author.substring(0, 1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canEdit)
                  IconButton(
                    icon: const Icon(Icons.flag, size: 20),
                    onPressed: () {},
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              child: Text('$replies Replies'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoadingEvents = true;
      _eventsError = null;
    });

    try {
      final events = await _eventService.fetchCommunityEvents(
        widget.community.id,
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoadingEvents = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _eventsError = error.toString();
        _isLoadingEvents = false;
      });
    }
  }

  Widget _buildEventsTab() {
    if (_isLoadingEvents) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_eventsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Failed to load events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _eventsError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadEvents,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Events',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _showCreateEventDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No events yet.'),
              ),
            )
          else
            ..._events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventCard(event),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getMonthName(event.date.month),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${event.date.day}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.location,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.attendees} attending',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            event.isRegistered
                ? const OutlinedButton(
                    onPressed: null,
                    child: Text('Registered'),
                  )
                : FilledButton(
                    onPressed: () async {
                      await _eventService.rsvpToEvent(event.id);
                      await _loadEvents();
                    },
                    child: const Text('RSVP'),
                  ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _showCreateEventDialog() {
    _eventTitleController.clear();
    _eventDateController.clear();
    _eventTimeController.clear();
    _eventEndTimeController.clear();
    _eventLocationController.clear();
    _eventDescriptionController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _eventTitleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _eventDateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _eventTimeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'HH:MM',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _eventEndTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: 'HH:MM',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _eventLocationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _eventDescriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _createEvent,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  TimeOfDay? _parseTime(String timeText) {
    final parts = timeText.split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }
  
  Future<void> _createEvent() async {
    final title = _eventTitleController.text.trim();
    final dateText = _eventDateController.text.trim();
    final startTimeText = _eventTimeController.text.trim();
    final endTimeText = _eventEndTimeController.text.trim();
    final location = _eventLocationController.text.trim();
    final description = _eventDescriptionController.text.trim();

    if (title.isEmpty ||
        dateText.isEmpty ||
        startTimeText.isEmpty ||
        endTimeText.isEmpty ||
        location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title, date, start time, end time, and location.'),
        ),
      );
      return;
    }

    final parsedDate = DateTime.tryParse(dateText);

    if (parsedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the date in YYYY-MM-DD format.'),
        ),
      );
      return;
    }

    final startTime = _parseTime(startTimeText);
    final endTime = _parseTime(endTimeText);

    if (startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter time in HH:MM format.'),
        ),
      );
      return;
    }

    final startDateTime = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      endTime.hour,
      endTime.minute,
    );

    if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
        ),
      );
      return;
    }

    try {
      await _eventService.createEvent(
        communityId: widget.community.id,
        title: title,
        date: parsedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        location: location,
        description: description,
        category: 'General',
        capacity: 0,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully.')),
      );

      await _loadEvents();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: $error')),
      );
    }
  }
}
