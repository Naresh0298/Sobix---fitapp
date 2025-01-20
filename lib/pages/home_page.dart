import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitapp/components/my_listViewPanel.dart';
import 'package:fitapp/components/my_panel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Import StreamController

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showAvg = false;
  final user = FirebaseAuth.instance.currentUser!;
  bool isLoading = false; // Flag to track loading state

  // StreamController to manually control the stream
  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController<List<Map<String, dynamic>>>();

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  // Fetch daily progress data
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

  // Custom Title Widgets for X-axis (Dates)
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    Widget text;
    var date = DateFormat('MM/dd')
        .format(DateTime.fromMillisecondsSinceEpoch(value.toInt()));
    text = Text(date, style: style);
    return SideTitleWidget(meta: meta, child: text);
  }

  // Custom Title Widgets for Y-axis (Total Lift)
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
          color: Colors.blue, // Gradient color
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(show: true, color: Colors.green),
        ),
      ],
    );
  }

  // Method to trigger refresh of data
  void refreshData() {
    // Fetch the latest data and add it to the stream
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

      _streamController.sink.add(updatedData); // Add data to stream
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _streamController.close(); // Don't forget to close the stream
    super.dispose();
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
                    MyPanel(title: 'PR', value: "2", color: Colors.red),
                  ],
                ),
                SizedBox(height: 25),
                // Refresh button
                ElevatedButton(
                  onPressed: refreshData,
                  child: Text('Refresh Data'),
                ),
                SizedBox(height: 25),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _streamController.stream.isEmpty
                        ? getDailyProgress() // Use default stream if no refresh
                        : _streamController.stream, // Use custom stream
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
                          SizedBox(
                            width: 60,
                            height: 34,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  showAvg = !showAvg;
                                });
                              },
                              child: Text(
                                'avg',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: showAvg
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.white,
                                ),
                              ),
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
