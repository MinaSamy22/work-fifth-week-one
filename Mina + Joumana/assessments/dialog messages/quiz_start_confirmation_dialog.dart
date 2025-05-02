import 'package:flutter/material.dart';

class QuizStartConfirmationDialog extends StatelessWidget {
  final String quizTitle;
  final int totalQuestions;

  const QuizStartConfirmationDialog({
    Key? key,
    required this.quizTitle,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const Icon(Icons.help_outline, color: Color(0xFF196AB3)),
          const SizedBox(width: 12),
          const Text('Start Assessment?', style: TextStyle(fontSize: 22)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You are about to start the "$quizTitle" assessment.',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          const Text('Important Notes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('• Total questions: $totalQuestions in one minute' , style: const TextStyle(fontSize: 14)),

          const Text('• You should click next to save your answer', style: TextStyle(fontSize: 14)),
          const Text('• You cannot exit once started', style: TextStyle(fontSize: 14)),
          const Text('• if you exit the assessment you will not be able to retake it again ', style: TextStyle(fontSize: 14, color: Colors.red,
          )),
          const SizedBox(height: 16),
          const Text('Are you ready to begin?',
              style: TextStyle(fontSize: 16)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('CANCEL', style: TextStyle(fontSize: 14)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF196AB3),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('START', style: TextStyle(fontSize: 15)),
        ),
      ],
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
    );
  }
}