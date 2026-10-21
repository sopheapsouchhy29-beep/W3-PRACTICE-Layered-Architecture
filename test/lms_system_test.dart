import 'package:test/test.dart';
import 'package:lms_layered_architecture_example/service/lms_system.dart';

void main() {
  late LmsSystem lms;

  setUp(() {
    lms = LmsSystem();
  });

  // ==========================================
  // BASELINE: STUDENT MANAGEMENT
  // ==========================================
  group('Student Management', () {
    test('creates and removes a student', () {
      lms.addStudent(studentId: 'S1', studentName: 'ronan');
      expect(lms.students.first.name, 'ronan');

      lms.removeStudent(studentId: 'S1');
      expect(lms.students.isEmpty, isTrue);
    });

    test('rejects adding duplicate student ID', () {
      lms.addStudent(studentId: 'S1', studentName: 'ronan');
      expect(
        () => lms.addStudent(studentId: 'S1', studentName: 'another ronan'),
        throwsException,
      );
    });

    test('rejects removing nonexistent student', () {
      expect(
        () => lms.removeStudent(studentId: 'NON_EXISTENT'),
        throwsException,
      );
    });
  });

  // ==========================================
  // TASK 1: ADD AND REMOVE COURSES
  // ==========================================
  group('Task 1: Course Management', () {
    test('adds and removes a course successfully', () {
      lms.addCourse(courseId: 'C101', courseName: 'Mobile Development');
      expect(lms.courses.length, 1);
      expect(lms.courses.first.id, 'C101');
      expect(lms.courses.first.name, 'Mobile Development');

      lms.removeCourse(courseId: 'C101');
      expect(lms.courses.isEmpty, isTrue);
    });

    test('rejects a duplicate course ID', () {
      lms.addCourse(courseId: 'C101', courseName: 'Mobile Development');
      expect(
        () => lms.addCourse(courseId: 'C101', courseName: 'Web Development'),
        throwsException,
      );
    });

    test('rejects removal of a nonexistent course', () {
      expect(
        () => lms.removeCourse(courseId: 'C999'),
        throwsException,
      );
    });

    test('removing a course cleans up any associated results', () {
      lms.addStudent(studentId: 'S1', studentName: 'Alice');
      lms.addCourse(courseId: 'C101', courseName: 'Mobile Development');
      lms.enrollStudent(studentId: 'S1', courseId: 'C101');
      lms.addResult(studentId: 'S1', courseId: 'C101', score: 88.0);

      expect(lms.results.length, 1);

      lms.removeCourse(courseId: 'C101');
      expect(lms.courses.isEmpty, isTrue);
      // Data consistency rule: results for removed course must also be removed
      expect(lms.results.isEmpty, isTrue);
    });
  });

  // ==========================================
  // TASK 2: ENROLL A STUDENT IN A COURSE
  // ==========================================
  group('Task 2: Student Enrollment', () {
    setUp(() {
      lms.addStudent(studentId: 'S01', studentName: 'Alice');
      lms.addCourse(courseId: 'C01', courseName: 'Mobile Development');
    });

    test('enrolls an existing student in an existing course', () {
      lms.enrollStudent(studentId: 'S01', courseId: 'C01');

      final course = lms.findCourse('C01');
      expect(course.isEnrolled('S01'), isTrue);
      expect(course.studentIds, contains('S01'));
    });

    test('rejects enrollment if the student does not exist', () {
      expect(
        () => lms.enrollStudent(studentId: 'UNKNOWN_STUDENT', courseId: 'C01'),
        throwsException,
      );
    });

    test('rejects enrollment if the course does not exist', () {
      expect(
        () => lms.enrollStudent(studentId: 'S01', courseId: 'UNKNOWN_COURSE'),
        throwsException,
      );
    });

    test('rejects duplicate enrollment', () {
      lms.enrollStudent(studentId: 'S01', courseId: 'C01');
      expect(
        () => lms.enrollStudent(studentId: 'S01', courseId: 'C01'),
        throwsException,
      );
    });

    test('supports enrolling one student in multiple courses', () {
      lms.addCourse(courseId: 'C02', courseName: 'Cloud Computing');
      lms.enrollStudent(studentId: 'S01', courseId: 'C01');
      lms.enrollStudent(studentId: 'S01', courseId: 'C02');

      final enrolledCourses = lms.getCoursesForStudent('S01');
      expect(enrolledCourses.length, 2);
    });
  });

  // ==========================================
  // TASK 3: REMOVE A STUDENT FROM A COURSE
  // ==========================================
  group('Task 3: Discard Student from Course & Revisit Student Removal', () {
    setUp(() {
      lms.addStudent(studentId: 'S01', studentName: 'Alice');
      lms.addCourse(courseId: 'C01', courseName: 'Mobile Development');
      lms.enrollStudent(studentId: 'S01', courseId: 'C01');
    });

    test('removes an existing enrollment', () {
      lms.discardStudentFromCourse(studentId: 'S01', courseId: 'C01');
      final course = lms.findCourse('C01');
      expect(course.isEnrolled('S01'), isFalse);
    });

    test('rejects removal of a nonexistent enrollment', () {
      lms.addStudent(studentId: 'S02', studentName: 'Bob');
      expect(
        () => lms.discardStudentFromCourse(studentId: 'S02', courseId: 'C01'),
        throwsException,
      );
    });

    test('verifies student and course still exist after enrollment is removed', () {
      lms.discardStudentFromCourse(studentId: 'S01', courseId: 'C01');

      expect(lms.students.any((s) => s.id == 'S01'), isTrue);
      expect(lms.courses.any((c) => c.id == 'C01'), isTrue);
    });

    test('verifies chosen policy for associated results when discarding enrollment', () {
      lms.addResult(studentId: 'S01', courseId: 'C01', score: 90.0);
      expect(lms.results.length, 1);

      // Discarding student from course removes their result in that course
      lms.discardStudentFromCourse(studentId: 'S01', courseId: 'C01');
      expect(lms.results.where((r) => r.courseId == 'C01').isEmpty, isTrue);
    });

    test('removes a student who has enrollments in multiple courses', () {
      lms.addCourse(courseId: 'C02', courseName: 'Cloud Computing');
      lms.enrollStudent(studentId: 'S01', courseId: 'C02');
      lms.addResult(studentId: 'S01', courseId: 'C01', score: 85.0);
      lms.addResult(studentId: 'S01', courseId: 'C02', score: 92.0);

      // Revisit removeStudent: must remove student from LMS, all courses, and all results
      lms.removeStudent(studentId: 'S01');

      // 1. Student removed from global students list
      expect(lms.students.any((s) => s.id == 'S01'), isFalse);

      // 2. Student removed from all enrolled courses
      final c1 = lms.findCourse('C01');
      final c2 = lms.findCourse('C02');
      expect(c1.isEnrolled('S01'), isFalse);
      expect(c2.isEnrolled('S01'), isFalse);

      // 3. All results belonging to this student are removed
      expect(lms.getResultsForStudent('S01').isEmpty, isTrue);
    });
  });

  // ==========================================
  // TASK 4: ADD A RESULT TO A COURSE
  // ==========================================
  group('Task 4: Add Result to Course', () {
    setUp(() {
      lms.addStudent(studentId: 'S01', studentName: 'Alice');
      lms.addCourse(courseId: 'C01', courseName: 'Mobile Development');
      lms.enrollStudent(studentId: 'S01', courseId: 'C01');
    });

    test('adds a valid result', () {
      final result = lms.addResult(
        studentId: 'S01',
        courseId: 'C01',
        score: 85.0,
      );

      expect(result.studentId, 'S01');
      expect(result.courseId, 'C01');
      expect(result.score, 85.0);
      expect(lms.results.length, 1);
    });

    test('rejects a result for a nonexistent student or course', () {
      expect(
        () => lms.addResult(
          studentId: 'UNKNOWN',
          courseId: 'C01',
          score: 80.0,
        ),
        throwsException,
      );

      expect(
        () => lms.addResult(
          studentId: 'S01',
          courseId: 'UNKNOWN',
          score: 80.0,
        ),
        throwsException,
      );
    });

    test('rejects a result for a student who is not enrolled', () {
      lms.addStudent(studentId: 'S02', studentName: 'Bob');
      expect(
        () => lms.addResult(
          studentId: 'S02',
          courseId: 'C01',
          score: 75.0,
        ),
        throwsException,
      );
    });

    test('rejects an invalid score (< 0 or > 100)', () {
      expect(
        () => lms.addResult(
          studentId: 'S01',
          courseId: 'C01',
          score: -5.0,
        ),
        throwsException,
      );

      expect(
        () => lms.addResult(
          studentId: 'S01',
          courseId: 'C01',
          score: 105.0,
        ),
        throwsException,
      );
    });

    test('rejects duplicate results for the same student and course', () {
      lms.addResult(studentId: 'S01', courseId: 'C01', score: 85.0);
      expect(
        () => lms.addResult(studentId: 'S01', courseId: 'C01', score: 90.0),
        throwsException,
      );
    });
  });

  // ==========================================
  // TASK 5: REMOVE A STUDENT RESULT
  // ==========================================
  group('Task 5: Remove Result', () {
    late String resId;

    setUp(() {
      lms.addStudent(studentId: 'S01', studentName: 'Alice');
      lms.addStudent(studentId: 'S02', studentName: 'Bob');
      lms.addCourse(courseId: 'C01', courseName: 'Mobile Development');
      lms.enrollStudent(studentId: 'S01', courseId: 'C01');
      lms.enrollStudent(studentId: 'S02', courseId: 'C01');

      final r1 = lms.addResult(
        studentId: 'S01',
        courseId: 'C01',
        score: 85.0,
        resultId: 'R01',
      );
      lms.addResult(
        studentId: 'S02',
        courseId: 'C01',
        score: 95.0,
        resultId: 'R02',
      );
      resId = r1.id;
    });

    test('removes an existing result', () {
      lms.removeResult(resultId: resId);
      expect(lms.results.any((r) => r.id == resId), isFalse);
    });

    test('rejects removal of a nonexistent result', () {
      expect(
        () => lms.removeResult(resultId: 'NON_EXISTENT_RESULT'),
        throwsException,
      );
    });

    test('verifies that the result is no longer available', () {
      lms.removeResult(resultId: resId);
      expect(lms.getResultsForStudent('S01').isEmpty, isTrue);
    });

    test('verifies student, course, and unrelated results remain unchanged', () {
      lms.removeResult(resultId: resId);

      // Student and course still intact
      expect(lms.findStudent('S01').name, 'Alice');
      expect(lms.findCourse('C01').name, 'Mobile Development');

      // Unrelated result for S02 is unaffected
      final s02Results = lms.getResultsForStudent('S02');
      expect(s02Results.length, 1);
      expect(s02Results.first.score, 95.0);
    });
  });

  // ==========================================
  // END-TO-END SCENARIO (Slide 8)
  // ==========================================
  group('Slide 8: End-to-End LMS Scenario', () {
    test('Scenario: create 2 students, 1 course, enroll both, add results, remove 1 student', () {
      // 1. Create two students
      lms.addStudent(studentId: 'S01', studentName: 'Alice');
      lms.addStudent(studentId: 'S02', studentName: 'Bob');

      // 2. Create a course
      lms.addCourse(courseId: 'C01', courseName: 'Mobile Development');

      // 3. Enroll both students
      lms.enrollStudent(studentId: 'S01', courseId: 'C01');
      lms.enrollStudent(studentId: 'S02', courseId: 'C01');

      // (Step 4: assignments is bonus task, skipped as requested)

      // 5. Add results for both students
      lms.addResult(studentId: 'S01', courseId: 'C01', score: 85.0);
      lms.addResult(studentId: 'S02', courseId: 'C01', score: 92.0);

      expect(lms.results.length, 2);

      // 6. Remove one student (S01)
      lms.removeStudent(studentId: 'S01');

      // Expected Result for the removed student:
      // • no longer exists in students
      expect(lms.students.any((s) => s.id == 'S01'), isFalse);

      // • is no longer enrolled in the course
      final course = lms.findCourse('C01');
      expect(course.isEnrolled('S01'), isFalse);

      // • has no results
      expect(lms.getResultsForStudent('S01').isEmpty, isTrue);

      // Expected Result for the other student:
      // • data must remain unchanged
      expect(lms.students.any((s) => s.id == 'S02'), isTrue);
      expect(lms.findStudent('S02').name, 'Bob');
      expect(course.isEnrolled('S02'), isTrue);
      final s02Results = lms.getResultsForStudent('S02');
      expect(s02Results.length, 1);
      expect(s02Results.first.score, 92.0);
    });
  });
}
