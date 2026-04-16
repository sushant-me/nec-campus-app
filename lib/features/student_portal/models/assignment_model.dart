// lib/features/teacher_portal/models/assignment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String title;
  final String description;
  final Timestamp dueDate;
  final String? fileUrl;

  Assignment({
    required this.title,
    required this.description,
    required this.dueDate,
    this.fileUrl,
  });

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Assignment(
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] ?? Timestamp.now(),
      fileUrl: data['fileUrl'],
    );
  }
}
