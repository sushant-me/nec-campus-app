import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/schedule_document_model.dart';

class ScheduleScreen extends StatefulWidget {
  final User user;
  const ScheduleScreen({super.key, required this.user});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Stream<QuerySnapshot>? _schedulesStream;

  @override
  void initState() {
    super.initState();
    _determineUserAndSetupStream(widget.user);
  }

  Future<void> _determineUserAndSetupStream(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final List<String> targets = ['all'];

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final role = userData['role'];

      if (role == 'student') {
        targets.add('students');
        final batch = userData['batch'];
        if (batch != null) targets.add('students_batch_$batch');
      } else if (role == 'teacher') {
        targets.add('teachers');
      } else if (role == 'hod') {
        targets.add('hods');
        targets.add('teachers');
      }
    }

    if (mounted) {
      setState(() {
        _schedulesStream = FirebaseFirestore.instance
            .collection('schedules')
            .where('targetAudience', whereIn: targets)
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    }
  }

  // Function to launch a URL in the browser
  Future<void> _launchURL(String urlString, BuildContext context) async {
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () => _determineUserAndSetupStream(widget.user),
        child: StreamBuilder<QuerySnapshot>(
          stream: _schedulesStream,
          builder: (context, snapshot) {
            if (_schedulesStream == null ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const _EmptySchedulesView();
            }

            final schedules = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = ScheduleDocument.fromFirestore(
                  schedules[index],
                );
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.green,
                      size: 32,
                    ),
                    title: Text(
                      schedule.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Published on: ${DateFormat.yMMMd().format(schedule.timestamp.toDate())}',
                    ),
                    trailing: const Icon(Icons.open_in_new, color: Colors.grey),
                    onTap: () => _launchURL(schedule.fileUrl, context),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// A reusable widget for the empty state
class _EmptySchedulesView extends StatelessWidget {
  const _EmptySchedulesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Schedules Found',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
