import 'package:flutter/material.dart';
import 'package:plannus/models/community.dart';
import 'package:plannus/services/community_service.dart';
import 'package:plannus/models/events.dart';
import 'package:plannus/services/event_service.dart';


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
  final CommunityService _communityService = CommunityService();

  // State variables for events
  List<Event> _events = [];
  bool _isLoadingEvents = true;
  String? _eventsError;

  // State variables for event creation dialog
  bool _isCreating = false;
  String? _dialogError;

  // State variables for members
  List<Map<String, String>> _members = [];
  bool _isLoadingMembers = true;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents(); 
    _loadMembers(); 
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
    if (_isLoadingMembers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_membersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_membersError'),
            TextButton(
              onPressed: _loadMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(child: Text('No members found.'));
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final name = member['name']!;
          final role = member['role']!;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(role.toUpperCase()),
              trailing: role == 'owner' || role == 'admin' 
                  ? Icon(Icons.shield, color: Theme.of(context).colorScheme.primary, size: 20) 
                  : null,
            ),
          );
        },
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

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });

    try {
      final members = await _communityService.fetchCommunityMembers(widget.community.id);

      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _membersError = error.toString();
        _isLoadingMembers = false;
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEventDetailsDialog(event),
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
      ),
    );
  }

  void _showEventDetailsDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrinks to fit content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Event Description ---
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description.isNotEmpty 
                      ? event.description 
                      : 'No description provided.',
                ),
                const SizedBox(height: 24),

                // --- Attendees Header ---
                Row(
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Attendees (${event.attendees})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(),

                // --- Dynamic Attendees List ---
                Flexible(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: _eventService.fetchEventAttendees(event.id),
                    builder: (context, snapshot) {
                      // Loading State
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      // if error
                      if (snapshot.hasError) {
                        return Text('Error loading attendees: ${snapshot.error}');
                      }

                      // Success State
                      final attendees = snapshot.data ?? [];
                      if (attendees.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No one has registered yet. Be the first!'),
                        );
                      }

                      // Build the list of avatars and names
                      return ListView.builder(
                        shrinkWrap: true, // Crucial for using ListView inside Dialog
                        itemCount: attendees.length,
                        itemBuilder: (context, index) {
                          final name = attendees[index]['name']!;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                name[0].toUpperCase(),
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                              ),
                            ),
                            title: Text(name),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
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

  void _showCreateEventDialog() {
    // Clear controllers when opening a fresh dialog
    _eventTitleController.clear();
    _eventDateController.clear();
    _eventTimeController.clear();
    _eventEndTimeController.clear();
    _eventLocationController.clear();
    _eventDescriptionController.clear();

    // Reset the dialog state variables
    _dialogError = null;
    _isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents accidental dismissal while loading
      builder: (dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: const Text('Create Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // error message display
                  if (_dialogError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dialogError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- FORM FIELDS ---
                  TextField(
                    controller: _eventTitleController,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Picker
                  TextField(
                    controller: _eventDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'DD-MM-YYYY',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(), 
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        final String day = pickedDate.day.toString().padLeft(2, '0');
                        final String month = pickedDate.month.toString().padLeft(2, '0');
                        final String year = pickedDate.year.toString();
                        _eventDateController.text = '$day-$month-$year';
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Start Time Picker
                  TextField(
                    controller: _eventTimeController,
                    readOnly: true, // Prevents keyboard from showing up
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      hintText: 'HH:MM',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        final String hour = pickedTime.hour.toString().padLeft(2, '0');
                        final String minute = pickedTime.minute.toString().padLeft(2, '0');
                        _eventTimeController.text = '$hour:$minute';
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // End Time Picker
                  TextField(
                    controller: _eventEndTimeController,
                    readOnly: true, // Prevents keyboard from showing up
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      hintText: 'HH:MM',
                      suffixIcon: Icon(Icons.access_time_filled),
                    ),
                    onTap: () async {
                      TimeOfDay initialEndTime = TimeOfDay.now();
                      if (_eventTimeController.text.isNotEmpty) {
                        final parts = _eventTimeController.text.split(':');
                        if (parts.length == 2) {
                           initialEndTime = TimeOfDay(
                             hour: int.tryParse(parts[0]) ?? initialEndTime.hour, 
                             minute: int.tryParse(parts[1]) ?? initialEndTime.minute
                           );
                        }
                      }
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: initialEndTime,
                      );
                      if (pickedTime != null) {
                        final String hour = pickedTime.hour.toString().padLeft(2, '0');
                        final String minute = pickedTime.minute.toString().padLeft(2, '0');
                        _eventEndTimeController.text = '$hour:$minute';
                      }
                    },
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
            
            // --- ACTIONS ---
            actions: [
              TextButton(
                onPressed: _isCreating ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                // Disable button while creating to prevent multiple submissions
                onPressed: _isCreating ? null : () => _handleEventSubmission(setDialogState), // pass info to event submission function.
                child: _isCreating 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _handleEventSubmission(StateSetter setDialogState) async {
    // We check for any errors in the submission
    
    // 1. Empty field check
    if (_eventTitleController.text.isEmpty || 
        _eventDateController.text.isEmpty ||
        _eventTimeController.text.isEmpty ||
        _eventEndTimeController.text.isEmpty ||
        _eventLocationController.text.isEmpty) {
      setDialogState(() => _dialogError = 'Please fill in all required fields.');
      return;
    }

    // 2. Date Validation: Date must be in the future and in correct format (DD-MM-YYYY)
    final dateParts = _eventDateController.text.split('-');
    DateTime? parsedDate;
    if (dateParts.length == 3) {
      final day = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final year = int.tryParse(dateParts[2]);
      
      if (day != null && month != null && year != null) {
        parsedDate = DateTime(year, month, day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (parsedDate.isBefore(today)) {
          setDialogState(() => _dialogError = 'Event date cannot be in the past.');
          return;
        }
      }
    }
    
    if (parsedDate == null) {
       setDialogState(() => _dialogError = 'Invalid date format.');
       return;
    }

    // 3. Time Validation: End time must be after start time and in correct format (HH:MM)
    final startTime = _parseTime(_eventTimeController.text);
    final endTime = _parseTime(_eventEndTimeController.text);

    if (startTime != null && endTime != null) {
      if (endTime.hour < startTime.hour || 
         (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
        setDialogState(() => _dialogError = 'End time must be after start time.');
        return;
      }
    } else {
       setDialogState(() => _dialogError = 'Invalid time format.');
       return;
    }

    // If all ok, we show spinner and send to Supabase
    setDialogState(() {
      _dialogError = null;
      _isCreating = true;
    });
    // Send to Supabase
    try {
      final startDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, startTime.hour, startTime.minute);
      final endDateTime = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, endTime.hour, endTime.minute);

      await _eventService.createEvent(
        communityId: widget.community.id,
        title: _eventTitleController.text.trim(),
        date: parsedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        location: _eventLocationController.text.trim(),
        description: _eventDescriptionController.text.trim(),
        category: 'General',
        capacity: 0,
      );

      if (!mounted) return;
      
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully.')),
      );
      await _loadEvents();
      
    } catch (error) {
      // If creation fails, stop loading spinner and show error
      setDialogState(() {
        _dialogError = 'Failed to create event: $error';
        _isCreating = false;
      });
    }
  }
}
