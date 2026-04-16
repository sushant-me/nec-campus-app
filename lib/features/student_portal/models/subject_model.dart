// lib/features/student_portal/models/subject_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final String code;
  final String teacherName;
  final int semester;
  final Syllabus syllabus;

  // --- NEW FIELDS ---
  final String classType;
  final List<String> assignedGroups;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.teacherName,
    required this.semester,
    required this.syllabus,
    required this.classType,
    required this.assignedGroups,
  });

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['subjectName'] ?? '',
      code: data['subjectCode'] ?? '',
      teacherName: data['teacherName'] ?? '',
      semester: data['semester'] ?? 0,
      syllabus: Syllabus.fromMap(data['syllabus'] ?? {}),

      // --- INITIALIZE NEW FIELDS ---
      classType: data['classType'] ?? 'Theory', // Default to 'Theory'
      // Convert the dynamic list from Firestore to a List<String>
      assignedGroups: List<String>.from(data['assignedGroups'] ?? []),
    );
  }
}

class Syllabus {
  final List<Chapter> chapters;
  final List<String> references;

  Syllabus({required this.chapters, required this.references});

  factory Syllabus.fromMap(Map<String, dynamic> map) {
    return Syllabus(
      chapters:
          (map['chapters'] as List<dynamic>?)
              ?.map((chapterMap) => Chapter.fromMap(chapterMap))
              .toList() ??
          [],
      references: List<String>.from(map['references'] ?? []),
    );
  }
}

class Chapter {
  final int chapterNo;
  final String chapterName;
  final String details;

  Chapter({
    required this.chapterNo,
    required this.chapterName,
    required this.details,
  });

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      chapterNo: map['chapter_no'] ?? 0,
      chapterName: map['chapter_name'] ?? '',
      details: map['details'] ?? '',
    );
  }
}
