import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  
  // State variables to hold the user's profile data and loading state
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;

  bool _isLoadingCalendar = true;
  bool _isImportingNusMods = false;

  late TabController _tabController;
  String _searchQuery = '';

  late final TextEditingController _nameController;
  late final TextEditingController _schoolController;
  late final TextEditingController _majorController;
  late final TextEditingController _yearController;
  late final TextEditingController _nusModsLinkController;

  String _selectedAcadYear = '2026-2027'; // Default academic year for the calendar tab
  int _selectedSemester = 1; // Default semester for the calendar tab
  List<Map<String, dynamic>> _personalCalendarEvents = []; // List to hold personal calendar events fetched from Supabase

  // Change to Supabase data fetching in the future.
  final List<Map<String, String>> _friends = [
    {'name': 'Alice Tan', 'major': 'Computer Science', 'year': 'Year 3'},
    {'name': 'Bob Chen', 'major': 'Business Analytics', 'year': 'Year 2'},
    {'name': 'Clara Wong', 'major': 'Engineering', 'year': 'Year 4'},
    {'name': 'David Lim', 'major': 'Medicine', 'year': 'Year 1'},
    {'name': 'Emma Koh', 'major': 'Law', 'year': 'Year 3'},
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
    _nusModsLinkController = TextEditingController();

    // Trigger the database fetch
    _fetchProfileData();
    _fetchPersonalCalendarEvents();
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

  Future<void> _fetchPersonalCalendarEvents() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now().toUtc();

      // Fetch the personal calendar events from the 'personal_calendar' table
      final data = await Supabase.instance.client
          .from('personal_calendar_events')
          .select()
          .eq('user_id', user.id)
          .gte('end_at', now.toIso8601String())
          .order('start_at', ascending: true)
          .limit(50);

      if (!mounted) return; 
      setState(() {
        _personalCalendarEvents = List<Map<String, dynamic>>.from(data);
        _isLoadingCalendar = false;
      });
    } catch (e) {
      if (!mounted) return; 
        
      setState(() => _isLoadingCalendar = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading calendar events: $e')),
      );
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
    _nusModsLinkController.dispose();
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
    return RefreshIndicator(
      onRefresh: _fetchPersonalCalendarEvents,
      child: ListView(
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
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Import NUSMods Timetable'),
              subtitle: const Text(
                'Paste your NUSMods sharelink to update your availability',
              ),
              trailing: _isImportingNusMods
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
              onTap: _isImportingNusMods ? null : _showNusModsImportDialog, 
            ),
          ),

          const SizedBox(height: 16),

          if (_isLoadingCalendar)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_personalCalendarEvents.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size:40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No personal calendar events yet.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Import your NUSMods timetable',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else 
            ..._personalCalendarEvents.map(
              (event) => _buildCalendarEventCard(event),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarEventCard(Map<String, dynamic> event) {
    final startAt = DateTime.parse(event['start_at']).toLocal();
    final endAt = DateTime.parse(event['end_at']).toLocal();

    final source = event['source']?.toString() ?? 'manual';
    final venue = event['venue']?.toString();
    final title = event['title']?.toString() ?? 'Busy';

    return Card(
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
                    _getMonthName(startAt.month),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${startAt.day}',
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
                  Row(
                    children: [
                      if (source == 'nusmods') ...[
                        const Icon(Icons.school, size: 16),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCalendarDate(startAt)} • ${_formatTimeRange(startAt, endAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (venue != null && venue.isNotEmpty)
                    Text(
                      venue,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (source == 'nusmods')
                    Text(
                      'NUSMods • Busy only',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deletePersonalCalendarEvent(event['id']),
            ),
          ],
        ),
      ),
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


  Future<void> _showNusModsImportDialog() async {
    _nusModsLinkController.clear();

    String acadYear = _selectedAcadYear;
    int semester = _selectedSemester;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Import NUSMods Timetable'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Paste your NUSMods share link. Your lessons will be saved as busy timings in your personal calendar.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nusModsLinkController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'NUSMods Share Link',
                        hintText:
                            'https://nusmods.com/timetable/sem-1/share?...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: acadYear,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year',
                        hintText: '2026-2027',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        acadYear = value.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: semester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Semester 1'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Semester 2'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          semester = value;
                        });
                      },
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
                  onPressed: () {
                    final link = _nusModsLinkController.text.trim();

                    if (link.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please paste a NUSMods link.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    _importNusModsTimetable(
                      shareLink: link,
                      acadYear: acadYear,
                      fallbackSemester: semester,
                    );
                  },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _importNusModsTimetable({
    required String shareLink,
    required String acadYear,
    required int fallbackSemester,
  }) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to import your timetable.'),
        ),
      );
      return;
    }

    setState(() {
      _isImportingNusMods = true;
    });

    try {
      final parsedSemester = _parseSemesterFromNusModsLink(shareLink);
      final semester = parsedSemester ?? fallbackSemester;

      final selectedLessons = _parseNusModsShareLink(shareLink);

      if (selectedLessons.isEmpty) {
        throw Exception(
          'No modules found in the link. Please copy the Share/Sync link from NUSMods.',
        );
      }

      final List<Map<String, dynamic>> rowsToInsert = [];

      for (final moduleEntry in selectedLessons.entries) {
        final moduleCode = moduleEntry.key;
        final selectedLessonTypes = moduleEntry.value;

        final moduleData = await _fetchNusModsModule(
          acadYear: acadYear,
          moduleCode: moduleCode,
        );

        final moduleTitle = moduleData['title']?.toString() ?? moduleCode;

        final semesterData = _findSemesterData(
          moduleData: moduleData,
          semester: semester,
        );

        if (semesterData == null) {
          debugPrint('No semester data found for $moduleCode semester $semester');
          continue;
        }

        final timetable = semesterData['timetable'];

        if (timetable is! List) {
          debugPrint('No timetable found for $moduleCode');
          continue;
        }

        for (final selectedLessonEntry in selectedLessonTypes.entries) {
          final selectedLessonTypeShort = selectedLessonEntry.key;
          final selectedClassNo = selectedLessonEntry.value;

          final selectedLessonTypeFull =
              _normaliseNusModsLessonType(selectedLessonTypeShort);

          final matchingLessons = timetable.where((lesson) {
            if (lesson is! Map) return false;

            final apiLessonType = lesson['lessonType']?.toString();
            final apiClassNo = lesson['classNo']?.toString();

            return apiLessonType == selectedLessonTypeFull &&
                apiClassNo == selectedClassNo;
          }).toList();

          for (final rawLesson in matchingLessons) {
            final lesson = Map<String, dynamic>.from(rawLesson as Map);

            final day = lesson['day']?.toString();
            final startTime = lesson['startTime']?.toString();
            final endTime = lesson['endTime']?.toString();
            final venue = lesson['venue']?.toString();
            final weeks = lesson['weeks'];

            if (day == null ||
                startTime == null ||
                endTime == null ||
                weeks is! List) {
              continue;
            }

            final weekNumbers = weeks
                .whereType<num>()
                .map((week) => week.toInt())
                .where((week) => week > 0)
                .toList();

            for (final weekNumber in weekNumbers) {
              final lessonDate = _dateForNusModsWeek(
                acadYear: acadYear,
                semester: semester,
                weekNumber: weekNumber,
                day: day,
              );

              final startDateTimeSingapore = _combineDateAndTime(
                lessonDate,
                startTime,
              );

              final endDateTimeSingapore = _combineDateAndTime(
                lessonDate,
                endTime,
              );

              final startAtUtc = _singaporeTimeToUtc(startDateTimeSingapore);
              final endAtUtc = _singaporeTimeToUtc(endDateTimeSingapore);

              rowsToInsert.add({
                'user_id': currentUser.id,
                'title': '$moduleCode $selectedLessonTypeFull',
                'source': 'nusmods',
                'source_ref':
                    '$acadYear-sem$semester-$moduleCode-$selectedLessonTypeShort-$selectedClassNo-week$weekNumber',
                'module_code': moduleCode,
                'module_title': moduleTitle,
                'lesson_type': selectedLessonTypeFull,
                'class_no': selectedClassNo,
                'venue': venue,
                'start_at': startAtUtc.toIso8601String(),
                'end_at': endAtUtc.toIso8601String(),
                'is_busy': true,
                'visibility': 'busy_only',
                'academic_year': acadYear,
                'semester': semester,
              });
            }
          }
        }
      }

      if (rowsToInsert.isEmpty) {
        throw Exception(
          'No matching lesson slots were found. Check your academic year and semester.',
        );
      }

      await supabase
          .from('personal_calendar_events')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('source', 'nusmods')
          .eq('academic_year', acadYear)
          .eq('semester', semester);

      await supabase.from('personal_calendar_events').insert(rowsToInsert);

      if (!mounted) return;

      setState(() {
        _selectedAcadYear = acadYear;
        _selectedSemester = semester;
      });

      await _fetchPersonalCalendarEvents();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${rowsToInsert.length} NUSMods busy timings.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import NUSMods timetable: $error'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isImportingNusMods = false;
      });
    }
  }

  Map<String, Map<String, String>> _parseNusModsShareLink(String link) {
    final uri = Uri.parse(link);
    final result = <String, Map<String, String>>{};

    uri.queryParameters.forEach((key, value) {
      final moduleCode = key.trim().toUpperCase();

      if (!_looksLikeNusModuleCode(moduleCode)) {
        return;
      }

      final lessonSelections = <String, String>{};

      final parts = value.split(',');

      for (final part in parts) {
        final cleanedPart = part.trim();

        if (!cleanedPart.contains(':')) {
          continue;
        }

        final colonIndex = cleanedPart.indexOf(':');

        final lessonTypeShort =
            cleanedPart.substring(0, colonIndex).trim().toUpperCase();

        final classNo = cleanedPart.substring(colonIndex + 1).trim();

        if (lessonTypeShort.isEmpty || classNo.isEmpty) {
          continue;
        }

        lessonSelections[lessonTypeShort] = classNo;
      }

      if (lessonSelections.isNotEmpty) {
        result[moduleCode] = lessonSelections;
      }
    });

    return result;
  }

  bool _looksLikeNusModuleCode(String value) {
    final regex = RegExp(r'^[A-Z]{2,4}\d{4}[A-Z]{0,3}$');
    return regex.hasMatch(value);
  }

  int? _parseSemesterFromNusModsLink(String link) {
    final uri = Uri.parse(link);

    for (final segment in uri.pathSegments) {
      if (segment.startsWith('sem-')) {
        final semText = segment.replaceFirst('sem-', '');
        return int.tryParse(semText);
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> _fetchNusModsModule({
    required String acadYear,
    required String moduleCode,
  }) async {
    final cleanedAcadYear = _normaliseAcadYear(acadYear);

    final url = Uri.parse(
      'https://api.nusmods.com/v2/$cleanedAcadYear/modules/$moduleCode.json',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Could not fetch $moduleCode from NUSMods. Status: ${response.statusCode}',
      );
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Map<String, dynamic>? _findSemesterData({
    required Map<String, dynamic> moduleData,
    required int semester,
  }) {
    final semesterDataList = moduleData['semesterData'];

    if (semesterDataList is! List) {
      return null;
    }

    for (final item in semesterDataList) {
      if (item is! Map) continue;

      final itemSemester = item['semester'];

      if (itemSemester == semester) {
        return Map<String, dynamic>.from(item);
      }
    }

    return null;
  }

  String _normaliseAcadYear(String acadYear) {
    final cleaned = acadYear.trim().replaceAll('/', '-');

    final regex = RegExp(r'^\d{4}-\d{4}$');

    if (!regex.hasMatch(cleaned)) {
      throw Exception('Academic year must look like 2026-2027.');
    }

    return cleaned;
  }
  String _normaliseNusModsLessonType(String shortCode) {
    switch (shortCode.toUpperCase()) {
      case 'LEC':
        return 'Lecture';
      case 'TUT':
        return 'Tutorial';
      case 'LAB':
        return 'Laboratory';
      case 'SEC':
        return 'Sectional Teaching';
      case 'REC':
        return 'Recitation';
      case 'SEM':
        return 'Seminar-Style Module Class';
      case 'WS':
        return 'Workshop';
      default:
        return shortCode;
    }
  }

  DateTime _dateForNusModsWeek({
    required String acadYear,
    required int semester,
    required int weekNumber,
    required String day,
  }) {
    final weekOneMonday = _getEstimatedWeekOneMonday(
      acadYear: acadYear,
      semester: semester,
    );

    final dayOffset = _dayOffset(day);

    return weekOneMonday.add(
      Duration(
        days: ((weekNumber - 1) * 7) + dayOffset,
      ),
    );
  }

  DateTime _getEstimatedWeekOneMonday({
    required String acadYear,
    required int semester,
  }) {
    final years = acadYear.split('-');

    if (years.length != 2) {
      throw Exception('Academic year must look like 2026-2027.');
    }

    final startYear = int.tryParse(years[0]);
    final endYear = int.tryParse(years[1]);

    if (startYear == null || endYear == null) {
      throw Exception('Invalid academic year: $acadYear');
    }

    if (semester == 1) {
      final orientationMonday = _firstMondayOfMonth(
        startYear,
        DateTime.august,
      );

      return orientationMonday.add(const Duration(days: 7));
    }

    if (semester == 2) {
      final firstMonday = _firstMondayOfMonth(
        endYear,
        DateTime.january,
      );

      return firstMonday.add(const Duration(days: 7));
    }

    throw Exception('Only Semester 1 and Semester 2 are supported for now.');
  }

  DateTime _firstMondayOfMonth(int year, int month) {
    var date = DateTime(year, month, 1);

    while (date.weekday != DateTime.monday) {
      date = date.add(const Duration(days: 1));
    }

    return date;
  }

  int _dayOffset(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 0;
      case 'tuesday':
        return 1;
      case 'wednesday':
        return 2;
      case 'thursday':
        return 3;
      case 'friday':
        return 4;
      case 'saturday':
        return 5;
      case 'sunday':
        return 6;
      default:
        throw Exception('Unknown day: $day');
    }
  }

  DateTime _combineDateAndTime(DateTime date, String timeText) {
    if (timeText.length != 4) {
      throw Exception('Invalid time format: $timeText');
    }

    final hour = int.parse(timeText.substring(0, 2));
    final minute = int.parse(timeText.substring(2, 4));

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  DateTime _singaporeTimeToUtc(DateTime singaporeDateTime) {
    return DateTime.utc(
      singaporeDateTime.year,
      singaporeDateTime.month,
      singaporeDateTime.day,
      singaporeDateTime.hour - 8,
      singaporeDateTime.minute,
    );
  }

  Future<void> _deletePersonalCalendarEvent(String eventId) async {
    try {
      await Supabase.instance.client
          .from('personal_calendar_events')
          .delete()
          .eq('id', eventId);

      await _fetchPersonalCalendarEvents();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calendar event deleted.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting event: $e')),
      );
    }
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

  String _formatCalendarDate(DateTime date) {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} ${_getMonthName(date.month)}';
  }

  String _formatTimeRange(DateTime startAt, DateTime endAt) {
    return '${_formatTime(startAt)} - ${_formatTime(endAt)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
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
