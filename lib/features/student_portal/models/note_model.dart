// lib/features/student_portal/models/note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String title;
  final String fileUrl;
  final Timestamp timestamp;

  Note({required this.title, required this.fileUrl, required this.timestamp});

  factory Note.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Note(
      title: data['title'] ?? 'Untitled',
      fileUrl: data['fileUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
