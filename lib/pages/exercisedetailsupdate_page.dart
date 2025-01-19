import 'package:flutter/material.dart';

class ExerciseDetailsUpdatePage extends StatelessWidget {
  final int day;

  const ExerciseDetailsUpdatePage({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Day $day")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
