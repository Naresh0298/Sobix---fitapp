import 'package:fitapp/components/my_listViewPanel.dart';
import 'package:fitapp/components/my_panel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  int todaysPR = 0;
  double pgPercentage = 60.0; // Initial PG% value
  String weight = "--"; // Initial weight
  final StreamController<List<Map<String, dynamic>>> _streamController =
      StreamController<List<Map<String, dynamic>>>();

  final user = FirebaseAuth.instance.currentUser!;

  String today = DateTime.now().toIso8601String().substring(0, 10);

  Future<void> updateWeight(String newWeight, String date) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in");
    }

    // Update the weight in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('active-dates')
        .doc(date)
        .update({'weight': newWeight});

    setState(() {
      weight = newWeight;
    });
  }

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

    for (var doc in snapshot.docs) {
      prCount += (doc.data()['PR'] as int?) ?? 0;
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

  void filterData(String timeRange) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (timeRange) {
      case '1 week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case '1 month':
        startDate = now.subtract(Duration(days: 30));
        break;
      case '3 months':
        startDate = now.subtract(Duration(days: 90));
        break;
      default:
        startDate = now.subtract(Duration(days: 7));
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily-progress')
        .orderBy('date')
        .where('date',
            isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate))
        .where('date',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(now))
        .get()
        .then((querySnapshot) {
      List<Map<String, dynamic>> filteredData = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'date': data['date'],
          'total-lift': data['total-lift'] ?? 0.0,
        };
      }).toList();

      _streamController.sink.add(filteredData);
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
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    return Text('${value.toInt()} kg', style: style, textAlign: TextAlign.left);
  }

  double getYAxisInterval(double maxLift) {
    // Calculate the interval for 5 values on the y-axis
    double interval =
        (maxLift / 5).ceilToDouble(); // Divide by 4 to have 5 points

    // Make sure we get an interval that makes sense
    if (interval < 50) return 50;
    if (interval < 100) return 100;
    if (interval < 250) return 450;
    if (interval < 250) return 450;

    return 500;
  }

  LineChartData mainData(List<Map<String, dynamic>> dailyProgress) {
    List<FlSpot> liftSpots = [];
    List<FlSpot> weightSpots = [];
    List<String> dates = [];

    for (int i = 0; i < dailyProgress.length; i++) {
      var data = dailyProgress[i];
      DateTime date = DateFormat('yyyy-MM-dd').parse(data['date']);
      double weightLifted = data['total-lift'] as double;
      double weight = data['weight'] as double? ??
          0.0; // Assuming weight is stored under 'weight' field

      liftSpots.add(FlSpot(i.toDouble(), weightLifted));
      weightSpots.add(FlSpot(i.toDouble(), weight));
      dates.add(DateFormat('MM/dd').format(date));
    }

    double maxLiftValue = liftSpots.isNotEmpty
        ? liftSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 100;

    double maxWeightValue = weightSpots.isNotEmpty
        ? weightSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
        : 100;

    double maxYValue =
        maxLiftValue > maxWeightValue ? maxLiftValue : maxWeightValue;

    // Calculate the interval and maxY for the y-axis
    double interval = getYAxisInterval(maxYValue);
    double maxY =
        (maxYValue / interval).ceil() * interval; // Round up to make maxY fit

    return LineChartData(
      clipData: FlClipData.all(),
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < dates.length) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(dates[value.toInt()],
                      style: TextStyle(fontSize: 12)),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: interval,
            getTitlesWidget: leftTitleWidgets,
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.black, width: 1),
      ),
      minX: 0,
      maxX: dailyProgress.length.toDouble() - 1,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: liftSpots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.4),
                Colors.blue.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // LineChartBarData(
        //   spots: weightSpots,
        //   isCurved: true,
        //   color: Colors.green, // Green line for weight data
        //   barWidth: 4,
        //   isStrokeCapRound: true,
        //   belowBarData: BarAreaData(
        //     show: true,
        //     gradient: LinearGradient(
        //       colors: [
        //         Colors.green.withOpacity(0.4),
        //         Colors.green.withOpacity(0.1),
        //       ],
        //       begin: Alignment.topCenter,
        //       end: Alignment.bottomCenter,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchTodaysPR().then((prCount) {
      setState(() {
        todaysPR = prCount;
      });
    });
    filterData('1 week'); // Load 1 week data by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
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
                    MyPanel(
                        title: 'PG%',
                        value: "${pgPercentage}%",
                        color: Colors.green),
                    GestureDetector(
                      onTap: () {
                        _showWeightDialog();
                      },
                      child: MyPanel(
                          title: 'Weight',
                          value: weight + "kg",
                          color: Colors.blue),
                    ),
                    MyPanel(title: 'PR', value: "$todaysPR", color: Colors.red),
                  ],
                ),
                SizedBox(height: 25),
                // ElevatedButton(
                //   onPressed: refreshData,
                //   child: Text('Refresh Data'),
                // ),
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
                            aspectRatio: 1.75,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 10, left: 1, top: 2, bottom: 1),
                              child: LineChart(mainData(dailyProgress)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => filterData('1 week'),
                      child: Text('1 Week'),
                    ),
                    ElevatedButton(
                      onPressed: () => filterData('1 month'),
                      child: Text('1 Month'),
                    ),
                    ElevatedButton(
                      onPressed: () => filterData('3 months'),
                      child: Text('3 Months'),
                    ),
                  ],
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

  _showWeightDialog() {
    TextEditingController weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Weight'),
          content: TextField(
            controller: weightController,
            decoration: InputDecoration(hintText: "Enter new weight"),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newWeight = weightController.text;
                if (newWeight.isNotEmpty) {
                  updateWeight(newWeight, today);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
