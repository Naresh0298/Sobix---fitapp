import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitapp/components/my_listViewPanel.dart';
import 'package:fitapp/components/my_panel.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DashBoard'),
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .start, //to algin "Your progress "  text to left side of the screen
            children: [
              //Header Section
              Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              //progress Panel

              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyPanel(title: 'PG%', value: "60", color: Colors.green),
                  MyPanel(title: 'Wieght', value: "74kg", color: Colors.blue),
                  MyPanel(title: 'PR', value: "2", color: Colors.red)
                ],
              ),

              SizedBox(
                height: 25,
              ),
              //Graph Section

              Expanded(
                child: Container(
                  color: Colors.blue.shade200,
                  child: Center(
                    child: Text(
                      'Graph placeholder',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: 25,
              ),

              //Workout Details panel

              Expanded(
                  child: MyListViewPanel(
                count: 7,
                title: "Day",
                subtitle: "date",
              )),
            ],
          ),
        ),
      )),
    );
  }
}
