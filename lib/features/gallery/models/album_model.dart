// lib/features/gallery/models/album_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Album {
  final String id;
  final String title;
  final String coverImageUrl;

  Album({required this.id, required this.title, required this.coverImageUrl});

  factory Album.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Use the first image in the list as the cover, or a placeholder
    final images = data['imageUrls'] as List<dynamic>? ?? [];
    return Album(
      id: doc.id,
      title: data['title'] ?? 'Untitled Album',
      coverImageUrl: images.isNotEmpty
          ? images.first
          : 'https://via.placeholder.com/150',
    );
  }
}
