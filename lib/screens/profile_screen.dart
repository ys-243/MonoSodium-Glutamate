import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  
  // State variables to hold the user's profile data and loading state
  String _userEmail = '';
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;

  late TabController _tabController;
  String _searchQuery = '';

  late final TextEditingController _nameController;
  late final TextEditingController _schoolController;
  late final TextEditingController _majorController;
  late final TextEditingController _yearController;

  // Change to Supabase data fetching in the future.
  final List<Map<String, String>> _friends = [
    {'name': 'Alice Tan', 'major': 'Computer Science', 'year': 'Year 3'},
    {'name': 'Bob Chen', 'major': 'Business Analytics', 'year': 'Year 2'},
    {'name': 'Clara Wong', 'major': 'Engineering', 'year': 'Year 4'},
    {'name': 'David Lim', 'major': 'Medicine', 'year': 'Year 1'},
    {'name': 'Emma Koh', 'major': 'Law', 'year': 'Year 3'},
  ];

  // This too.
  final List<Map<String, dynamic>> _personalEvents = [
    {
      'title': 'CS2103 Tutorial',
      'date': DateTime(2026, 5, 12),
      'time': '10:00 AM',
      'location': 'COM1-0210'
    },
    {
      'title': 'Study Group Meeting',
      'date': DateTime(2026, 5, 13),
      'time': '2:00 PM',
      'location': 'Central Library'
    },
    {
      'title': 'Hackathon Prep',
      'date': DateTime(2026, 5, 15),
      'time': '6:00 PM',
      'location': 'i3 Lab'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialise controllers for the Settings tab
    _nameController = TextEditingController();
    _schoolController = TextEditingController();
    _majorController = TextEditingController();
    _yearController = TextEditingController();

    // Trigger the database fetch
    _fetchProfileData();
  }

  // Fetch the user's profile data from Supabase and populate the state variables and controllers. 
  Future<void> _fetchProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch the row from the profiles table
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        // If user really doesn't have a profile yet.
        setState(() => _isLoadingProfile = false);
        return;
      }

      // Once data found, 
      if (mounted) {
        // Update the state with the fetched profile data.
        setState(() {
          _profileData = data;
          
          // Populate the controllers for the Settings tab
          _nameController.text = data['user_name'] ?? '';
          _schoolController.text = data['school'] ?? '';
          _majorController.text = data['major'] ?? '';
          _yearController.text = data['year_of_study'] ?? '';
          _userEmail = user.email ?? '';
          
          _isLoadingProfile = false;
        });
      }
      //show error if fetching profile data fails
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

// Function to get initials from the user's name for the avatar, used for the CircleAvatar in the Profile tab. If name not available, return '?'.
String _getInitials() {
  if (_profileData == null) return '?';
  String firstName = _profileData!['first_name'] ?? '';
  String lastName = _profileData!['last_name'] ?? '';
    
  if (firstName.isNotEmpty && lastName.isNotEmpty) {
    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  } else if (firstName.isNotEmpty) {
    return firstName[0].toUpperCase();
  }
  return '?';
}

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _schoolController.dispose();
    _majorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Calendar'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  child: _isLoadingProfile
                      ? const CircularProgressIndicator()
                      : Text(
                          _getInitials(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoadingProfile ? 'Loading...' : _profileData?['user_name'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingProfile ? 'Loading...' : '${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingProfile 
                            ? '...' 
                            : '${_profileData?['school'] ?? ''} • ${_profileData?['major'] ?? ''}, ${_profileData?['year_of_study'] ?? ''}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _isLoadingProfile ? '...' : _profileData?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                _buildFriendsTab(),
                _buildCalendarTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    final filteredFriends = _friends
        .where((friend) =>
            friend['name']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Friends (${_friends.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Manage connections'),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _showAddFriendDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search friends...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...filteredFriends.map((friend) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(friend['name']!.substring(0, 1)),
                ),
                title: Text(friend['name']!),
                subtitle: Text('${friend['major']} • ${friend['year']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {},
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildCalendarTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Personal Calendar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Your upcoming events and commitments'),
        const SizedBox(height: 16),
        ..._personalEvents.map((event) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getMonthName(event['date'].month),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${event['date'].day}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 18,
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
                            event['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event['time'],
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            event['location'],
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Deprecated profile settings, might change to a seperate screen in the future.
        
        // const Text(
        //   'Profile Settings',
        //   style: TextStyle(
        //     fontSize: 20,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        // const SizedBox(height: 16),
        // Card(
        //   child: Padding(
        //     padding: const EdgeInsets.all(16),
        //     child: Column(
        //       children: [
        //         TextField(
        //           decoration: const InputDecoration(labelText: 'Full Name'),
        //           controller: _nameController,
        //         ),
        //         const SizedBox(height: 16),
        //         TextField(
        //           decoration: const InputDecoration(labelText: 'Major'),
        //           controller: _majorController,
        //         ),
        //         const SizedBox(height: 16),
        //         TextField(
        //           decoration: const InputDecoration(labelText: 'Year of Study'),
        //           controller: _yearController,
        //         ),
        //       ],
        //     ),
        //   ),
        // ),

        const SizedBox(height: 24),
        const Text(
          'App Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle:
                    const Text('Receive updates about events and communities'),
                value: true,
                onChanged: (value) {},
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Get real-time alerts on your device'),
                value: true,
                onChanged: (value) {},
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Show Online Status'),
                subtitle: const Text("Let friends see when you're active"),
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.logout),
          label: const Text(
            'Log Out',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of PlanNUS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
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

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a Friend'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'friend@u.nus.edu',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}
