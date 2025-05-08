import 'package:flutter/material.dart';
import '../model/quiz_model.dart';

class QuizReviewDialog extends StatelessWidget {
  final List<Question> questions;
  final List<int?> userAnswers;

  const QuizReviewDialog({
    Key? key,
    required this.questions,
    required this.userAnswers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFFFFC7);

    // Calculate statistics
    final correctCount = questions.where((q) {
      final index = questions.indexOf(q);
      return userAnswers[index] != null &&
          q.options[userAnswers[index]!] == q.answer;
    }).length;

    final incorrectCount = questions.where((q) {
      final index = questions.indexOf(q);
      return userAnswers[index] != null &&
          q.options[userAnswers[index]!] != q.answer;
    }).length;

    final unansweredCount = userAnswers.where((a) => a == null).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, isDarkMode),
          _buildStatsBar(correctCount, incorrectCount, unansweredCount, primaryColor),
          _buildQuestionsList(context, isDarkMode, primaryColor),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Assessment Review',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        
        ],
      ),
    );
  }

  Widget _buildStatsBar(int correct, int incorrect, int unanswered, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        border: Border.symmetric(
          horizontal: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Correct', correct, Colors.green),
          _buildStatItem('Incorrect', incorrect, Colors.red),
          _buildStatItem('Unanswered', unanswered, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsList(BuildContext context, bool isDarkMode, Color primaryColor) {
    return Flexible(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            final userAnswerIndex = userAnswers[index];
            final correctAnswerIndex = question.options.indexOf(question.answer);
            final isCorrect = userAnswerIndex != null &&
                question.options[userAnswerIndex] == question.answer;
            final isUnanswered = userAnswerIndex == null;

            return _buildQuestionCard(
              index: index,
              question: question,
              isCorrect: isCorrect,
              isUnanswered: isUnanswered,
              userAnswerIndex: userAnswerIndex,
              correctAnswerIndex: correctAnswerIndex,
              isDarkMode: isDarkMode,
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required Question question,
    required bool isCorrect,
    required bool isUnanswered,
    required int? userAnswerIndex,
    required int correctAnswerIndex,
    required bool isDarkMode,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildQuestionIndicator(index, isCorrect, isUnanswered, isDarkMode),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.question,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...question.options.asMap().entries.map((e) =>
                _buildOption(e.key, e.value, correctAnswerIndex, userAnswerIndex, isDarkMode)),
            const SizedBox(height: 8),
            _buildAnswerFeedback(isCorrect, isUnanswered, question, userAnswerIndex, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionIndicator(int index, bool isCorrect, bool isUnanswered, bool isDarkMode) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isUnanswered ? Colors.orange.withOpacity(0.2) :
        isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: isUnanswered ? Colors.orange :
          isCorrect ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Text(
        '${index + 1}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildOption(int index, String option, int correctIndex, int? userIndex, bool isDarkMode) {
    final isCorrect = index == correctIndex;
    final isUserAnswer = index == userIndex;
    final isWrong = isUserAnswer && !isCorrect;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.withOpacity(0.2) :
              isWrong ? Colors.red.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCorrect ? Colors.green :
                isWrong ? Colors.red : Colors.grey,
                width: isCorrect || isWrong ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  fontWeight: isCorrect || isWrong ? FontWeight.bold : FontWeight.normal,
                  color: isCorrect ? Colors.green :
                  isWrong ? Colors.red :
                  isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              option,
              style: TextStyle(
                color: isCorrect ? Colors.green :
                isWrong ? Colors.red :
                isDarkMode ? Colors.white : Colors.black,
                fontWeight: isCorrect || isWrong ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect || isWrong)
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerFeedback(bool isCorrect, bool isUnanswered, Question question, int? userAnswerIndex, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnanswered ? Colors.orange.withOpacity(0.1) :
        isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnanswered ? Colors.orange.withOpacity(0.3) :
          isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUnanswered ? Icons.help_outline :
                isCorrect ? Icons.check_circle_outline : Icons.error_outline,
                color: isUnanswered ? Colors.orange :
                isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isUnanswered ? 'Not answered' :
                isCorrect ? 'Correct answer' : 'Incorrect answer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUnanswered ? Colors.orange :
                  isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          if (!isUnanswered && !isCorrect) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Correct answer was: '),
                  TextSpan(
                    text: question.answer,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF196AB3),
            foregroundColor: Colors.white, // White text
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),

            ),
          ),
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
          child: const Text(
            'Return to Home',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,

            ),
          ),
        ),
      ),
    );
  }
}