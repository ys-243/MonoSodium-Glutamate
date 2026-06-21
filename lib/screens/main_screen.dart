import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'communities_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Add variable to track where we came from.
  int _currentIndex = 0;
  int _previousIndex = 0; 

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onTabSelected: (index) {
          setState(() {
            _previousIndex = _currentIndex; // Track before changing
            _currentIndex = index;
          });
        },
      ),
      const CommunitiesScreen(),
      const EventsScreen(),
      ProfileScreen(
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Updated AnimatedSwitcher with directional logic
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Check if we are moving L to R or R to L.
          final isMovingRight = _currentIndex > _previousIndex;
          
          Offset beginOffset;
          
          // Determine if this specific child widget is the incoming or outgoing screen
          if (child.key == ValueKey<int>(_currentIndex)) {
            // INCOMING SCREEN: Starts off-screen and moves to center
            beginOffset = isMovingRight 
                ? const Offset(1.0, 0.0)   // Come from the right
                : const Offset(-1.0, 0.0); // Come from the left
          } else {
            // OUTGOING SCREEN: Starts in center and moves off-screen
            beginOffset = isMovingRight 
                ? const Offset(-1.0, 0.0)  // Exit to the left
                : const Offset(1.0, 0.0);  // Exit to the right
          }

          final slideAnimation = Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return SlideTransition(
            position: slideAnimation,
            child: child,
          );
        },
        child: SizedBox(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _previousIndex = _currentIndex; //Track the previous index here too
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Communities',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}