// lib/features/teacher_portal/models/marks_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MarksSheet {
  final String title;
  final String fileUrl;
  final Timestamp timestamp;

  MarksSheet({
    required this.title,
    required this.fileUrl,
    required this.timestamp,
  });

  factory MarksSheet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MarksSheet(
      title: data['title'] ?? 'Untitled',
      fileUrl: data['fileUrl'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
