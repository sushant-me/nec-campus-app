// lib/features/home/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nec_app/features/auth/screens/login_screen.dart';
import 'package:nec_app/features/events/screens/events_screen.dart';
import 'package:nec_app/features/gallery/screens/gallery_albums_screen.dart';
import 'package:nec_app/features/hod_portal/screens/hod_dashboard.dart'; // <-- 1. Import HOD dashboard
import 'package:nec_app/features/notices/screens/notice_board_screen.dart';
import 'package:nec_app/features/schedule/screens/schedule_screen.dart';
import 'package:nec_app/features/student_portal/screens/student_dashboard.dart';
import 'package:nec_app/features/teacher_portal/screens/teacher_dashboard.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      RoleSpecificDashboard(user: widget.user),
      NoticeBoardScreen(user: widget.user),
      ScheduleScreen(user: widget.user),
      const EventsScreen(),
      const GalleryAlbumsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nepal Engineering College'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Notices'),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: 'Gallery',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

// At the bottom of lib/features/home/screens/home_screen.dart

class RoleSpecificDashboard extends StatelessWidget {
  final User user;
  const RoleSpecificDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // --- UPDATED: Use a StreamBuilder ---
    // This listens for the user document to be created or updated in real-time.
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // This handles the case where the user has been created in Auth,
        // but their document is not yet in Firestore.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Finalizing user setup...'),
              ],
            ),
          );
        }

        final userData = snapshot.data!;
        // Safely get the role with a fallback
        final role =
            (userData.data() as Map<String, dynamic>?)?['role'] ?? 'unknown';

        switch (role) {
          case 'student':
            return StudentDashboard(user: user);
          case 'teacher':
            final teacherName =
                (userData.data() as Map<String, dynamic>?)?['name'] ??
                'Unknown Teacher';
            return TeacherDashboard(teacherName: teacherName);
          case 'hod':
            return const HodDashboard();
          default:
            return const Center(child: Text('Unknown user role.'));
        }
      },
    );
  }
}
