import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notice_model.dart';

class NoticeBoardScreen extends StatefulWidget {
  final User user;
  const NoticeBoardScreen({super.key, required this.user});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  Stream<QuerySnapshot>? _noticesStream;

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
        // Note: The 'semester' field on the user doc is no longer used for dynamic semesters.
        // This logic is kept for flexibility if you ever need it again.
        final semester = userData['semester'];
        if (semester != null) targets.add('students_semester_$semester');

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
        _noticesStream = FirebaseFirestore.instance
            .collection('notices')
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
      backgroundColor: Colors.grey[100], // A light background color
      body: RefreshIndicator(
        onRefresh: () => _determineUserAndSetupStream(widget.user),
        child: StreamBuilder<QuerySnapshot>(
          stream: _noticesStream,
          builder: (context, snapshot) {
            if (_noticesStream == null ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const _EmptyNoticesView();
            }

            final notices = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = Notice.fromFirestore(notices[index]);
                return _NoticeCard(
                  notice: notice,
                  onTap: () {
                    final bool hasLink =
                        notice.fileUrl != null && notice.fileUrl!.isNotEmpty;
                    if (hasLink) {
                      _launchURL(notice.fileUrl!, context);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// A reusable, enhanced card widget for displaying a single notice
class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeCard({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isFileNotice =
        notice.fileUrl != null && notice.fileUrl!.isNotEmpty;
    final bool isTextNotice =
        notice.content != null && notice.content!.isNotEmpty;
    final date = notice.timestamp.toDate();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isFileNotice ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isFileNotice ? Icons.attachment : Icons.campaign_outlined,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isFileNotice)
                    const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                ],
              ),
              const Divider(height: 20),
              if (isTextNotice)
                Text(
                  notice.content!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                ),
              if (isTextNotice) const SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  DateFormat.yMMMd().format(date), // e.g., Oct 12, 2025
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A reusable widget for the empty state
class _EmptyNoticesView extends StatelessWidget {
  const _EmptyNoticesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Notices Found',
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
