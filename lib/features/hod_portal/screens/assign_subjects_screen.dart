import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignSubjectsScreen extends StatefulWidget {
  const AssignSubjectsScreen({super.key});

  @override
  State<AssignSubjectsScreen> createState() => _AssignSubjectsScreenState();
}

class _AssignSubjectsScreenState extends State<AssignSubjectsScreen> {
  // We no longer need state variables for lists; StreamBuilder will manage them.

  Future<void> _assignTeacher(String subjectId, String teacherName) async {
    try {
      await FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .update({'teacherName': teacherName});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully assigned $teacherName.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign teacher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSubject(String subjectId, String subjectName) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete the subject "$subjectName"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('subjects')
            .doc(subjectId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$subjectName" deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete subject: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddSubjectDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    int? selectedSemester;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subject Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Subject Code'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<int>(
                  hint: const Text('Select Semester'),
                  items: List.generate(8, (i) => i + 1)
                      .map(
                        (sem) => DropdownMenuItem(
                          value: sem,
                          child: Text('Semester $sem'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => selectedSemester = val,
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await FirebaseFirestore.instance.collection('subjects').add({
                  'subjectName': nameController.text.trim(),
                  'subjectCode': codeController.text.trim(),
                  'semester': selectedSemester,
                  'teacherName': 'Unassigned',
                  'classType': 'Theory',
                  'assignedGroups': [],
                  'syllabus': {'chapters': [], 'references': []},
                });
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Subject',
            onPressed: _showAddSubjectDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('subjects')
            .orderBy('semester')
            .snapshots(),
        builder: (context, subjectSnapshot) {
          if (subjectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!subjectSnapshot.hasData || subjectSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No subjects found. Click "+" to add one.'),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'teacher')
                .snapshots(),
            builder: (context, teacherSnapshot) {
              if (teacherSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!teacherSnapshot.hasData) {
                return const Center(child: Text('Could not load teachers.'));
              }

              final subjects = subjectSnapshot.data!.docs;
              final teachers = teacherSnapshot.data!.docs;
              final teacherNames = teachers
                  .map((t) => t.get('name') as String)
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  final String currentTeacher =
                      subject.get('teacherName') ?? 'Unassigned';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.get('subjectName'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Semester: ${subject.get('semester')} | Code: ${subject.get('subjectCode')}',
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Delete Subject',
                                onPressed: () => _deleteSubject(
                                  subject.id,
                                  subject.get('subjectName'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                            ),
                            value: teacherNames.contains(currentTeacher)
                                ? currentTeacher
                                : null,
                            hint: const Text('Assign a Teacher'),
                            isExpanded: true,
                            items: teachers.map((teacherDoc) {
                              final teacherName =
                                  teacherDoc.get('name') as String;
                              return DropdownMenuItem<String>(
                                value: teacherName,
                                child: Text(teacherName),
                              );
                            }).toList(),
                            onChanged: (String? newTeacherName) {
                              if (newTeacherName != null &&
                                  newTeacherName != currentTeacher) {
                                _assignTeacher(subject.id, newTeacherName);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
