import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Import all the necessary models
import 'package:nec_app/features/teacher_portal/models/assignment_model.dart';
import 'package:nec_app/features/teacher_portal/models/marks_model.dart';
import '../models/note_model.dart';
import '../models/subject_model.dart';

class SubjectDetailsScreen extends StatelessWidget {
  final Subject subject;
  final int batch;
  const SubjectDetailsScreen({
    super.key,
    required this.subject,
    required this.batch,
  });

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
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(subject.code), // Use subject code for a shorter title
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Colors.indigo.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'Syllabus'),
              Tab(icon: Icon(Icons.description), text: 'Notes'),
              Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
              Tab(icon: Icon(Icons.school), text: 'Marks'),
              Tab(icon: Icon(Icons.book), text: 'References'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- 1. Syllabus Tab ---
            _buildSyllabusTab(),

            // --- 2. Notes Tab ---
            _buildNotesTab(context),

            // --- 3. Assignments Tab ---
            _buildAssignmentsTab(context),

            // --- 4. Marks Tab ---
            _buildMarksTab(context),

            // --- 5. References Tab ---
            _buildReferencesTab(),
          ],
        ),
      ),
    );
  }

  // Helper method for Syllabus Tab
  Widget _buildSyllabusTab() {
    if (subject.syllabus.chapters.isEmpty) {
      return const _EmptyTab(
        message: 'Syllabus has not been uploaded for this subject.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: subject.syllabus.chapters.length,
      itemBuilder: (context, index) {
        final chapter = subject.syllabus.chapters[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColorLight,
              child: Text(chapter.chapterNo.toString()),
            ),
            title: Text(
              chapter.chapterName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(chapter.details, textAlign: TextAlign.justify),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method for Notes Tab
  Widget _buildNotesTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('subjectId', isEqualTo: subject.id)
          .where('batch', isEqualTo: batch)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const _EmptyTab(
            message: 'No notes have been posted for your batch.',
          );
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final note = Note.fromFirestore(snapshot.data!.docs[index]);
            final bool hasLink = note.fileUrl.isNotEmpty;
            return _buildInfoCard(
              context: context,
              title: note.title,
              icon: Icons.description,
              iconColor: Colors.blueAccent,
              hasLink: hasLink,
              onTap: hasLink ? () => _launchURL(note.fileUrl, context) : null,
            );
          },
        );
      },
    );
  }

  // Helper method for Assignments Tab
  Widget _buildAssignmentsTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('subjectId', isEqualTo: subject.id)
          .where('batch', isEqualTo: batch)
          .orderBy('dueDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const _EmptyTab(
            message: 'No assignments have been posted for your batch.',
          );
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final assignment = Assignment.fromFirestore(
              snapshot.data!.docs[index],
            );
            final bool hasLink =
                assignment.fileUrl != null && assignment.fileUrl!.isNotEmpty;
            return _buildInfoCard(
              context: context,
              title: assignment.title,
              subtitle: assignment.description,
              trailing: Text(
                'Due: ${DateFormat.yMd().format(assignment.dueDate.toDate())}',
              ),
              icon: Icons.assignment_turned_in,
              iconColor: Colors.orange,
              hasLink: hasLink,
              onTap: hasLink
                  ? () => _launchURL(assignment.fileUrl!, context)
                  : null,
            );
          },
        );
      },
    );
  }

  // Helper method for Marks Tab
  Widget _buildMarksTab(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('marks')
          .where('subjectId', isEqualTo: subject.id)
          .where('batch', isEqualTo: batch)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const _EmptyTab(
            message: 'No marks have been posted for your batch.',
          );
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final marksSheet = MarksSheet.fromFirestore(
              snapshot.data!.docs[index],
            );
            return _buildInfoCard(
              context: context,
              title: marksSheet.title,
              icon: Icons.school,
              iconColor: Colors.purple,
              hasLink: true,
              onTap: () => _launchURL(marksSheet.fileUrl, context),
            );
          },
        );
      },
    );
  }

  // Helper method for References Tab
  Widget _buildReferencesTab() {
    if (subject.syllabus.references.isEmpty) {
      return const _EmptyTab(message: 'No references listed for this subject.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: subject.syllabus.references.length,
      itemBuilder: (context, index) {
        final reference = subject.syllabus.references[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(reference),
          ),
        );
      },
    );
  }
}

// A reusable widget for displaying items in Notes, Assignments, Marks
Widget _buildInfoCard({
  required BuildContext context,
  required String title,
  String? subtitle,
  Widget? trailing,
  required IconData icon,
  required Color iconColor,
  required bool hasLink,
  VoidCallback? onTap,
}) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      leading: Icon(icon, color: hasLink ? iconColor : Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: hasLink
          ? (trailing ?? const Icon(Icons.open_in_new))
          : trailing,
      onTap: onTap,
    ),
  );
}

// A reusable widget for empty tabs
class _EmptyTab extends StatelessWidget {
  final String message;
  const _EmptyTab({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
