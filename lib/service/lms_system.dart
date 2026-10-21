import '../model/course.dart';
import '../model/course_result.dart';
import '../model/student.dart';

/// LmsSystem provides the service layer managing students, courses, and course results.
/// It encapsulates the LMS business logic and enforces data consistency rules.
class LmsSystem {
  final List<Student> students = [];
  final List<Course> courses = [];
  final List<CourseResult> results = [];

  // ==========================================
  // STUDENT OPERATIONS
  // ==========================================

  /// Adds a new student to the LMS.
  /// Precondition: Student ID must not already exist.
  /// Postcondition: Student is added to [students].
  void addStudent({required String studentId, required String studentName}) {
    Student? student = _findStudentOrNull(studentId);
    if (student != null) {
      throw Exception('Student $studentId already exists');
    }

    students.add(Student(id: studentId, name: studentName));
  }

  /// Removes a student from the LMS.
  /// Precondition: Student with [studentId] must exist.
  /// Postconditions:
  /// 1. Student is removed from the global [students] list.
  /// 2. Student is removed from every course in [courses] they are enrolled in.
  /// 3. All results belonging to this student are removed from [results].
  /// After this operation, there is no reference to [studentId] in the LMS.
  void removeStudent({required String studentId}) {
    Student? student = _findStudentOrNull(studentId);
    if (student == null) {
      throw Exception('Student $studentId not found');
    }

    // 1- Remove student from the global students list
    students.removeWhere((s) => s.id == studentId);

    // 2- Remove student from every course in which they are enrolled
    for (Course course in courses) {
      course.unenroll(studentId);
    }

    // 3- Remove all results belonging to this student
    results.removeWhere((result) => result.studentId == studentId);
  }

  // ==========================================
  // TASK 1: COURSE OPERATIONS
  // ==========================================

  /// Adds a new course to the LMS.
  /// Precondition: Course ID must not already exist.
  /// Postcondition: Course is added to [courses].
  void addCourse({required String courseId, required String courseName}) {
    Course? course = _findCourseOrNull(courseId);
    if (course != null) {
      throw Exception('Course with ID $courseId already exists');
    }

    courses.add(Course(id: courseId, name: courseName));
  }

  /// Removes a course from the LMS.
  /// Precondition: Course with [courseId] must exist.
  /// Postcondition:
  /// 1. Course is removed from [courses].
  /// 2. All associated results for this course are removed from [results]
  ///    to preserve data consistency (no dangling results for nonexistent courses).
  void removeCourse({required String courseId}) {
    Course? course = _findCourseOrNull(courseId);
    if (course == null) {
      throw Exception('Course with ID $courseId not found');
    }

    // Remove the course
    courses.removeWhere((c) => c.id == courseId);

    // Remove associated results for this course to preserve system consistency
    results.removeWhere((r) => r.courseId == courseId);
  }

  // ==========================================
  // TASK 2: ENROLL STUDENT IN COURSE
  // ==========================================

  /// Enrolls an existing student in an existing course.
  /// Preconditions:
  /// 1. Student with [studentId] must exist.
  /// 2. Course with [courseId] must exist.
  /// 3. Student must not already be enrolled in the course.
  /// Postcondition: [studentId] is added to [course.studentIds].
  void enrollStudent({required String studentId, required String courseId}) {
    Student? student = _findStudentOrNull(studentId);
    if (student == null) {
      throw Exception('Student with ID $studentId does not exist');
    }

    Course? course = _findCourseOrNull(courseId);
    if (course == null) {
      throw Exception('Course with ID $courseId does not exist');
    }

    if (course.isEnrolled(studentId)) {
      throw Exception('Student $studentId is already enrolled in course $courseId');
    }

    course.enroll(studentId);
  }

  // ==========================================
  // TASK 3: REMOVE STUDENT FROM COURSE
  // ==========================================

  /// Removes a student from a course.
  /// Preconditions:
  /// 1. Student with [studentId] must exist.
  /// 2. Course with [courseId] must exist.
  /// 3. Student must currently be enrolled in the course.
  /// Postconditions:
  /// 1. [studentId] is removed from [course.studentIds].
  /// 2. Policy for associated results: any results for this student in this course
  ///    are removed to prevent inconsistent state (student cannot have a score in
  ///    a course they are not enrolled in).
  /// 3. The student and course objects themselves remain in the LMS.
  void discardStudentFromCourse({required String studentId, required String courseId}) {
    Student? student = _findStudentOrNull(studentId);
    if (student == null) {
      throw Exception('Student with ID $studentId does not exist');
    }

    Course? course = _findCourseOrNull(courseId);
    if (course == null) {
      throw Exception('Course with ID $courseId does not exist');
    }

    if (!course.isEnrolled(studentId)) {
      throw Exception('Student $studentId is not enrolled in course $courseId');
    }

    course.unenroll(studentId);

    // Associated results cleanup policy:
    // A student who is no longer enrolled should not maintain course results.
    results.removeWhere(
      (r) => r.studentId == studentId && r.courseId == courseId,
    );
  }

  // ==========================================
  // TASK 4: ADD RESULT TO A COURSE
  // ==========================================

  /// Adds a score/result for a student in a course.
  /// Preconditions:
  /// 1. Student with [studentId] must exist.
  /// 2. Course with [courseId] must exist.
  /// 3. Student must be currently enrolled in the course.
  /// 4. Valid score range: 0.0 <= [score] <= 100.0.
  /// 5. Duplicate policy: A student can only have ONE result per course.
  ///    Attempting to add a duplicate result will throw an Exception.
  /// 6. Result ID: Unique identifier for the result. If not provided,
  ///    an ID is auto-generated as 'RES_${studentId}_${courseId}'.
  /// Postcondition: [CourseResult] is recorded in [results].
  CourseResult addResult({
    required String studentId,
    required String courseId,
    required double score,
    String? resultId,
  }) {
    Student? student = _findStudentOrNull(studentId);
    if (student == null) {
      throw Exception('Student with ID $studentId does not exist');
    }

    Course? course = _findCourseOrNull(courseId);
    if (course == null) {
      throw Exception('Course with ID $courseId does not exist');
    }

    if (!course.isEnrolled(studentId)) {
      throw Exception('Student $studentId is not enrolled in course $courseId');
    }

    if (score < 0 || score > 100) {
      throw Exception('Invalid score $score. Score must be between 0 and 100');
    }

    // Duplicate policy check: student can only have one result per course
    bool alreadyHasResult = results.any(
      (r) => r.studentId == studentId && r.courseId == courseId,
    );
    if (alreadyHasResult) {
      throw Exception(
        'Duplicate result rejected: student $studentId already has a result in course $courseId',
      );
    }

    final id = resultId ?? 'RES_${studentId}_${courseId}';
    // Ensure resultId uniqueness
    if (_findResultOrNull(id) != null) {
      throw Exception('Result with ID $id already exists');
    }

    final result = CourseResult(
      id: id,
      studentId: studentId,
      courseId: courseId,
      score: score,
    );
    results.add(result);
    return result;
  }

  // ==========================================
  // TASK 5: REMOVE A STUDENT RESULT
  // ==========================================

  /// Removes a student result by its unique result ID.
  /// Precondition: Result with [resultId] must exist.
  /// Postcondition:
  /// 1. Result is removed from [results].
  /// 2. The student, course, and other unrelated results remain unchanged.
  void removeResult({required String resultId}) {
    CourseResult? result = _findResultOrNull(resultId);
    if (result == null) {
      throw Exception('Result with ID $resultId not found');
    }

    results.removeWhere((r) => r.id == resultId);
  }

  // ==========================================
  // HELPER / LOOKUP METHODS
  // ==========================================

  Student? _findStudentOrNull(String studentId) {
    for (Student s in students) {
      if (s.id == studentId) {
        return s;
      }
    }
    return null;
  }

  Course? _findCourseOrNull(String courseId) {
    for (Course c in courses) {
      if (c.id == courseId) {
        return c;
      }
    }
    return null;
  }

  CourseResult? _findResultOrNull(String resultId) {
    for (CourseResult r in results) {
      if (r.id == resultId) {
        return r;
      }
    }
    return null;
  }

  /// Finds a student by ID, or throws an exception if not found.
  Student findStudent(String studentId) {
    final student = _findStudentOrNull(studentId);
    if (student == null) {
      throw Exception('Student with ID $studentId not found');
    }
    return student;
  }

  /// Finds a course by ID, or throws an exception if not found.
  Course findCourse(String courseId) {
    final course = _findCourseOrNull(courseId);
    if (course == null) {
      throw Exception('Course with ID $courseId not found');
    }
    return course;
  }

  /// Finds a result by ID, or throws an exception if not found.
  CourseResult findResult(String resultId) {
    final result = _findResultOrNull(resultId);
    if (result == null) {
      throw Exception('Result with ID $resultId not found');
    }
    return result;
  }

  /// Returns all results belonging to a specific student.
  List<CourseResult> getResultsForStudent(String studentId) {
    return results.where((r) => r.studentId == studentId).toList();
  }

  /// Returns all results for a specific course.
  List<CourseResult> getResultsForCourse(String courseId) {
    return results.where((r) => r.courseId == courseId).toList();
  }

  /// Returns all courses in which a student is enrolled.
  List<Course> getCoursesForStudent(String studentId) {
    return courses.where((c) => c.isEnrolled(studentId)).toList();
  }
}
