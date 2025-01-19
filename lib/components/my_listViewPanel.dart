import 'package:fitapp/pages/exercisedetailsupdate_page.dart';
import 'package:flutter/material.dart';

class MyListViewPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;

  const MyListViewPanel(
      {super.key,
      required this.count,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.builder(
        itemCount: count,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              //Navigate to Add Exercise Details Page
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExerciseDetailsUpdatePage(day: index + 1),
                  ));
            },
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text("${title} ${index + 1}"),
                subtitle: Text(subtitle),
              ),
            ),
          );
        },
      ),
    );
  }
}
