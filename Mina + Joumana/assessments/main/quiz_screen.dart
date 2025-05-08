import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/quiz_model.dart';
import '../dialog messages/quiz_completion_dialog.dart';
import '../dialog messages/exit_confirmation_dialog.dart';
import '../dialog messages/timeout_dialog.dart';
import 'quiz_timer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  final String quizTitle;
  final Function(int)? onQuizCompleted;
  final int quizDuration;

  const QuizScreen({
    Key? key,
    required this.quizTitle,
    this.onQuizCompleted,
    this.quizDuration = 600,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  List<Question> questions = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedOption;
  bool answerSubmitted = false;
  List<int?> userAnswers = [];
  List<bool> alreadyCounted = [];
  bool quizCompleted = false;
  bool quizExited = false;
  bool _timeOutOccurred = false;
  late String _assessmentId;


  late QuizTimer _quizTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _calculateLevel(int score, int totalQuestions) {
    if (totalQuestions == 0) return 'No Level';

    double percentage = (score / totalQuestions) * 100;

    if (percentage >= 85) return 'Advanced';
    if (percentage >= 75) return 'Intermediate';
    if (percentage >= 50) return 'Beginner';
    return 'No Level';
  }


  Future<void> _saveQuizResults(String userId, int score, String assessmentId) async {
    try {
      final level = _calculateLevel(score, questions.length);

      await _firestore.collection('Assessment_Results').add({
        "UserId": userId,
        "AssessmentId": assessmentId,
        'quizTitle': widget.quizTitle,
        'level': level,
        'score': score,
        'totalQuestions': questions.length,
        'percentage': (score / questions.length) * 100,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('Quiz results saved successfully with level: $level');
    } catch (e) {
      debugPrint('Error saving quiz results: $e');
    }
  }

  Future<bool> _checkQuizStatus(String userId) async {
    final resultSnapshot = await _firestore
        .collection('Assessment_Results')
        .where('UserId', isEqualTo: userId)
        .where('AssessmentId', isEqualTo: _assessmentId)
        .limit(1)
        .get();

    return resultSnapshot.docs.isNotEmpty;
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quizTimer = QuizTimer(
      duration: widget.quizDuration,
      onTick: _handleTimerTick,
      onTimeout: _handleTimeOut,
    );
    _initializeQuiz();
    _quizTimer.start();
  }

  @override
  void dispose() {
    _quizTimer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _quizTimer.pause();
    } else if (state == AppLifecycleState.resumed) {
      _quizTimer.resume();
    }
  }

  void _handleTimerTick(int remaining) {
    if (mounted) setState(() {});
  }

  void _handleTimeOut() async {
    if (quizCompleted || _timeOutOccurred) return;
    setState(() => _timeOutOccurred = true);

    final score = _calculateCurrentScore();

    // Get the current user ID
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _saveQuizResults(userId, score, _assessmentId);
    } else {
      debugPrint('User not logged in. Cannot save quiz results.');
    }

    widget.onQuizCompleted?.call(score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TimeoutDialog(
        score: score,
        totalQuestions: questions.length,
        onOkPressed: () => Navigator.of(context)
          ..pop()
          ..pop(),
        questions: questions,
        userAnswers: userAnswers,
      ),
    );
  }



  Future<void> _initializeQuiz() async {
    try {
      // Load quiz document to get assessment ID
      final quizQuery = await _firestore
          .collection('Assessment')
          .where('title', isEqualTo: widget.quizTitle)
          .limit(1)
          .get();

      if (quizQuery.docs.isEmpty) {
        throw Exception('Assessment "${widget.quizTitle}" not found');
      }

      final quizDoc = quizQuery.docs.first;
      _assessmentId = quizDoc.id;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final alreadyCompleted = await _checkQuizStatus(userId);
      if (alreadyCompleted) {
        setState(() {
          errorMessage = 'You have already completed this assessment.';
          isLoading = false;
        });
        return;
      }

      await _loadQuizQuestionsFromFirebase();
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing quiz: ${e.toString()}';
        isLoading = false;
      });
    }
  }



  Future<void> _loadQuizQuestionsFromFirebase() async {
    try {
      final quizDoc = await _firestore.collection('Assessment').doc(_assessmentId).get();
      final questionsSnapshot = await quizDoc.reference.collection('Questions').get();

      if (questionsSnapshot.docs.isEmpty) {
        throw Exception('No questions found for ${widget.quizTitle}');
      }

      final List<Question> loadedQuestions = [];
      for (var doc in questionsSnapshot.docs) {
        final data = doc.data();
        loadedQuestions.add(Question(
          question: data['question'] ?? '',
          options: List<String>.from(data['options'] ?? []),
          answer: data['answer'] ?? '',
        ));
      }

      setState(() {
        questions = loadedQuestions;
        userAnswers = List<int?>.filled(loadedQuestions.length, null);
        alreadyCounted = List<bool>.filled(loadedQuestions.length, false);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading questions: ${e.toString()}';
        isLoading = false;
      });
      debugPrint('Error loading questions: $e');
    }
  }

  void selectAnswer(int optionIndex) {
    setState(() {
      selectedOption = questions[currentQuestionIndex].options[optionIndex];
      userAnswers[currentQuestionIndex] = optionIndex;
      answerSubmitted = false;
    });
  }


  int _calculateCurrentScore() {
    int score = 0;
    for (int i = 0; i <= currentQuestionIndex; i++) {
      if (userAnswers[i] != null &&
          questions[i].options[userAnswers[i]!] == questions[i].answer) {
        score++;
      }
    }
    return score;
  }

  Future<void> moveToNextQuestion() async {
    if (userAnswers[currentQuestionIndex] != null &&
        !alreadyCounted[currentQuestionIndex]) {
      final correctIndex = questions[currentQuestionIndex]
          .options
          .indexOf(questions[currentQuestionIndex].answer);
      if (userAnswers[currentQuestionIndex] == correctIndex) {
        correctAnswers++;
      }
      setState(() {
        alreadyCounted[currentQuestionIndex] = true;
      });
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOption = null;
        answerSubmitted = false;
      });
    } else {
      _quizTimer.dispose();
      setState(() => quizCompleted = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _saveQuizResults(userId, correctAnswers, _assessmentId);
      } else {
        debugPrint('User not logged in. Cannot save quiz results.');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => QuizCompletionDialog(
          correctAnswers: correctAnswers,
          totalQuestions: questions.length,
          questions: questions,
          userAnswers: userAnswers,
        ),
      );
      widget.onQuizCompleted?.call(correctAnswers);
    }
  }


  Future<bool> _onWillPop() async {
    if (quizCompleted || _timeOutOccurred) return true;

    _quizTimer.pause();
    final currentScore = _calculateCurrentScore();

    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => ExitConfirmationDialog(
        correctAnswers: currentScore,
        totalQuestions: questions.length,
      ),
    );

    if (shouldExit ?? false) {

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _saveQuizResults(userId, currentScore, _assessmentId);
      } else {
        debugPrint('User not logged in. Cannot save quiz results.');
      }

      setState(() => quizExited = true);
      widget.onQuizCompleted?.call(currentScore);
      return true;
    } else {
      _quizTimer.resume();
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null || quizExited || _timeOutOccurred) {
      return _buildStatusScreen();
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: const Color(0xFF196AB3),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = questions[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: const Color(0xFF196AB3),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [_buildTimerWidget()],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / questions.length,
                backgroundColor: Colors.grey.shade300,
                color: const Color(0xFF196AB3),
                minHeight: 10,
              ),
              const SizedBox(height: 20),
              Text(
                'Question ${currentQuestionIndex + 1} of ${questions.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                question.question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: [
                    ...question.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(option),
                          onTap: () => selectAnswer(index),
                          trailing: userAnswers[currentQuestionIndex] == index
                              ? const Icon(Icons.check_circle, color: Color(0xFF196AB3))
                              : null,
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentQuestionIndex > 0)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                currentQuestionIndex--;
                                selectedOption = userAnswers[currentQuestionIndex] != null
                                    ? questions[currentQuestionIndex]
                                    .options[userAnswers[currentQuestionIndex]!]
                                    : null;
                                answerSubmitted = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              side: const BorderSide(
                                  color: Color(0xFF196AB3), width: 1),
                            ),
                            child: const Text('Previous',
                                style: TextStyle(color: Color(0xFF196AB3))),
                          )
                        else
                          const SizedBox(width: 100),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => answerSubmitted = true);
                            Future.delayed(const Duration(milliseconds: 500), moveToNextQuestion);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF196AB3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Text(isLastQuestion ? 'Submit Assessment' : 'Next',
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: const Color(0xFF196AB3),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _timeOutOccurred ? Icons.timer_off : Icons.info,
                size: 50,
                color: _timeOutOccurred ? Colors.red : Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage ??
                    (_timeOutOccurred
                        ? 'Time expired! You scored ${_calculateCurrentScore()}/${questions.length}'
                        : 'You exited the assessment with ${_calculateCurrentScore()}/${questions.length} correct answers.'),
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF196AB3),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'Return to Assessment Home',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerWidget() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _quizTimer.timeRemaining <= 10
            ? (_quizTimer.timeRemaining % 2 == 0 ? Colors.red : Colors.red[800])
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 20, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _quizTimer.formattedTime,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _quizTimer.timeRemaining <= 10
                  ? Colors.white
                  : _quizTimer.timeRemaining <= 30
                  ? Colors.orange
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}