import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key});

  @override
  State createState() => LeaderboardState();
}

class LeaderboardState extends State<Leaderboard> {
  DatabaseReference dbhandler = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> leaderboardList = [];

   // load leaderboard records after the first frame is drawn
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadLeaderboardRecords();
    });
  }


  DateTime today = DateTime.now();

  // Load leaderboardrecords from Firebase Realtime Database
  Future<void> loadLeaderboardRecords() async {
    List<Map<String, dynamic>> tempList = [];
    dbhandler.child("Leaderboard").onValue.listen((event) async {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic>? data =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          data.forEach((key, value) {
            String dateString = value['date'];
            DateTime date = DateFormat('dd-MM-yyyy').parse(dateString);

            if (isToday(date)) { // only dislays records from today
              Map<String, dynamic> scoreRecord = {
                'username': value['username'],
                'score': value['score'],
                'date': value['date'],
              };
              tempList.add(scoreRecord);
            } else {
              // Remove the leaderboard record if it is not from today
              dbhandler.child("Leaderboard").child(key).remove();
            }
          });
        }
      }

      // Sort the leaderboard records by score
      tempList.sort((a, b) => b['score'].compareTo(a['score']));

      setState(() {
        leaderboardList = tempList;
      });
    });
  }

  // Check if the date is today
  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30), // Add some spacing below app bar
              const Text(
                "Today's Leaderboard",
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: leaderboardList.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> record = leaderboardList[index];
                  return InkWell(
                    onTap: () {
                      // Handle item tap if needed
                    },
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: const Color.fromARGB(255, 255, 18, 18)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text("Username: ${record['username']}",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 98, 211, 136), fontSize: 26, fontWeight: FontWeight.bold)),
                        subtitle: Text("Score of ${record['score']} on ${record['date']}",
                            style: const TextStyle(
                                color: Color.fromARGB(255, 98, 211, 136), fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 240,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  loadLeaderboardRecords(); // Refresh records
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 226, 55, 55),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 240,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/quiz');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 98, 211, 136),
                ),
                child: const Text(
                  'Play Again', // goes back to strat quiz again
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
