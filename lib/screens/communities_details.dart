import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plannus/models/community.dart';
import 'package:plannus/services/community_service.dart';
import 'package:plannus/models/events.dart';
import 'package:plannus/services/event_service.dart';
import 'package:plannus/models/post.dart';
import 'package:plannus/services/post_service.dart';
import 'package:plannus/screens/post_details.dart';


class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Text boxes
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _postTitleController = TextEditingController();
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventTimeController = TextEditingController();
  final TextEditingController _eventEndTimeController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();

  // Services
  final EventService _eventService = EventService();
  final CommunityService _communityService = CommunityService();
  final PostService _postService = PostService();

  // State variables for events
  List<Event> _events = [];
  bool _isLoadingEvents = true;
  String? _eventsError;

  // State variables for event creation dialog
  bool _isCreating = false;
  String? _dialogError;

  // State variables for posts
  List<Post> _posts = [];
  bool _isLoadingPosts = true;
  bool _isPosting = false;

  // State variables for members
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = true;
  String? _membersError;
  
  CommunityRole? _currentRole;
  bool _isJoining = false;

  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoadingRequests = true;

  bool get _isApprovedMember => 
      _currentRole == CommunityRole.owner || 
      _currentRole == CommunityRole.admin || 
      _currentRole == CommunityRole.member;
  
  bool get _canEdit => 
    widget.community.currentUserRole == CommunityRole.owner || 
    widget.community.currentUserRole == CommunityRole.admin;
      
  bool get _isPending => _currentRole == CommunityRole.pending;

  @override
  void initState() {
    super.initState();

    // Shows the Admin tab only if the user is an owner or admin of the community.
    _tabController = TabController(length: _canEdit? 4 : 3, vsync: this);
    _currentRole = widget.community.currentUserRole;
    
    _loadEvents(); 
    _loadMembers();
    _loadPosts(); 

    if (_canEdit) {
      _loadPendingRequests(); // Fetch the waitlist if they are an admin
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Discussions'),
            const Tab(text: 'Events'),
            const Tab(text: 'Members'),
            if (_canEdit) const Tab(text: 'Admin'), // Only shows for owners/admins
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

          // Join/Pending Banner
          if (!_isApprovedMember)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: _isPending 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text('Your request to join is pending approval.', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                : FilledButton.icon(
                    onPressed: _isJoining ? null : _handleJoin,
                    icon: _isJoining 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(widget.community.level == CommunityLevel.open ? Icons.group_add : Icons.lock_person),
                    label: Text(widget.community.level == CommunityLevel.open ? 'Join Community' : 'Request to Join'),
                  ),
            ),

          // Tab Content (Locked if not a member)
          Expanded(
            child: (!_isApprovedMember && widget.community.level != CommunityLevel.open)
                ? const Center(
                    child: Text(
                      'You must join this community to view its content.',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDiscussionsTab(),
                      _buildEventsTab(),
                      _buildMembersTab(),
                      if (_canEdit) _buildAdminTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsTab() {
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create a Post', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _postTitleController,
                    decoration: const InputDecoration(hintText: 'Discussion Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _postController,
                    decoration: const InputDecoration(hintText: 'Share your thoughts with the community!'),
                    maxLines: 8,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isPosting ? null : _handleCreatePost,
                      icon: _isPosting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.send),
                      label: const Text('Post'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recent Discussions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (_isLoadingPosts)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_posts.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No discussions yet. Be the first to post!')))
          else
            ..._posts.map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPostCard(post),
                )),
        ],
      ),
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
          final name = member['name'];
          final role = member['role'];
          final memberUserId = member['user_id']; // Using the ID we ensured was returned
          
          final currentUserId = Supabase.instance.client.auth.currentUser!.id;

          // Can only remove if you are an admin/owner, and the target is not yourself nor the owner.
          final canRemove = _canEdit && memberUserId != currentUserId && role != 'owner';
          final canPromote = _currentRole == CommunityRole.owner && role == 'member';
          final canDemote = _currentRole == CommunityRole.owner && role == 'admin';

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
              
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (role == 'owner' || role == 'admin')
                    Tooltip(
                      // show whether they are the owner or an admin
                      message: role == 'owner' ? 'Community Owner' : 'Community Admin',
                      triggerMode: TooltipTriggerMode.tap, 
                      child: Icon(Icons.shield, color: Theme.of(context).colorScheme.primary, size: 20),
                    ),
                    
                  // Promote Button
                  if (canPromote) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.stars, color: Colors.amber),
                      tooltip: 'Promote to Admin',
                      onPressed: () => _confirmPromoteMember(memberUserId, name),
                    ),
                  ],

                  // Demote Button
                  if (canDemote) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_moderator, color: Colors.orange),
                      tooltip: 'Demote to Member',
                      onPressed: () => _confirmDemoteMember(memberUserId, name),
                    ),
                  ],

                  // Remove Button
                  if (canRemove) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      tooltip: 'Remove Member',
                      onPressed: () => _confirmRemoveMember(memberUserId, name),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminTab() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pending Join Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          if (_pendingRequests.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No pending requests at the moment.'),
              ),
            )
          else
            ..._pendingRequests.map((request) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    request['name'][0].toUpperCase(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
                title: Text(request['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(request['email']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // REJECT BUTTON
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () async {
                        try {
                          await _communityService.rejectMember(widget.community.id, request['user_id']);
                          _loadPendingRequests(); // Refresh list after action
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error rejecting: $e')));
                        }
                      },
                    ),
                    // APPROVE BUTTON
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Approve',
                      style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1)),
                      onPressed: () async {
                        try {
                          await _communityService.approveMember(widget.community.id, request['user_id']);
                          _loadPendingRequests(); // Refresh list after action
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member approved!')));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error approving: $e')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
          );
          _loadPosts(); 
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(post.creatorName[0])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.creatorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _formatTimeAgo(post.createdAt),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                post.title, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              
              Text(post.content),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: null, 
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text('${post.repliesCount} Replies'),
              ),
            ],
          ),
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

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await _postService.fetchCommunityPosts(widget.community.id);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPosts = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load posts: $e')));
    }
  }

  // Load pending requests for admin users.
  Future<void> _loadPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final requests = await _communityService.fetchPendingMembers(widget.community.id);
      if (!mounted) return;
      setState(() {
        _pendingRequests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRequests = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load requests: $e')),
      );
    }
  }

  // Handle the join or request to join action based on community level.
  Future<void> _handleJoin() async {
    setState(() => _isJoining = true);
    try {
      final newRole = await _communityService.joinCommunity(
        widget.community.id, 
        widget.community.level
      );
      
      if (!mounted) return;
      setState(() {
        _currentRole = newRole;
        _isJoining = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newRole == CommunityRole.pending 
            ? 'Request sent! Waiting for admin approval.' 
            : 'Successfully joined the community!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join: $e')),
      );
    }
  }

  Future<void> _handleCreatePost() async {
    final title = _postTitleController.text.trim();
    final content = _postController.text.trim();
    
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the title and content for the post.'))
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      // create the post using service
      await _postService.createPost(widget.community.id, title, content);
      
      // clear the text
      _postTitleController.clear();
      _postController.clear();

      FocusScope.of(context).unfocus(); 
      // force refresh the posts list to show the new post
      await _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  // Confirm and remove a member from the community.
  Future<void> _confirmRemoveMember(String userId, String userName) async {
    // Show confirmation popup
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $userName from the community?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    // If button pressed confirmed, then remove.
    if (confirm == true) {
      try {
        await _communityService.removeMember(widget.community.id, userId);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName was removed.')),
        );
        
        _loadMembers(); // Refresh the list again
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing member: $e')),
        );
      }
    }
  }

  Future<void> _confirmPromoteMember(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text('Are you sure you want to promote $userName to an Admin? They will be able to moderate content and manage the waitlist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    // If confirmed, update the role.
    if (confirm == true) {
      try {
        await _communityService.promoteToAdmin(widget.community.id, userId);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName is now an Admin!')),
        );
        
        _loadMembers(); // Refresh the list to reflect the new role
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error promoting member: $e')),
        );
      }
    }
  }

  Future<void> _confirmDemoteMember(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demote Admin'),
        content: Text('Are you sure you want to demote $userName to a regular member? They will lose their moderation privileges.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange, // Warning color
            ),
            child: const Text('Demote'),
          ),
        ],
      ),
    );

    // If confirmed, update the role.
    if (confirm == true) {
      try {
        await _communityService.demoteToMember(widget.community.id, userId);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName was demoted to a regular member.')),
        );
        
        _loadMembers(); // Refresh the list to reflect the new role
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error demoting member: $e')),
        );
      }
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
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: event.isRegistered
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(92, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text('Registered'),
                        )
                      : FilledButton(
                          onPressed: () async {
                            try {
                              await _eventService.rsvpToEvent(
                                event.id,
                                event.communityId,
                              );

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Registration successful. A reminder will be sent 1 hour before the event.',
                                  ),
                                ),
                              );

                              await _loadEvents();
                            } catch (error) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Registration failed: $error'),
                                ),
                              );
                            }
                          },

                          style: FilledButton.styleFrom(
                            minimumSize: const Size(72, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(fontSize: 13),
                          ),

                          child: const Text('RSVP'),
                        ),
                ),
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
      final DateTime startDateTime = DateTime(
        parsedDate.year, 
        parsedDate.month, 
        parsedDate.day, 
        startTime.hour, 
        startTime.minute
      );

      final DateTime endDateTime = DateTime(
        parsedDate.year, 
        parsedDate.month, 
        parsedDate.day, 
        endTime.hour, 
        endTime.minute
      );

      await _eventService.createEvent(
        communityId: widget.community.id,
        title: _eventTitleController.text.trim(),
        date: parsedDate,
        startTime: startDateTime.toLocal(),
        endTime: endDateTime.toLocal(),
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
