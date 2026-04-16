// lib/common/utils/semester_calculator.dart

/// Calculates the current semester based on the student's batch and the current date.
/// Assumes Fall semester starts in August and Spring semester starts in February.
int calculateCurrentSemester(int batchYear) {
  final now = DateTime.now();
  final currentYear = now.year;
  final currentMonth = now.month;

  // Calculate the number of years that have passed since the batch started.
  int yearsPassed = currentYear - batchYear;

  // Determine the base semester from the years passed.
  // E.g., 0 years -> Sem 1/2, 1 year -> Sem 3/4, etc.
  int semester = yearsPassed * 2 + 1;

  // If we are in the Spring semester (roughly Feb-July), add 1 to the semester.
  // We assume the batch starts in the Fall (August).
  if (currentMonth >= 2 && currentMonth <= 7) {
    semester++;
  }

  // A student can't be in more than 8 semesters.
  return semester > 8 ? 8 : semester;
}
