/// Model representing a student's score/result in a specific course.
class CourseResult {
  final String id;
  final String studentId;
  final String courseId;
  final double score;

  CourseResult({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.score,
  });

  @override
  String toString() =>
      'CourseResult(id: $id, studentId: $studentId, courseId: $courseId, score: $score)';
}

/// Type aliases to support alternative naming conventions referenced in specifications.
typedef Result = CourseResult;
typedef Score = CourseResult;
