// lib/features/schedule/models/schedule_document_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleDocument {
  final String title;
  final String fileUrl;
  final String targetAudience;
  final Timestamp timestamp;

  ScheduleDocument({
    required this.title,
    required this.fileUrl,
    required this.targetAudience,
    required this.timestamp,
  });

  factory ScheduleDocument.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ScheduleDocument(
      title: data['title'] ?? 'No Title',
      fileUrl: data['fileUrl'] ?? '',
      targetAudience: data['targetAudience'] ?? 'all',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
