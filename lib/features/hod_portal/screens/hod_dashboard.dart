// lib/features/hod_portal/screens/hod_dashboard.dart
import 'package:flutter/material.dart';
import 'assign_subjects_screen.dart'; // <-- 1. Import
import 'manage_events_screen.dart';
import 'manage_gallery_screen.dart';
import 'post_notice_screen.dart';
import 'promote_batch_screen.dart';
import 'upload_schedule_screen.dart';

class HodDashboard extends StatelessWidget {
  const HodDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        AdminTaskCard(
          icon: Icons.article,
          title: 'Post General Notice',
          description: 'Publish a new notice for all users.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostNoticeScreen()),
          ),
        ),
        AdminTaskCard(
          icon: Icons.schedule,
          title: 'Upload Schedule',
          description: 'Upload the class schedule file for a semester.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadScheduleScreen(),
            ),
          ),
        ),
        AdminTaskCard(
          icon: Icons.school,
          title: 'Promote Batch',
          description: 'Move an entire batch to the next semester.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromoteBatchScreen()),
          ),
        ),
        AdminTaskCard(
          icon: Icons.event,
          title: 'Manage Events',
          description: 'Create and update college events.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageEventsScreen()),
          ),
        ),
        AdminTaskCard(
          icon: Icons.photo_album,
          title: 'Manage Gallery',
          description: 'Create albums and upload photos.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageGalleryScreen(),
            ),
          ),
        ),
        // 2. Add the final admin task card
        AdminTaskCard(
          icon: Icons.person_add_alt_1,
          title: 'Assign Subjects',
          description: 'Assign subjects to teachers.',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AssignSubjectsScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

// AdminTaskCard widget remains the same
class AdminTaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  const AdminTaskCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
