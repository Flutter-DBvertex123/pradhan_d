import 'dart:async';
import 'package:flutter/material.dart';

class VotingTimerWidget extends StatefulWidget {
  const VotingTimerWidget({super.key});

  @override
  State<VotingTimerWidget> createState() => _VotingTimerWidgetState();
}

class _VotingTimerWidgetState extends State<VotingTimerWidget> {
  late Timer _timer;
  late DateTime votingStartTime;
  late DateTime _votingEndTime;

  @override
  void initState() {
    super.initState();
    votingStartTime = _calculateVotingStartTime();
    _votingEndTime = _calculateVotingEndTime();
    _timer = Timer.periodic(Duration(seconds: 1), _updateTimer);
  }

  DateTime _calculateVotingStartTime() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    final nextSunday = now.add(Duration(days: daysUntilSunday));
    return DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      21, // Change this to your desired starting hour
      0, // Change this to your desired starting minute
    );
  }

  DateTime _calculateVotingEndTime() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday;
    final nextSunday = now.add(Duration(days: daysUntilSunday));
    return DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      22, // Change this to your desired ending hour
      0, // Change this to your desired ending minute
    );
  }

  void _updateTimer(Timer timer) {
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    return "${duration.inDays} days ${duration.inHours.remainder(24)} hours ${duration.inMinutes.remainder(60)} minutes ${duration.inSeconds.remainder(60)} seconds";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remainingTime = _votingEndTime.isAfter(now)
        ? _votingEndTime.difference(now)
        : Duration.zero;

    return Container(
      padding: EdgeInsets.all(16.0),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          Text(
            "Voting Starts In",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            _formatDuration(remainingTime),
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
