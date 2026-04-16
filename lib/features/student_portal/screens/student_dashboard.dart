import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import 'subject_details_screen.dart';

class StudentDashboard extends StatefulWidget {
  final User user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // A single Future to get all necessary data at once
  late Future<Map<String, dynamic>> _studentDataFuture;

  @override
  void initState() {
    super.initState();
    _studentDataFuture = _fetchStudentData();
  }

  // This function fetches the user's name, batch, and current semester
  Future<Map<String, dynamic>> _fetchStudentData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    if (!userDoc.exists ||
        userDoc.data() == null ||
        userDoc.data()!['batch'] == null) {
      throw Exception(
        'Your user profile is missing required data. Please contact an admin.',
      );
    }
    final int batch = userDoc.data()!['batch'];
    final String name = userDoc.data()!['name'] ?? 'Student';

    final batchDoc = await FirebaseFirestore.instance
        .collection('batches')
        .doc(batch.toString())
        .get();
    if (!batchDoc.exists ||
        batchDoc.data() == null ||
        batchDoc.data()!['currentSemester'] == null) {
      throw Exception(
        'Could not determine the current semester for your batch.',
      );
    }
    final int currentSemester = batchDoc.data()!['currentSemester'];

    return {'name': name, 'batch': batch, 'currentSemester': currentSemester};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _studentDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Could not load student data.'));
        }

        final String name = snapshot.data!['name'];
        final int batch = snapshot.data!['batch'];
        final int currentSemester = snapshot.data!['currentSemester'];

        return RefreshIndicator(
          onRefresh: () {
            // Allow user to pull-to-refresh the data
            setState(() {
              _studentDataFuture = _fetchStudentData();
            });
            return _studentDataFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- NEW: Welcoming Header ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Batch $batch | Semester $currentSemester',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- Current Semester Section ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                  child: Text(
                    'Current Subjects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SubjectList(semester: currentSemester, batch: batch),

                // --- Past Semesters Section ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                  child: Text(
                    'Course Archive',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (int i = currentSemester - 1; i >= 1; i--)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ExpansionTile(
                      leading: const Icon(Icons.folder_copy_outlined),
                      title: Text('Semester $i Subjects'),
                      children: [_SubjectList(semester: i, batch: batch)],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- NEW: Enhanced Subject List Card ---
class _SubjectList extends StatelessWidget {
  final int semester;
  final int batch;
  const _SubjectList({required this.semester, required this.batch});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .where('semester', isEqualTo: semester)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey),
            title: Text('No subjects found for this semester.'),
          );
        }
        final subjectDocs = snapshot.data!.docs;
        return Column(
          children: subjectDocs.map((doc) {
            final subject = Subject.fromFirestore(doc);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.book_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(
                    subject.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Teacher: ${subject.teacherName}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubjectDetailsScreen(
                          subject: subject,
                          batch: batch,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
