import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nec_app/features/student_portal/models/subject_model.dart';

class UploadNoteScreen extends StatefulWidget {
  final Subject subject;
  const UploadNoteScreen({super.key, required this.subject});

  @override
  State<UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<UploadNoteScreen> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isPosting = false;
  List<int> _availableBatches = [];
  int? _selectedBatch;

  @override
  void initState() {
    super.initState();
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    final batchesSnapshot = await FirebaseFirestore.instance
        .collection('batches')
        .get();
    if (mounted) {
      setState(() {
        _availableBatches = batchesSnapshot.docs
            .map((doc) => int.parse(doc.id))
            .toList();
      });
    }
  }

  Future<void> _postNote() async {
    if (_titleController.text.isEmpty || _selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a title and select a batch.'),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('notes').add({
        'title': _titleController.text.trim(),
        'fileUrl': _linkController.text.trim(),
        'subjectId': widget.subject.id,
        'batch': _selectedBatch,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the form after successful post
      _titleController.clear();
      _linkController.clear();
      setState(() => _selectedBatch = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post note: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  // --- NEW: Function to delete a note ---
  Future<void> _deleteNote(String noteId) async {
    try {
      await FirebaseFirestore.instance.collection('notes').doc(noteId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Notes')),
      body: Column(
        children: [
          // --- Form for adding new notes ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add a New Note',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Note Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Google Drive Link (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedBatch,
                  hint: const Text('Select Batch'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _availableBatches.map((int batch) {
                    return DropdownMenuItem<int>(
                      value: batch,
                      child: Text(batch.toString()),
                    );
                  }).toList(),
                  onChanged: (int? newValue) =>
                      setState(() => _selectedBatch = newValue),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isPosting ? null : _postNote,
                  child: _isPosting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Post Note'),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),

          // --- List of previously posted notes ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notes')
                  .where('subjectId', isEqualTo: widget.subject.id)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No notes have been posted for this subject yet.',
                    ),
                  );
                }
                final notes = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(note['title']),
                      subtitle: Text('Batch: ${note['batch']}'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteNote(note.id),
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
