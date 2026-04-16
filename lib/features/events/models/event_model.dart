// lib/features/events/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String title;
  final String description;
  final Timestamp eventDate;

  Event({
    required this.title,
    required this.description,
    required this.eventDate,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Event(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: data['eventDate'] ?? Timestamp.now(),
    );
  }
}
