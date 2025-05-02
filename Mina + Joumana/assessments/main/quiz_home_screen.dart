import 'package:flutter/material.dart';
import '../../Features/main_student.dart';
import 'quiz_detail_screen.dart';
import 'quiz_screen.dart';
import '../dialog messages/quiz_start_confirmation_dialog.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';

class QuizHomeScreen extends StatefulWidget {
  static const String routeName = '/QuizHomeScreen';

  const QuizHomeScreen({Key? key}) : super(key: key);

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  String searchText = "";
  late SharedPreferences prefs;
  Map<String, dynamic> quizResults = {};

  final List<Map<String, dynamic>> quizzes = [
    {'title': "Cyber Security", 'questions': 10, 'time': "10 mins"},
    {'title': "Networking", 'questions': 10, 'time': "10 mins"},
    {'title': "Software Development", 'questions': 10, 'time': "10 mins"},
    {'title': "Frontend Developer", 'questions': 10, 'time': "10 mins"},
    {'title': "Backend Developer", 'questions': 10, 'time': "10 mins"},
    {'title': "FullStack Developer", 'questions': 10, 'time': "10 mins"},
    {'title': "Mobile Application Development", 'questions': 10, 'time': "10 mins"},
    {'title': "Operating System", 'questions': 10, 'time': "10 mins"},
    {'title': "UI/UX Design", 'questions': 10, 'time': "10 mins"},
    {'title': "Cloud Computing", 'questions': 10, 'time': "10 mins"},
    {'title': "Database", 'questions': 10, 'time': "10 mins"},
    {'title': "Database Administrator", 'questions': 10, 'time': "10 mins"},
    {'title': "Data Science and Analysis", 'questions': 10, 'time': "10 mins"},
    {'title': "C Programming language", 'questions': 10, 'time': "10 mins"},
    {'title': "C++ Programming language", 'questions': 10, 'time': "10 mins"},
    {'title': "C# Programming language", 'questions': 10, 'time': "10 mins"},
    {'title': "Information Technology", 'questions': 10, 'time': "10 mins"},
    {'title': "Software Engineering", 'questions': 10, 'time': "10 mins"},
    {'title': "Project Management", 'questions': 10, 'time': "10 mins"},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuizResults();
  }

  Future<void> _loadQuizResults() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var quiz in quizzes) {
        final title = quiz['title'];
        if (prefs.containsKey('$title-correct')) {
          quizResults[title] = {
            'correct': prefs.getInt('$title-correct') ?? 0,
            'total': prefs.getInt('$title-total') ?? quiz['questions'],
          };
        }
      }
    });
  }

  Future<void> _saveQuizResult(String title, int correct, int total) async {
    await prefs.setInt('$title-correct', correct);
    await prefs.setInt('$title-total', total);
    setState(() {
      quizResults[title] = {'correct': correct, 'total': total};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Assessments",
          style: TextStyle(
              color: Color(0xFF2252A1),
              fontSize: 22,
              fontWeight: FontWeight.bold),

        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)), // Optional: make the back arrow the same color
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
        ),

      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search for an Assessment...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onChanged: (value) => setState(() => searchText = value.toLowerCase()),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: quizzes.where((quiz) => quiz['title'].toLowerCase().contains(searchText)).length,
                itemBuilder: (context, index) {
                  final filteredQuizzes = quizzes.where((quiz) => quiz['title'].toLowerCase().contains(searchText)).toList();
                  final quiz = filteredQuizzes[index];
                  final hasTakenQuiz = quizResults.containsKey(quiz['title']);
                  final correct = hasTakenQuiz ? quizResults[quiz['title']]!['correct'] : 0;
                  final total = hasTakenQuiz ? quizResults[quiz['title']]!['total'] : quiz['questions'];

                  return QuizCard(
                    title: quiz['title'],
                    questions: total,
                    correct: correct,
                    isTaken: hasTakenQuiz,
                    onTap: () {
                      if (hasTakenQuiz) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizDetailScreen(
                              quizTitle: quiz['title'],
                              correctAnswers: correct,
                              totalQuestions: total,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(
                              quizTitle: quiz['title'],
                              onQuizCompleted: (correctAnswers) {
                                _saveQuizResult(quiz['title'], correctAnswers, quiz['questions']);
                              },
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final String title;
  final int questions;
  final int correct;
  final bool isTaken;
  final VoidCallback onTap;

  const QuizCard({
    Key? key,
    required this.title,
    required this.questions,
    required this.correct,
    required this.isTaken,
    required this.onTap,
  }) : super(key: key);

  String getLevel(double percentage) {
    if (percentage >= 85) return 'Advanced';
    if (percentage >= 75) return 'Intermediate';
    if (percentage >= 50) return 'Beginner';
    return 'No Level';
  }

  Color getLevelColor(String level) {
    switch (level) {
      case 'Advanced': return Colors.green;
      case 'Intermediate': return Colors.orange;
      case 'Beginner': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  Future<void> _showStartConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => QuizStartConfirmationDialog(
        quizTitle: title,
        totalQuestions: questions,
      ),
    );

    if (confirmed ?? false) {
      onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double successRate = isTaken ? correct / questions : 0;
    final double successPercent = successRate * 100;
    final String level = getLevel(successPercent);
    final Color levelColor = getLevelColor(level);

    return Card(
      elevation: 12,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.black.withOpacity(0.2),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.question_answer, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 5),
                Text("Questions: $questions", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            // NEW: Add Time Row (below Questions)
            const SizedBox(height: 4), // Small spacing
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 5),
                Text("Time: 1 min", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            if (isTaken) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: Colors.green),
                  const SizedBox(width: 5),
                  Text("Correct: $correct", style: const TextStyle(fontSize: 14, color: Colors.green)),
                  const SizedBox(width: 16),
                  const Icon(Icons.cancel, size: 18, color: Colors.red),
                  const SizedBox(width: 5),
                  Text("Wrong: ${questions - correct}", style: const TextStyle(fontSize: 14, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                  ),
                  Container(
                    height: 6,
                    width: successRate * (MediaQuery.of(context).size.width - 64),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: successPercent >= 70
                          ? Colors.green
                          : successPercent >= 50
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Success: ${successPercent.toStringAsFixed(1)}%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Your Level: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: levelColor, width: 1),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isTaken ? onTap : () => _showStartConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTaken ? Colors.blueGrey : Color(0xFF196AB3),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isTaken ? "View Details" : "Start ",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

