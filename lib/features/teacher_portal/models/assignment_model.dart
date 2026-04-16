// lib/features/teacher_portal/models/assignment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String title;
  final String description;
  final Timestamp dueDate;
  final String? fileUrl; // The file is optional

  Assignment({
    required this.title,
    required this.description,
    required this.dueDate,
    this.fileUrl,
  });

  // This factory constructor easily converts a document from Firestore
  // into an Assignment object.
  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Assignment(
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] ?? Timestamp.now(),
      fileUrl: data['fileUrl'], // This can be null
    );
  }
}
