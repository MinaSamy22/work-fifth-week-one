import 'package:flutter/material.dart';

class QuizDetailScreen extends StatelessWidget {
  static const String routeName = '/QuizDetailScreen';

  final String quizTitle;
  final int correctAnswers;
  final int totalQuestions;

  const QuizDetailScreen({
    Key? key,
    required this.quizTitle,
    required this.correctAnswers,
    required this.totalQuestions,
  }) : super(key: key);

  String _getLevel(double percentage) {
    if (percentage >= 85) return 'Advanced';
    if (percentage >= 75) return 'Intermediate';
    if (percentage >= 50) return 'Beginner';
    return 'No Level';
  }

  @override
  Widget build(BuildContext context) {
    final double successPercentage = (correctAnswers / totalQuestions) * 100;
    final int wrongAnswers = totalQuestions - correctAnswers;
    final int marks = correctAnswers * 4;
    final int negativeMarks = wrongAnswers * 1;
    final int totalMarks = marks - negativeMarks;
    final String level = _getLevel(successPercentage);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF196AB3)), // Icon color to blue
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          quizTitle,
          style: const TextStyle(color: Color(0xFF196AB3),
            fontSize: 22,
            fontWeight: FontWeight.bold,), // Text color to blue
        ),
        centerTitle: true,

        elevation: 1, // Optional: adds subtle shadow for separation
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Score: $correctAnswers/$totalQuestions",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${successPercentage.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: successPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 16),
                    _buildResultRow("✅ Correct Answers:", "$correctAnswers"),
                    _buildResultRow("❌ Wrong Answers:", "$wrongAnswers"),
                    _buildResultRow("⭐ Marks Obtained:", "$marks"),
                    _buildResultRow("⚠️ Negative Marks:", "-$negativeMarks"),
                    _buildResultRow(
                      "🏆 Total Marks:",
                      "$totalMarks",
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildResultRow(
                      "📊 Your Level:",
                      level,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Test Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("✅ 4 marks for correct answer"),
                    Text("❌ 1 negative mark for incorrect answer"),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF196AB3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Return to Home",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Color(0xFF196AB3) : null,
            ),
          ),
        ],
      ),
    );
  }
}