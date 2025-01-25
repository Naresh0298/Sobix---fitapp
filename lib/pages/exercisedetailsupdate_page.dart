import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitapp/database_services/firestore_CRUD.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExerciseDetailsUpdatePage extends StatefulWidget {
  final String date;

  const ExerciseDetailsUpdatePage({super.key, required this.date});

  @override
  State<ExerciseDetailsUpdatePage> createState() =>
      _ExerciseDetailsUpdatePageState();
}

class _ExerciseDetailsUpdatePageState extends State<ExerciseDetailsUpdatePage> {
  final TextEditingController textEditingController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  final TextEditingController exerciseNameController = TextEditingController();

  //to Store weight and reps for each set
  int numberOfSets = 1;
  List<Map<String, dynamic>> setsDetails = [];

// Open a dialog box to add or update a note
  void openAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: exerciseNameController,
              decoration: const InputDecoration(hintText: "Exercise Name"),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Number of Sets"),
              onChanged: (value) {
                numberOfSets = int.tryParse(value) ?? numberOfSets;
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () {
                setsDetails = List.generate(
                  numberOfSets,
                  (_) => {"weight": 0.0, 'reps': 0},
                );
                Navigator.pop(context);
                openSetDetailsDialog();
              },
              child: const Text("Next")),
        ],
      ),
    );
  }

  void openSetDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Details for ${exerciseNameController.text}"),
        content: SizedBox(
          height: 300, // Set a fixed height for the dialog content
          width: double.maxFinite, // Allow the dialog to expand horizontally
          child: ListView.builder(
            itemCount: numberOfSets,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Text("Set ${index + 1}"),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Weight (kg)"),
                    onChanged: (value) {
                      setsDetails[index]["weight"] =
                          double.tryParse(value) ?? 0.0;
                    },
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Reps"),
                    onChanged: (value) {
                      setsDetails[index]["reps"] = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 10), // Add spacing between inputs
                ],
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              firestoreService.addExerciseLog(
                widget.date,
                exerciseNameController.text,
                setsDetails,
              );
              exerciseNameController.clear();
              setsDetails.clear();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Day ${widget.date}")),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddExerciseDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotesForDateStream(widget.date),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = notesList[index];

                String docID = document.id;
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;

                // Extract exercise log data
                String exerciseName =
                    data['exercise-name'] ?? 'No exercise name';
                List<dynamic> setsDetails = data['sets'] ?? [];

                return Card(
                  child: ListTile(
                    title: Text(exerciseName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          setsDetails.asMap().entries.map<Widget>((entry) {
                        int index = entry.key; // Correctly access the index
                        Map<String, dynamic> set = entry.value; // Set details
                        return Text(
                          'Set ${index + 1}: Weight ${set["weight"]} kg, Reps: ${set["reps"]}',
                        );
                      }).toList(),
                    ),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              // Add logic for editing the card
                            },
                            icon: const Icon(Icons.settings),
                          ),
                          IconButton(
                            onPressed: () {
                              firestoreService.deleteExerciseLog(
                                  widget.date, docID);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("No exercise logs available."));
          }
        },
      ),
    );
  }
}
