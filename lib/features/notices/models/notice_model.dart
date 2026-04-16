// lib/features/notices/models/notice_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String title;
  final String? fileUrl;
  final String? content;
  final Timestamp timestamp;
  final String targetAudience; // This field is required

  Notice({
    required this.title,
    this.fileUrl,
    this.content,
    required this.timestamp,
    required this.targetAudience,
  });

  factory Notice.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Notice(
      title: data['title'] ?? 'No Title',
      fileUrl: data['fileUrl'],
      content: data['content'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      targetAudience: data['targetAudience'] ?? 'all',
    );
  }
}
