import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/events.dart';
import '../services/event_service.dart';

class EventsScreen extends StatefulWidget {
  final String? communityId;
  final String? communityName;
  final bool showRegisteredOnly;

  const EventsScreen({
    super.key,
    this.communityId,
    this.communityName,
    this.showRegisteredOnly = false,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final EventService _eventService = EventService();

  String _searchQuery = '';
  String _selectedCommunityID = 'All'; // changed to filter by communityID (i.e community) CAA070726
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  bool _isLoading = true; // flag to indicate if events are being loaded
  String? _errorMessage;

  List<Event> _events = [];

  final Set<String> _processingRSVPs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      late final List<Event> events;

      if (widget.communityId == null) {
        // If there's no specific community ID, we show the events on the Global Events screen.
        events = await _eventService.fetchGlobalEvents();
      } else {
        // If there's a specific community ID, we show the events for that community.
        events = await _eventService.fetchCommunityEvents(widget.communityId!);
      }

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRSVP(Event event) async {
    setState(() {
      _processingRSVPs.add(event.id);
    });

    try {
      // First check if the user is already a member of this community
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final membership = await Supabase.instance.client
          .from('community_members')
          .select('role')
          .eq('community_id', event.communityId)
          .eq('user_id', userId)
          .maybeSingle();

      // If they are NOT a member, pause and ask for confirmation
      if (membership == null) {
        if (!mounted) return;
        final confirm = await showDialog<bool>( // Returns true if they click "Proceed", false if they click "Cancel" or tap outside.
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Auto-Join Community?'),
            content: const Text(
              'This event belongs to an open community you have not joined yet. RSVPing will automatically add you as a member of the community. Do you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        );

        // If they click Cancel or tap outside the dialog, abort the RSVP
        if (confirm != true) {
          setState(() {
            _processingRSVPs.remove(event.id);
          });
          return;
        }
      }

      // If confirm, RSVP and auto-join if necessary
      final autoJoined = await _eventService.rsvpToEvent(event.id, event.communityId);
      await _loadEvents(); // Refresh the list to reflect the new RSVP status

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(autoJoined
              ? "Registered for '${event.title}' and joined the community!"
              : "Registered for '${event.title}'"),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to RSVP: $error'),
        ),
      );
    } finally {
      // Turn off the loading spinner regardless of success or failure
      if (mounted) {
        setState(() {
          _processingRSVPs.remove(event.id);
        });
      }
    }
  }
  
  // Allows the user to cancel their RSVP for an event. It first shows a confirmation dialog. 
  Future<void> _handleCancelRsvp(Event event) async {
    setState(() => _processingRSVPs.add(event.id));

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel RSVP?'),
          content: Text('Are you sure you want to unregister from ${event.title}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep RSVP'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Unregister'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _processingRSVPs.remove(event.id));
        return;
      }
      
      // tell the service to cancel the RSVP.
      await _eventService.cancelRSVP(event.id);
      await _loadEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unregistered from ${event.title}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _processingRSVPs.remove(event.id));
    }
  }

  // show event details in a dialog when event card is tapped. 
  void _showEventDetailsDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(event.title),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Description 
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

                // Attendees Header 
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

                // Dynamic Attendees List 
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
                      
                      // Error State
                      if (snapshot.hasError) {
                        return Text('Error loading attendees: ${snapshot.error}');
                      }

                      // Success State
                      final attendees = snapshot.data ?? [];
                      // show msg if no attendees
                      if (attendees.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No one has registered yet. Be the first!'),
                        );
                      }

                      // Build the list of avatars and names.
                      return ListView.builder(
                        shrinkWrap: true, 
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

  List<Event> _getFilteredEvents() {
    return _events.where((event) {
      final matchesSearch =
          event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());

      final matchesCommunity =
          _selectedCommunityID == 'All' || event.communityId == _selectedCommunityID;

      return matchesSearch && matchesCommunity;
    }).toList();
  }

  List<Event> _getEventsOnSelectedDate() {
    return _getFilteredEvents()
        .where(
          (event) =>
              event.date.year == _selectedDate.year &&
              event.date.month == _selectedDate.month &&
              event.date.day == _selectedDate.day,
        )
        .toList();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _getFilteredEvents()
        .where(
          (event) =>
              event.date.year == day.year &&
              event.date.month == day.month &&
              event.date.day == day.day,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _getFilteredEvents();

    // Dynamically extract unique communities from the fetched events
    final Map<String, String> uniqueCommunities = {};
    for (var event in _events) {
      uniqueCommunities[event.communityId] = event.communityName;
    }

    // Update the chip text to show the selected community
    String filterLabel = 'Filter';
    if (_selectedCommunityID != 'All') {
      filterLabel = uniqueCommunities[_selectedCommunityID] ?? 'Filter';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showRegisteredOnly
              ? 'My Events'
              : widget.communityName != null
                  ? '${widget.communityName} Events'
                  : 'Events',
        ),
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
                  child: Chip(
                    avatar: const Icon(Icons.filter_list, size: 18),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        filterLabel,
                        overflow: TextOverflow.ellipsis, // for overflowing text
                      ),
                    ),
                  ),
                  onSelected: (value) {
                    setState(() {
                      _selectedCommunityID = value;
                    });
                  },
                  itemBuilder: (context) {
                    // Start with the default 'All' option
                    List<PopupMenuItem<String>> items = [
                      const PopupMenuItem(
                        value: 'All',
                        child: Text('All Communities'),
                      ),
                    ];

                    // Dynamically map the extracted communities into the dropdown
                    items.addAll(
                      uniqueCommunities.entries.map(
                        (entry) => PopupMenuItem(
                          value: entry.key, // communityId
                          child: Text(entry.value), // communityName
                        ),
                      ),
                    );

                    return items;
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(filteredEvents),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Event> filteredEvents) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Failed to load events',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
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
      child: TabBarView(
        controller: _tabController,
        children: [
          // Discover Tab: Only show events they haven't registered for.
          _buildEventsList(filteredEvents.where((event) => !event.isRegistered).toList()),
          // My Events Tab: Only show registered events.
          _buildEventsList(filteredEvents.where((event) => event.isRegistered).toList()),
          _buildCalendarView(),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.showRegisteredOnly
                      ? 'You have not registered for any events yet'
                      : 'No events found',
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildEventCard(Event event) {
    final isFull = event.capacity > 0 && event.attendees >= event.capacity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: () => _showEventDetailsDialog(event), // show event details dialog when card is tapped
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
                  _buildCommunityChip(event.communityName, event.communityLevel),
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
              _buildEventInfo(
                Icons.calendar_today,
                '${event.date.day}/${event.date.month}/${event.date.year}',
              ),

              const SizedBox(height: 4),
              _buildEventInfo(Icons.access_time, event.time),

              const SizedBox(height: 4),
              _buildEventInfo(Icons.location_on, event.location),

              const SizedBox(height: 4),
              _buildEventInfo(
                Icons.people,
                event.capacity > 0
                    ? '${event.attendees} / ${event.capacity} attending'
                    : '${event.attendees} attending',
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'By ${event.organiser}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 12),
                  if (event.isRegistered) 
                    OutlinedButton(
                      onPressed: _processingRSVPs.contains(event.id)
                          ? null
                          : () => _handleCancelRsvp(event),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5)),
                      ),
                      child: _processingRSVPs.contains(event.id)
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Unregister'),
                    )
                  
                  else if (isFull)
                    const OutlinedButton(
                      onPressed: null,
                      child: Text('Full'),
                    )
                    
                  else
                    FilledButton(
                      // Disable the button when processing
                      onPressed: _processingRSVPs.contains(event.id) 
                          ? null 
                          : () => _handleRSVP(event),
                      // change to spinner 
                      child: _processingRSVPs.contains(event.id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('RSVP'),
                    ),
                ],
              ),
            ],
          ),
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
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityChip(String communityName, String level) {
    Color color;

    switch (level.toLowerCase()) {
      case 'intimate': color = Colors.purple; break;
      case 'closed': color = Colors.blue; break;
      case 'open': color = Colors.green; break;
      default: color = Colors.grey;
    }

    return Chip(
      label: Text(
        communityName,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildCalendarView() {
    final eventsOnSelectedDate = _getEventsOnSelectedDate();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar<Event>(
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