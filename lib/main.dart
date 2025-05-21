import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(MathPuzzleApp());
}

class MathPuzzleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Puzzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PuzzleScreen(),
    );
  }
}

class PuzzleScreen extends StatefulWidget {
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final int gridSize = 7;
  final int totalTime = 300; // total time in seconds (5 minutes)

  Timer? _timer;
  int _remainingSeconds = 300;
  bool timeUp = false;

  final List<List<String?>> puzzle = [
    ["3", "+", null, null, "=", "14", null],
    ["+", null, null, null, "+", null, null],
    ["1", null, null, null, "2", "x", "2"],
    ["=", null, null, null, "=", null, null],
    ["x", "4", "=", null, null, "=", null],
    ["x", null, null, null, null, null, null],
    ["3", "x", "=", "12", null, null, null],
  ];

  Map<String, String> userInputs = {};
  Map<String, bool> validationResults = {};

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _remainingSeconds = totalTime;
    timeUp = false;
    _timer?.cancel();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        setState(() {
          timeUp = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  bool isInput(int r, int c) => puzzle[r][c] == null;

  int? parseInt(String? s) {
    if (s == null) return null;
    return int.tryParse(s);
  }

  bool checkOperation(List<String?> parts) {
    if (parts.length != 5) return false;
    int? num1 = parseInt(parts[0]);
    String? op = parts[1];
    int? num2 = parseInt(parts[2]);
    String? equalSign = parts[3];
    int? result = parseInt(parts[4]);

    if (num1 == null || op == null || num2 == null || equalSign != "=" || result == null) {
      return false;
    }

    switch (op) {
      case "+":
        return num1 + num2 == result;
      case "-":
        return num1 - num2 == result;
      case "x":
        return num1 * num2 == result;
      case "/":
        if (num2 == 0) return false;
        return num1 ~/ num2 == result && num1 % num2 == 0;
      default:
        return false;
    }
  }

  void validatePuzzle() {
    validationResults.clear();

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize - 4; c++) {
        List<String?> slice = [];
        for (int i = 0; i < 5; i++) {
          String? cell = puzzle[r][c + i];
          if (cell == null) {
            cell = userInputs["$r-${c + i}"];
          }
          slice.add(cell);
        }
        if (slice[3] == "=" && slice[1] != null && ["+", "-", "x", "/"].contains(slice[1])) {
          bool valid = checkOperation(slice);
          for (int i = 0; i < 5; i++) {
            if (puzzle[r][c + i] == null) {
              validationResults["$r-${c + i}"] = valid;
            }
          }
        }
      }
    }

    for (int c = 0; c < gridSize; c++) {
      for (int r = 0; r < gridSize - 4; r++) {
        List<String?> slice = [];
        for (int i = 0; i < 5; i++) {
          String? cell = puzzle[r + i][c];
          if (cell == null) {
            cell = userInputs["${r + i}-$c"];
          }
          slice.add(cell);
        }
        if (slice[3] == "=" && slice[1] != null && ["+", "-", "x", "/"].contains(slice[1])) {
          bool valid = checkOperation(slice);
          for (int i = 0; i < 5; i++) {
            if (puzzle[r + i][c] == null) {
              validationResults["${r + i}-$c"] = valid;
            }
          }
        }
      }
    }

    setState(() {});
  }

  bool isPuzzleSolved() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (isInput(r, c)) {
          String key = "$r-$c";
          if (!userInputs.containsKey(key) || userInputs[key]!.isEmpty) return false;
          if (!validationResults.containsKey(key) || validationResults[key] != true) return false;
        }
      }
    }
    return true;
  }

  Widget buildCell(int r, int c) {
    String? val = puzzle[r][c];
    String key = "$r-$c";

    if (val != null) {
      return Container(
        alignment: Alignment.center,
        color: Colors.yellow[200],
        child: Text(
          val,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      bool valid = validationResults[key] ?? true;
      bool empty = !(userInputs.containsKey(key) && userInputs[key]!.isNotEmpty);
      Color bgColor;
      if (empty) {
        bgColor = Colors.white;
      } else {
        bgColor = valid ? Colors.green[200]! : Colors.red[200]!;
      }

      return Container(
        padding: EdgeInsets.all(1),
        color: bgColor,
        child: TextField(
          enabled: !timeUp,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 2,
          style: TextStyle(fontSize: 20),
          decoration: InputDecoration(
            counterText: "",
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          ),
          onChanged: (text) {
            if (text.length > 2) return;
            if (text.isNotEmpty && !RegExp(r'^\d+$').hasMatch(text)) return;

            setState(() {
              userInputs[key] = text;
            });
            validatePuzzle();
          },
          controller: TextEditingController(text: userInputs[key] ?? ""),
        ),
      );
    }
  }

  void resetPuzzle() {
    setState(() {
      userInputs.clear();
      validationResults.clear();
      timeUp = false;
    });
    startTimer();
  }

  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    bool solved = isPuzzleSolved();

    return Scaffold(
      appBar: AppBar(
        title: Text("Math Puzzle"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetPuzzle,
            tooltip: "Reset Puzzle",
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text(
            timeUp ? "⏰ Time's up! Puzzle locked." : "⏳ Time Remaining: ${formatTime(_remainingSeconds)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: timeUp ? Colors.red : Colors.black87,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              itemCount: gridSize * gridSize,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                childAspectRatio: 1,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemBuilder: (context, index) {
                int r = index ~/ gridSize;
                int c = index % gridSize;
                return buildCell(r, c);
              },
            ),
          ),
          if (solved)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "🎉 Puzzle solved! Congratulations! 🎉",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
            ),
        ],
      ),
    );
  }
}
