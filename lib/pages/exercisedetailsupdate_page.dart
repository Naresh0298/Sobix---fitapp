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

// Open a dialog box to add or update a note
  void openNoteBox(
      {String? docID,
      String? currentExerciseName,
      int? currentSets,
      int? currentReps,
      double? currentWeight}) {
    textEditingController.text = currentExerciseName ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textEditingController,
              decoration: InputDecoration(hintText: "Exercise Name"),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Sets"),
              onChanged: (value) {
                currentSets = int.tryParse(value);
              },
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Reps"),
              onChanged: (value) {
                currentReps = int.tryParse(value);
              },
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Weight (kg)"),
              onChanged: (value) {
                currentWeight = double.tryParse(value);
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (docID == null) {
                // Add new note for the day
                firestoreService.addExerciseLog(
                  widget.date,
                  textEditingController.text,
                  currentSets ?? 0,
                  currentReps ?? 0,
                  currentWeight ?? 0.0,
                );
              } else {
                // Update existing note
                firestoreService.updateExerciseLog(
                  widget.date,
                  docID,
                  textEditingController.text,
                  currentSets ?? 0,
                  currentReps ?? 0,
                  currentWeight ?? 0.0,
                );
              }

              // Clear the text controller and close the dialog
              textEditingController.clear();
              Navigator.pop(context);
            },
            child: Text(docID == null ? 'Add' : 'Update'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Day ${widget.date}")),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
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
                int sets = data['sets'] ?? 0;
                int reps = data['reps'] ?? 0;
                double weight = data['weight'] ?? 0.0;

                return ListTile(
                  title: Text(exerciseName),
                  subtitle:
                      Text('Sets: $sets, Reps: $reps, Weight: $weight kg'),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            openNoteBox(
                              docID: docID,
                              currentExerciseName: exerciseName,
                              currentSets: sets,
                              currentReps: reps,
                              currentWeight: weight,
                            );
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
                );
              },
            );
          } else {
            return Center(child: Text("No exercise logs available."));
          }
        },
      ),
    );
  }
}
