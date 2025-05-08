import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../Features/main_student.dart';
import 'quiz_detail_screen.dart';
import 'quiz_screen.dart';
import '../dialog messages/quiz_start_confirmation_dialog.dart';

class QuizHomeScreen extends StatefulWidget {
  static const String routeName = '/QuizHomeScreen';

  const QuizHomeScreen({Key? key}) : super(key: key);

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  bool _isLoading = true;
  String searchText = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> quizResults = {};
  List<Map<String, dynamic>> quizzes = [];
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    quizResults.clear(); // 🔥 Clear cached quiz results for new sessions
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      quizResults.clear();  // Clear any cached results
      _initializeData();    // Reload results for current user
    }
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadQuizResults(),
      _loadQuizzesFromFirestore(),
    ]);
    setState(() => _isLoading = false);
  }


  Future<void> _loadQuizResults() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 🔥 Clear previous results to avoid leaking data between users
    setState(() {
      quizResults.clear();
    });

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_results')
        .get();

    setState(() {
      quizResults = {
        for (var doc in snapshot.docs)
          doc.id: {'correct': doc['correct'], 'total': doc['total']}
      };
    });

    print("Loaded results for user: ${user.uid}");
  }



  Future<void> _loadQuizzesFromFirestore() async {
    final snapshot = await _firestore.collection('Assessment').get();
    List<Map<String, dynamic>> loadedQuizzes = [];

    for (var doc in snapshot.docs) {
      final title = doc['title'];
      final questionsSnapshot = await _firestore
          .collection('Assessment')
          .doc(doc.id)
          .collection('Questions')
          .get();

      int questionCount = questionsSnapshot.size;
      String time = getStaticTimeForQuiz(title);

      loadedQuizzes.add({
        'title': title,
        'questions': questionCount,
        'time': time,
      });
    }

    setState(() {
      quizzes = loadedQuizzes;
    });
  }

  String getStaticTimeForQuiz(String title) {
    switch (title) {
      case "Cyber Security":
      case "Networking":
        return "10 mins";
      case "Backend Developer":
      case "UI/UX Design":
        return "10 mins";
      case "Software Development":
        return "10 mins";
      default:
        return "10 mins";
    }
  }

  Future<void> _saveQuizResult(String title, int correct, int total) async {
    final userId = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('quiz_results')
        .doc(title)
        .set({
      'correct': correct,
      'total': total,
    });

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
          icon: Icon(Icons.arrow_back, color: Color(0xFF2252A1)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search for an Assessment...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                onChanged: (value) =>
                    setState(() => searchText = value.toLowerCase()),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: quizzes
                    .where((quiz) =>
                    quiz['title'].toLowerCase().contains(searchText))
                    .length,
                itemBuilder: (context, index) {
                  final filteredQuizzes = quizzes
                      .where((quiz) => quiz['title']
                      .toLowerCase()
                      .contains(searchText))
                      .toList();
                  final quiz = filteredQuizzes[index];
                  final hasTakenQuiz =
                  quizResults.containsKey(quiz['title']);
                  final correct = hasTakenQuiz
                      ? quizResults[quiz['title']]!['correct']
                      : 0;
                  final total = hasTakenQuiz
                      ? quizResults[quiz['title']]!['total']
                      : quiz['questions'];

                  return QuizCard(
                    title: quiz['title'],
                    questions: total,
                    correct: correct,
                    time: quiz['time'],
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
                                _saveQuizResult(
                                    quiz['title'], correctAnswers, quiz['questions']);
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
  final String time;
  final bool isTaken;
  final VoidCallback onTap;

  const QuizCard({
    Key? key,
    required this.title,
    required this.questions,
    required this.correct,
    required this.time,
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
      case 'Advanced':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Beginner':
        return Colors.blueGrey;
      default:
        return Colors.grey;
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
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.question_answer,
                    size: 18, color: Colors.blueGrey),
                const SizedBox(width: 5),
                Text("Questions: $questions",
                    style:
                    const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 18, color: Colors.blueGrey),
                const SizedBox(width: 5),
                Text("Time: $time",
                    style:
                    const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            if (isTaken) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: Colors.green),
                  const SizedBox(width: 5),
                  Text("Correct: $correct",
                      style: const TextStyle(
                          fontSize: 14, color: Colors.green)),
                  const SizedBox(width: 16),
                  const Icon(Icons.cancel, size: 18, color: Colors.red),
                  const SizedBox(width: 5),
                  Text("Wrong: ${questions - correct}",
                      style:
                      const TextStyle(fontSize: 14, color: Colors.red)),
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
                    width: successRate *
                        (MediaQuery.of(context).size.width - 64),
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blueGrey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Your Level: ",
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: levelColor, width: 1),
                    ),
                    child: Text(
                      level,
                      style: TextStyle(
                          color: levelColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isTaken
                    ? onTap
                    : () => _showStartConfirmation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isTaken ? Colors.blueGrey : const Color(0xFF196AB3),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isTaken ? "View Details" : "Start ",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
