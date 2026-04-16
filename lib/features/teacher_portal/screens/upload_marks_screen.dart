import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nec_app/features/student_portal/models/subject_model.dart';

class UploadMarksScreen extends StatefulWidget {
  final Subject subject;
  const UploadMarksScreen({super.key, required this.subject});

  @override
  State<UploadMarksScreen> createState() => _UploadMarksScreenState();
}

class _UploadMarksScreenState extends State<UploadMarksScreen> {
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

  Future<void> _postMarks() async {
    if (_titleController.text.isEmpty ||
        _selectedBatch == null ||
        _linkController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }
    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('marks').add({
        'title': _titleController.text.trim(),
        'fileUrl': _linkController.text.trim(),
        'subjectId': widget.subject.id,
        'batch': _selectedBatch,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _linkController.clear();
      setState(() => _selectedBatch = null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post marks: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  // --- NEW: Function to delete a marks entry ---
  Future<void> _deleteMarks(String marksId) async {
    try {
      await FirebaseFirestore.instance
          .collection('marks')
          .doc(marksId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks entry deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Marks')),
      body: Column(
        children: [
          // --- Form for adding new marks ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Post New Marks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (e.g., Mid-Term Results)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Google Drive Link',
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
                  onPressed: _isPosting ? null : _postMarks,
                  child: _isPosting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Post Marks'),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),

          // --- List of previously posted marks ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('marks')
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
                      'No marks have been posted for this subject yet.',
                    ),
                  );
                }
                final marksList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: marksList.length,
                  itemBuilder: (context, index) {
                    final marks = marksList[index];
                    return ListTile(
                      leading: const Icon(Icons.school),
                      title: Text(marks['title']),
                      subtitle: Text('Batch: ${marks['batch']}'),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteMarks(marks.id),
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
