import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nec_app/features/student_portal/models/subject_model.dart';

class UploadAssignmentScreen extends StatefulWidget {
  final Subject subject;
  const UploadAssignmentScreen({super.key, required this.subject});

  @override
  State<UploadAssignmentScreen> createState() => _UploadAssignmentScreenState();
}

class _UploadAssignmentScreenState extends State<UploadAssignmentScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  DateTime? _dueDate;
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

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) setState(() => _dueDate = pickedDate);
  }

  Future<void> _postAssignment() async {
    if (_titleController.text.isEmpty ||
        _selectedBatch == null ||
        _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }
    setState(() => _isPosting = true);

    try {
      await FirebaseFirestore.instance.collection('assignments').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'dueDate': Timestamp.fromDate(_dueDate!),
        'fileUrl': _linkController.text.trim(),
        'subjectId': widget.subject.id,
        'batch': _selectedBatch,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _descController.clear();
      _linkController.clear();
      setState(() {
        _selectedBatch = null;
        _dueDate = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to post assignment: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // --- NEW: Function to delete an assignment ---
  Future<void> _deleteAssignment(String assignmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(assignmentId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete assignment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Assignments')),
      body: Column(
        children: [
          // --- Form for adding new assignments ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Post New Assignment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedBatch,
                        hint: const Text('Select Batch'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _availableBatches
                            .map(
                              (b) => DropdownMenuItem<int>(
                                value: b,
                                child: Text(b.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBatch = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _dueDate == null
                              ? 'Due Date'
                              : DateFormat.yMd().format(_dueDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isPosting ? null : _postAssignment,
                  child: _isPosting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Post Assignment'),
                ),
              ],
            ),
          ),
          const Divider(thickness: 2),

          // --- List of previously posted assignments ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
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
                      'No assignments have been posted for this subject yet.',
                    ),
                  );
                }
                final assignments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return ListTile(
                      leading: const Icon(Icons.assignment),
                      title: Text(assignment['title']),
                      subtitle: Text(
                        'Batch: ${assignment['batch']} | Due: ${DateFormat.yMd().format((assignment['dueDate'] as Timestamp).toDate())}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteAssignment(assignment.id),
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
