import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class Quiz extends StatefulWidget {
  const Quiz({Key? key}) : super(key: key);

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  final DatabaseReference dbHandler = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> questionList = [];
  int currentIndex = 0;
  int score = 0;
  String username = "anonymous";

  // List of colors to itterate through
  List<Color> christmasButtonColorList = [
    const Color.fromARGB(255, 2, 170, 66), 
    const Color.fromARGB(255, 150, 10, 29),
    const Color.fromARGB(255, 18, 100, 45),
    const Color.fromARGB(255, 204, 8, 8),
    const Color.fromARGB(255, 98, 211, 136),
    const Color.fromARGB(255, 226, 55, 55),
  ];

  @override
  void initState() {
    super.initState();
    // First show the username popup
    WidgetsBinding.instance.addPostFrameCallback((_) => usernamePopup());
    loadQuestions();
  }

  void usernamePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        TextEditingController usernameController = TextEditingController();
        return AlertDialog(
          title: const Text("Enter Username"),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(hintText: "Username"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (usernameController.text.isNotEmpty) {
                  setState(() {
                    username = usernameController.text;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void loadQuestions() {
    dbHandler.child("Questions").onValue.listen((event) {
      List<Map<String, dynamic>> tempList = [];
      final value = event.snapshot.value;

      if (value == null) { //NULL CHECK
        tempList.add({
          "question": "Default Question",
          "answer1": "Answer 1",
          "answer2": "Answer 2",
          "answer3": "Answer 3",
          "answer4": "Answer 4",
          "correctAnswer": 1,
        });
      } else if (value is Map<dynamic, dynamic>) {
        value.forEach((key, val) {
          tempList.add({
            "question": val["question"] ?? "",
            "answer1": val["answer1"] ?? "",
            "answer2": val["answer2"] ?? "",
            "answer3": val["answer3"] ?? "",
            "answer4": val["answer4"] ?? "",
            "correctAnswer": val["correctAnswer"] ?? 0,
          });
        });
      } else if (value is List<dynamic>) {
        for (var item in value) {
          if (item is Map<dynamic, dynamic>) {
            tempList.add({
              "question": item["question"] ?? "",
              "answer1": item["answer1"] ?? "",
              "answer2": item["answer2"] ?? "",
              "answer3": item["answer3"] ?? "",
              "answer4": item["answer4"] ?? "",
              "correctAnswer": item["correctAnswer"] ?? 0,
            });
          }
        }
      }

      setState(() {
        questionList = tempList;
      });
    });
  }

  void checkAnswer(int selectedAnswer) {
    if (questionList.isNotEmpty) {
      if (selectedAnswer == questionList[currentIndex]["correctAnswer"]) {
        score++;
      }
      if (currentIndex < questionList.length - 1) {
        setState(() {
          currentIndex++;
        });
      } else {
        uploadScore();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Quiz Complete"),
            content: Text("Your final score is $score/${questionList.length}"),
            actions: [
              TextButton(
                onPressed: () {
                  //go to leaderboard
                  Navigator.pushNamed(context, '/leaderboard');
                },
                child: const Text("Go to Leaderboard"),
              ),
            ],
          ),
        );
      }
    }
  }

  // Reset the quiz - not currently used
  void resetQuiz() {
    setState(() {
      currentIndex = 0;
      score = 0;
    });
  }

  // Upload the score to the leaderboard In database
  void uploadScore() {
    String dateString = DateFormat('dd-MM-yyyy').format(DateTime.now());
    dbHandler.child("Leaderboard").push().set({
      "username": username,
      "score": score,
      "date": dateString,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(" ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: const Color.fromARGB(255, 40, 35, 46),
      ),
      body: questionList.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator if device offline or database issue 
          : SingleChildScrollView(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Qustion text ui
                  Padding(padding: const EdgeInsets.all(10), child:Text(
                    questionList[currentIndex]["question"],
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  )),
                  const SizedBox(height: 20),
                  // Buttons ui
                  for (int i = 1; i <= 4; i++)
                    SizedBox(
                      child: Column(children: [ 
                        SizedBox(
                          width: 300,
                          height: 80,
                          child:ElevatedButton(
                            onPressed: () => checkAnswer(i),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: christmasButtonColorList[i % christmasButtonColorList.length],
                            ),
                            child: Text(questionList[currentIndex]["answer$i"],
                              style: const TextStyle(fontSize: 24, color: Colors.white),
                        ))),
                        const SizedBox(height: 10),
                    ])),
                  const SizedBox(height: 20),
                  Text(
                    "Score: $score/${questionList.length}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),

            ),
    );
  }
}
