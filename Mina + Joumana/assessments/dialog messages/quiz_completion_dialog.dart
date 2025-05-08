import 'package:flutter/material.dart';
import '../model/quiz_model.dart';
import 'quiz_review_dialog.dart';

class QuizCompletionDialog extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final List<Question> questions;
  final List<int?> userAnswers;

  const QuizCompletionDialog({
    Key? key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.questions,
    required this.userAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double percentage = (correctAnswers / totalQuestions) * 100;
    final String performance = _getPerformanceText(percentage);
    final Color performanceColor = _getPerformanceColor(percentage);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      elevation: 8,
      backgroundColor: backgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated celebration container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      performanceColor.withOpacity(0.3),
                      performanceColor.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getPerformanceIcon(percentage),
                    size: 60,
                    color: performanceColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Performance text with animated scale
              AnimatedScale(
                scale: 1.05,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  performance,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: performanceColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Score circle with percentage
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      color: performanceColor,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$correctAnswers/$totalQuestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: performanceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Feedback message with decorative elements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: performanceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: performanceColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getFeedbackIcon(percentage),
                      size: 28,
                      color: performanceColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getFeedbackMessage(percentage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons with improved spacing
              Column(
                children: [
                  _buildReviewButton(context, performanceColor),
                  const SizedBox(height: 12),
                  _buildHomeButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context, Color performanceColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context); // Close current dialog
          showDialog(
            context: context,
            builder: (context) => QuizReviewDialog(
              questions: questions,
              userAnswers: userAnswers,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: performanceColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: performanceColor.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'REVIEW ANSWERS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 20, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'RETURN HOME',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getPerformanceText(double percentage) {
    if (percentage >= 90) return 'EXCELLENT!';
    if (percentage >= 80) return 'GREAT JOB!';
    if (percentage >= 60) return 'GOOD WORK';
    if (percentage >= 40) return 'KEEP TRYING';
    return 'NEED PRACTICE';
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.blueGrey;
    return Colors.grey;
  }

  IconData _getPerformanceIcon(double percentage) {
    if (percentage >= 90) return Icons.emoji_events;
    if (percentage >= 80) return Icons.star;
    if (percentage >= 60) return Icons.thumb_up;
    if (percentage >= 40) return Icons.school;
    return Icons.autorenew;
  }

  IconData _getFeedbackIcon(double percentage) {
    if (percentage >= 90) return Icons.celebration;
    if (percentage >= 80) return Icons.thumb_up_alt;
    if (percentage >= 60) return Icons.sentiment_satisfied_alt;
    if (percentage >= 40) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getFeedbackMessage(double percentage) {
    if (percentage >= 90) {
      return 'Incredible! You achieved a perfect score! Your hard work and mastery of this topic are truly inspiring. Keep it up!';
    } else if (percentage >= 80) {
      return 'Great work! You have a strong grasp of the material. A little more practice, and you’ll reach perfection!';
    } else if (percentage >= 60) {
      return 'Good effort! You’re doing well, and with some extra practice, you’ll improve even more!';
    } else if (percentage >= 40) {
      return 'You\'re making progress! Reviewing will help strengthen your knowledge.';
    } else {
      return 'Every step forward is a win! Keep practicing, and don’t forget our courses to strengthen your skills even further!';
    }
  }
}