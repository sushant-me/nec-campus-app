import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nec_app/features/student_portal/models/subject_model.dart';
import 'package:nec_app/features/teacher_portal/screens/take_attendance_screen.dart';
import 'package:nec_app/features/teacher_portal/screens/upload_assignment_screen.dart';
import 'package:nec_app/features/teacher_portal/screens/upload_marks_screen.dart';
import 'package:nec_app/features/teacher_portal/screens/upload_note_screen.dart';

class ClassroomManagementScreen extends StatelessWidget {
  final Subject subject;
  const ClassroomManagementScreen({super.key, required this.subject});

  // This function shows a dialog for the teacher to select a batch
  void _showBatchSelectionDialog(BuildContext context) async {
    // Fetch available batches from Firestore
    final batchesSnapshot = await FirebaseFirestore.instance
        .collection('batches')
        .get();
    final availableBatches = batchesSnapshot.docs
        .map((doc) => int.parse(doc.id))
        .toList();
    int? selectedBatch;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Batch for Attendance'),
              content: DropdownButtonFormField<int>(
                hint: const Text('Choose a batch'),
                value: selectedBatch,
                isExpanded: true,
                items: availableBatches.map((int batch) {
                  return DropdownMenuItem<int>(
                    value: batch,
                    child: Text(batch.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setDialogState(() {
                    selectedBatch = newValue;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedBatch != null) {
                      Navigator.of(dialogContext).pop(); // Close the dialog
                      Navigator.push(
                        // Navigate to the attendance screen
                        context,
                        MaterialPageRoute(
                          builder: (context) => TakeAttendanceScreen(
                            subject: subject,
                            batch: selectedBatch!,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Proceed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2, // 2 cards per row
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _ManagementCard(
            title: 'Upload Notes',
            icon: Icons.note_add_outlined,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadNoteScreen(subject: subject),
              ),
            ),
          ),
          _ManagementCard(
            title: 'Assignments',
            icon: Icons.assignment_outlined,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadAssignmentScreen(subject: subject),
              ),
            ),
          ),
          _ManagementCard(
            title: 'Upload Marks',
            icon: Icons.grading_outlined,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadMarksScreen(subject: subject),
              ),
            ),
          ),
          _ManagementCard(
            title: 'Take Attendance',
            icon: Icons.co_present_outlined,
            color: Colors.green,
            onTap: () => _showBatchSelectionDialog(context),
          ),
        ],
      ),
    );
  }
}

// A reusable, styled card for the dashboard grid
class _ManagementCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
