import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PromoteBatchScreen extends StatefulWidget {
  const PromoteBatchScreen({super.key});

  @override
  State<PromoteBatchScreen> createState() => _PromoteBatchScreenState();
}

class _PromoteBatchScreenState extends State<PromoteBatchScreen> {
  Future<void> _promoteBatch(String batchId, int currentSemester) async {
    if (currentSemester >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This batch has already graduated.')),
      );
      return;
    }

    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Promote Batch $batchId?'),
            content: Text(
              'Are you sure you want to promote this batch from Semester $currentSemester to Semester ${currentSemester + 1}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Promote'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('batches')
            .doc(batchId)
            .update({'currentSemester': currentSemester + 1});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch $batchId promoted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to promote batch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- 1. ADD THIS FUNCTION TO SHOW THE DIALOG ---
  void _showAddBatchDialog() {
    final TextEditingController batchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Batch'),
          content: TextField(
            controller: batchController,
            decoration: const InputDecoration(
              labelText: 'Batch Year (e.g., 2025)',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String batchId = batchController.text.trim();
                if (batchId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('batches')
                      .doc(batchId)
                      .set({'currentSemester': 1});
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promote a Batch')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('batches')
            .orderBy(FieldPath.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No batches found. Click "+" to add one.'),
            );
          }

          final batches = snapshot.data!.docs;

          return ListView.builder(
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              final batchId = batch.id;
              final currentSemester = batch['currentSemester'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    'Batch: $batchId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Current Semester: $currentSemester'),
                  trailing: ElevatedButton(
                    onPressed: () => _promoteBatch(batchId, currentSemester),
                    child: const Text('Promote'),
                  ),
                ),
              );
            },
          );
        },
      ),
      // --- 2. ADD THE FLOATING ACTION BUTTON HERE ---
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBatchDialog,
        tooltip: 'Add New Batch',
        child: const Icon(Icons.add),
      ),
    );
  }
}
