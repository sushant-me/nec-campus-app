import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:intl/intl.dart';

class ManageGalleryScreen extends StatefulWidget {
  const ManageGalleryScreen({super.key});

  @override
  State<ManageGalleryScreen> createState() => _ManageGalleryScreenState();
}

class _ManageGalleryScreenState extends State<ManageGalleryScreen> {
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final List<String> _imageUrls = [];
  bool _isPosting = false;

  void _addImageUrl() {
    if (_imageUrlController.text.isNotEmpty) {
      setState(() {
        _imageUrls.add(_imageUrlController.text.trim());
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _createAlbum() async {
    if (_titleController.text.isEmpty || _imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a title and at least one image URL.'),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('gallery').add({
        'title': _titleController.text.trim(),
        'imageUrls': _imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      setState(() {
        _imageUrls.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Album created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create album: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _deleteAlbum(String albumId) async {
    try {
      await FirebaseFirestore.instance
          .collection('gallery')
          .doc(albumId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Album deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete album: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Gallery')),
      body: Column(
        children: [
          // Form is now inside an ExpansionTile for a cleaner look
          ExpansionTile(
            title: const Text(
              'Create a New Album',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.add_photo_alternate_outlined),
            initiallyExpanded: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Album Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL (e.g., from Google Photos)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addImageUrl,
                          tooltip: 'Add Image URL',
                        ),
                      ),
                      onSubmitted: (_) => _addImageUrl(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _imageUrls
                          .map(
                            (url) => Chip(
                              avatar: const Icon(
                                Icons.image_outlined,
                                size: 18,
                              ),
                              label: Text(
                                'Image ${_imageUrls.indexOf(url) + 1}',
                              ),
                              onDeleted: () =>
                                  setState(() => _imageUrls.remove(url)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isPosting ? null : _createAlbum,
                      icon: _isPosting
                          ? Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isPosting ? 'Creating...' : 'Create Album'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(
            thickness: 4,
            color: Color.fromARGB(255, 240, 240, 240),
          ),

          // List of previously created albums
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Existing Albums",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gallery')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No albums have been created yet.'),
                  );
                }
                final albums = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final data = album.data() as Map<String, dynamic>;
                    final imageCount =
                        (data['imageUrls'] as List?)?.length ?? 0;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.photo_album_outlined),
                        title: Text(data['title']),
                        subtitle: Text('$imageCount photos'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteAlbum(album.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
