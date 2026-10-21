class Course {
  final String id;
  final String name;
  final List<String> studentIds = [];

  Course({required this.id, required this.name});

  /// Checks if a student is enrolled in this course.
  bool isEnrolled(String studentId) {
    return studentIds.contains(studentId);
  }

  /// Adds a student ID to the course enrollment list.
  void enroll(String studentId) {
    if (!studentIds.contains(studentId)) {
      studentIds.add(studentId);
    }
  }

  /// Removes a student ID from the course enrollment list.
  void unenroll(String studentId) {
    studentIds.remove(studentId);
  }

  @override
  String toString() => 'Course(id: $id, name: $name, students: $studentIds)';
}
