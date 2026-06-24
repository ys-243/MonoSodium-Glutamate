import 'package:flutter/material.dart';
import 'package:plannus/models/community.dart';
import 'package:plannus/services/community_service.dart';
import 'communities_details.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final CommunityService _communityService = CommunityService();
  List<Community> _allCommunities = [];
  bool _isLoading = true;

  // For creating a new community
  CommunityLevel _selectedLevel = CommunityLevel.open; // Default level for new communities
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Initial fetch of communities
    _fetchCommunities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommunities() async {
    setState(() => _isLoading = true);
    try {
      final communities = await _communityService.getCommunities();
      if (mounted) {
        setState(() {
          _allCommunities = communities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading communities: $e')),
        );
      }
    }
  }

  List<Community> _getFilteredCommunities() {
    var filtered = _allCommunities.where((community) {
      final matchesSearch = community.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          community.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    switch (_tabController.index) {
      case 1:
        return filtered.where((c) => c.isJoined).toList();
      case 2:
        return filtered.where((c) => c.level == CommunityLevel.intimate).toList();
      case 3:
        return filtered.where((c) => c.level == CommunityLevel.closed).toList();
      case 4:
        return filtered.where((c) => c.level == CommunityLevel.open).toList();
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCommunityDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'My Communities'),
            Tab(text: 'Intimate'),
            Tab(text: 'Closed'),
            Tab(text: 'Open'),
          ],
          onTap: (index) => setState(() {}),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // show loading spinner while fetching
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                hintText: 'Search communities...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommunityList(_getFilteredCommunities()),
                _buildCommunityList(_getFilteredCommunities()),
                _buildCommunityList(_getFilteredCommunities(), showLevelInfo: true, level: CommunityLevel.intimate),
                _buildCommunityList(_getFilteredCommunities(), showLevelInfo: true, level: CommunityLevel.closed),
                _buildCommunityList(_getFilteredCommunities(), showLevelInfo: true, level: CommunityLevel.open),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityList(List<Community> communities, {bool showLevelInfo = false, CommunityLevel? level}) {
    return RefreshIndicator(
      onRefresh: _fetchCommunities,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (showLevelInfo && level != null) ...[
            _buildLevelInfoCard(level),
            const SizedBox(height: 16),
          ],
          ...communities.map((community) => _buildCommunityCard(community)),
        ],
      ),
    );
  }

  Widget _buildLevelInfoCard(CommunityLevel level) {
    IconData icon;
    Color color;
    String title;
    String description;

    switch (level) {
      case CommunityLevel.intimate:
        icon = Icons.lock;
        color = Colors.purple;
        title = 'Intimate Communities';
        description =
            'Private spaces for close groups with full privacy and no content moderation. Perfect for study groups and friend circles.';
        break;
      case CommunityLevel.closed:
        icon = Icons.lock_outline;
        color = Colors.blue;
        title = 'Closed Communities';
        description =
            'Require approval to join. Content is moderated for hate speech, racism, and inappropriate content to maintain a safe environment.';
        break;
      case CommunityLevel.open:
        icon = Icons.public;
        color = Colors.green;
        title = 'Open Communities';
        description =
            'Public communities anyone can join. Content is actively moderated to ensure a welcoming and respectful environment for all members.';
        break;
    }

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetailScreen(community: community),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildLevelChip(community.level),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                community.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${community.members} members',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${community.posts} posts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (community.isJoined)
                    Chip(
                      label: const Text('Joined', style: TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(CommunityLevel level) {
    IconData icon;
    Color color;
    String label;

    switch (level) {
      case CommunityLevel.intimate:
        icon = Icons.lock;
        color = Colors.purple;
        label = 'Intimate';
        break;
      case CommunityLevel.closed:
        icon = Icons.lock_outline;
        color = Colors.blue;
        label = 'Closed';
        break;
      case CommunityLevel.open:
        icon = Icons.public;
        color = Colors.green;
        label = 'Open';
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  void _showCreateCommunityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Community'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Community Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CommunityLevel>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(labelText: 'Community Level'),
              items: const [
                DropdownMenuItem(value: CommunityLevel.intimate, child: Text('Intimate')),
                DropdownMenuItem(value: CommunityLevel.closed, child: Text('Closed')),
                DropdownMenuItem(value: CommunityLevel.open, child: Text('Open')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedLevel = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Show a loading indicator in a real app, but for now:
              await _communityService.createCommunity(
                _nameController.text,
                _descController.text,
                _selectedLevel,
              );
              
              _nameController.clear();
              _descController.clear();
              if (context.mounted) {
                Navigator.pop(context);
                _fetchCommunities();
                setState(() {}); // Refresh the screen to show the new data
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
