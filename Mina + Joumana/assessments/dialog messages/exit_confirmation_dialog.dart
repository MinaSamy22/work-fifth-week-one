import 'package:flutter/material.dart';

class ExitConfirmationDialog extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;

  const ExitConfirmationDialog({
    Key? key,
    required this.correctAnswers,
    required this.totalQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double percentage = (correctAnswers / totalQuestions) * 100;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text('Assessment Exit?', style: TextStyle(fontSize: 22)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Do you want to leave the assessment.',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Current score: $correctAnswers/$totalQuestions',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('(${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),

          const SizedBox(height: 8),
          const Text('You won\'t be able to retake it.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('CONTINUE', style: TextStyle(fontSize: 14)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF196AB3),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('EXIT ANYWAY', style: TextStyle(fontSize: 14)),
        ),
      ],
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16),
    );
  }
}