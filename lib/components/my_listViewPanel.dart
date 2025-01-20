import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitapp/pages/exercisedetailsupdate_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyListViewPanel extends StatelessWidget {
  final int count;

  const MyListViewPanel({
    super.key,
    required this.count,
  });

  // Helper method to get active dates
  Stream<List<String>> getActiveDates() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    var activeDatesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('active-dates');

    return activeDatesRef.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return doc.id; // The document ID is the date
      }).toList();
    });
  }

  // Helper method to get total lift and number of PRs for a specific date
  Future<Map<String, dynamic>> getTotalLiftAndPRs(String date) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception("User not logged in");
    }

    var totalLiftRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(date)
        .collection('total-lift-log');

    var snapshot = await totalLiftRef.get();

    double totalLift = 0.0;
    int prCount = 0;

    for (var doc in snapshot.docs) {
      totalLift += doc['total-weight'] ?? 0.0;
      if (doc['PR'] == 'YES') {
        prCount++;
      }
    }

    return {
      'totalLift': totalLift,
      'prCount': prCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // StreamBuilder to listen to active dates
          StreamBuilder<List<String>>(
            stream: getActiveDates(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // No active dates available, show today's panel
                String today =
                    DateTime.now().toIso8601String().substring(0, 10);
                return _buildTodayPanel(today, context);
              } else {
                // Active dates are available
                List<String> activeDates = snapshot.data!;

                // Sort active dates in descending order (most recent date first)
                activeDates
                    .sort((a, b) => b.compareTo(a)); // For descending order

                // Get today's date in string format (YYYY-MM-DD)
                String today =
                    DateTime.now().toIso8601String().substring(0, 10);

                // Check if today's date is available in active dates
                bool isTodayAvailable = activeDates.contains(today);

                // Start building the list
                List<Widget> listItems = [];

                // Add empty panel for today's date if not available
                if (!isTodayAvailable) {
                  listItems.add(_buildTodayPanel(today, context));
                }

                // Add active date items
                listItems.addAll(activeDates.map((date) {
                  return FutureBuilder<Map<String, dynamic>>(
                    future: getTotalLiftAndPRs(date),
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          title: Text('Loading...'),
                        );
                      } else if (futureSnapshot.hasError) {
                        return ListTile(
                          title: Text('Error: ${futureSnapshot.error}'),
                        );
                      } else if (!futureSnapshot.hasData) {
                        return ListTile(
                          title: Text('No data available'),
                        );
                      } else {
                        var data = futureSnapshot.data!;
                        double totalLift = data['totalLift'];
                        int prCount = data['prCount'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExerciseDetailsUpdatePage(date: date),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                'Total Lift: $totalLift kg | PRs: $prCount',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Date: $date'),
                            ),
                          ),
                        );
                      }
                    },
                  );
                }).toList());

                return Expanded(
                  child: ListView(
                    shrinkWrap: true, // To avoid rendering overflow
                    children: listItems,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper method to build today's panel
  Widget _buildTodayPanel(String today, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailsUpdatePage(date: today),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(
            'Lift: -- , PR: --',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Date: $today'),
        ),
      ),
    );
  }
}
