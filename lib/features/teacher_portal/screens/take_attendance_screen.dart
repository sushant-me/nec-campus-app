// lib/features/teacher_portal/screens/take_attendance_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nec_app/features/student_portal/models/subject_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AttendanceStatus { present, absent }

class TakeAttendanceScreen extends StatefulWidget {
  final Subject subject;
  final int batch;
  const TakeAttendanceScreen({
    super.key,
    required this.subject,
    required this.batch,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, AttendanceStatus> _attendanceMap = {};
  DateTime _selectedDate = DateTime.now();
  bool _isOffline = false;

  // A key for the ScaffoldMessenger to avoid BuildContext issues
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndFetch();
  }

  Future<void> _checkConnectivityAndFetch() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _isOffline = true;
      });
      _loadStudentsFromCache();
    } else {
      setState(() {
        _isOffline = false;
      });
      _fetchStudentsFromFirestore();
    }
  }

  Future<void> _fetchStudentsFromFirestore() async {
    setState(() => _isLoading = true);
    final studentSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('batch', isEqualTo: widget.batch)
        .where('group', whereIn: widget.subject.assignedGroups)
        .orderBy('rollNumber')
        .get();

    final studentsData = studentSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cached_students_${widget.subject.id}_${widget.batch}',
      jsonEncode(studentsData),
    );

    _initializeAttendance(studentsData);
    setState(() => _isLoading = false);
  }

  Future<void> _loadStudentsFromCache() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(
      'cached_students_${widget.subject.id}_${widget.batch}',
    );

    if (cachedData != null) {
      final studentsData = List<Map<String, dynamic>>.from(
        jsonDecode(cachedData),
      );
      _initializeAttendance(studentsData);
    }
    setState(() => _isLoading = false);
  }

  void _initializeAttendance(List<Map<String, dynamic>> studentsData) {
    // FIX: Ensure the student ID is always treated as a String
    final initialMap = {
      for (var student in studentsData)
        student['id'].toString(): AttendanceStatus.present,
    };
    setState(() {
      _students = studentsData;
      _attendanceMap = initialMap;
    });
  }

  Future<void> _submitAttendance() async {
    setState(() => _isSubmitting = true);
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final statusToStringMap = _attendanceMap.map(
      (key, value) => MapEntry(key, value.name),
    );

    if (_isOffline) {
      final prefs = await SharedPreferences.getInstance();
      final record = {
        'date': dateString,
        'subjectId': widget.subject.id,
        'batch': widget.batch,
        'teacherId': FirebaseAuth.instance.currentUser?.uid,
        'statuses': statusToStringMap,
      };
      await prefs.setString('unsynced_attendance', jsonEncode(record));
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Offline! Attendance saved locally. Sync when online.'),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      try {
        await FirebaseFirestore.instance.collection('attendance_records').add({
          'date': Timestamp.fromDate(_selectedDate),
          'subjectId': widget.subject.id,
          'batch': widget.batch,
          'teacherId': FirebaseAuth.instance.currentUser?.uid,
          'statuses': statusToStringMap,
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Attendance submitted successfully!')),
        );
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _generateAndShareReport() async {
    List<List<dynamic>> rows = [];
    rows.add(['Roll Number', 'Name', 'Status']);
    for (var student in _students) {
      rows.add([
        student['rollNumber'],
        student['name'],
        _attendanceMap[student['id'].toString()]?.name ??
            'N/A', // FIX: Use toString()
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/attendance_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(path)],
      text:
          'Attendance for ${widget.subject.name} on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
    );
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Use a MaterialApp to provide a ScaffoldMessenger
      home: Scaffold(
        key: _scaffoldMessengerKey,
        appBar: AppBar(
          title: Text('Attendance: ${widget.subject.name}'),
          leading: IconButton(
            // Add a back button
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Download Report',
              onPressed: _students.isEmpty ? null : _generateAndShareReport,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _isOffline
                        ? 'No students cached. Please connect to the internet first to load the student list.'
                        : 'No students found for this class and batch.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, index) {
                  final student = _students[index];
                  final studentId = student['id']
                      .toString(); // FIX: Use toString()

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(student['name']),
                      subtitle: Text('Roll: ${student['rollNumber']}'),
                      trailing: DropdownButton<AttendanceStatus>(
                        value: _attendanceMap[studentId],
                        items: const [
                          DropdownMenuItem(
                            value: AttendanceStatus.present,
                            child: Text(
                              'Present',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                          DropdownMenuItem(
                            value: AttendanceStatus.absent,
                            child: Text(
                              'Absent',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        onChanged: (AttendanceStatus? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _attendanceMap[studentId] = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isSubmitting ? null : _submitAttendance,
          label: Text(_isOffline ? 'Save Offline' : 'Submit Attendance'),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(_isOffline ? Icons.save : Icons.check),
        ),
      ),
    );
  }
}
