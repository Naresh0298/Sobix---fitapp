import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitapp/components/my_listViewPanel.dart';
import 'package:fitapp/components/my_panel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showAvg = false;
  final user = FirebaseAuth.instance.currentUser!;
  bool isLoading = false;
  int todaysPR = 0;
  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController<List<Map<String, dynamic>>>();

  Future<int> fetchTodaysPR() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily-progress')
        .where('date', isEqualTo: today)
        .get();

    int prCount = 0;

    // Sum up all the PR values from today's documents
    for (var doc in snapshot.docs) {
      prCount += (doc.data()['PR'] as int?) ?? 0; // Use 0 if 'PR' is null
    }

    return prCount;
  }

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  Stream<List<Map<String, dynamic>>> getDailyProgress() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily-progress')
        .orderBy('date')
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'date': data['date'],
          'total-lift': data['total-lift'] ?? 0.0,
        };
      }).toList();
    });
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    String date;
    try {
      date = DateFormat('MM/dd')
          .format(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
    } catch (_) {
      date = '';
    }
    return SideTitleWidget(meta: meta, child: Text(date, style: style));
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    String text = value.toInt().toString();
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  LineChartData mainData(List<Map<String, dynamic>> dailyProgress) {
    List<FlSpot> spots = dailyProgress.asMap().entries.map((entry) {
      int index = entry.key;
      var data = entry.value;
      return FlSpot(index.toDouble(), data['total-lift'] as double);
    }).toList();

    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: true),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: leftTitleWidgets,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData:
          FlBorderData(show: true, border: Border.all(color: Colors.black)),
      minX: 0,
      maxX: dailyProgress.length.toDouble(),
      minY: 0,
      maxY: dailyProgress
          .map((e) => e['total-lift'] as double)
          .reduce((a, b) => a > b ? a : b),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: true, color: Colors.green),
        ),
      ],
    );
  }

  void refreshData() {
    setState(() {
      isLoading = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily-progress')
        .orderBy('date')
        .get()
        .then((querySnapshot) {
      List<Map<String, dynamic>> updatedData = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'date': data['date'],
          'total-lift': data['total-lift'] ?? 0.0,
        };
      }).toList();

      _streamController.sink.add(updatedData);
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch today's PR when the widget is initialized
    fetchTodaysPR().then((prCount) {
      setState(() {
        print("prCount: $prCount"); // Debug log
        todaysPR = prCount; // Update the PR value
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DashBoard'),
        actions: [IconButton(onPressed: signUserOut, icon: Icon(Icons.logout))],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Progress',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyPanel(title: 'PG%', value: "60", color: Colors.green),
                    MyPanel(title: 'Weight', value: "74kg", color: Colors.blue),
                    MyPanel(title: 'PR', value: "$todaysPR", color: Colors.red),
                  ],
                ),
                SizedBox(height: 25),
                ElevatedButton(
                  onPressed: refreshData,
                  child: Text('Refresh Data'),
                ),
                SizedBox(height: 25),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _streamController.hasListener
                        ? _streamController.stream
                        : getDailyProgress(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          isLoading) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text('No data available'));
                      }

                      var dailyProgress = snapshot.data!;
                      return Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.70,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 18, left: 12, top: 24, bottom: 12),
                              child: LineChart(mainData(dailyProgress)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 25),
                Expanded(child: MyListViewPanel(count: 7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
