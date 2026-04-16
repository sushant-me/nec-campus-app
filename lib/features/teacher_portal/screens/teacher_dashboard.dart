// lib/features/teacher_portal/screens/teacher_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// 1. Import the new screen and the subject model
import 'package:nec_app/features/student_portal/models/subject_model.dart';
import 'classroom_management_screen.dart';

class TeacherDashboard extends StatelessWidget {
  final String teacherName;
  const TeacherDashboard({super.key, required this.teacherName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .where('teacherName', isEqualTo: teacherName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('You have not been assigned any subjects.'),
          );
        }

        final subjectDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: subjectDocs.length,
          itemBuilder: (context, index) {
            // 2. Convert the Firestore document into a Subject object
            final subject = Subject.fromFirestore(subjectDocs[index]);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(subject.name),
                subtitle: Text('Semester: ${subject.semester}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                // 3. Add the navigation logic
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClassroomManagementScreen(subject: subject),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
