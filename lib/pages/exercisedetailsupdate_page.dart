import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitapp/database_services/firestore_CRUD.dart';
import 'package:flutter/material.dart';

class ExerciseDetailsUpdatePage extends StatefulWidget {
  final int day;

  const ExerciseDetailsUpdatePage({super.key, required this.day});

  @override
  State<ExerciseDetailsUpdatePage> createState() =>
      _ExerciseDetailsUpdatePageState();
}

class _ExerciseDetailsUpdatePageState extends State<ExerciseDetailsUpdatePage> {
  final TextEditingController textEditingController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  //open a dailog box to add a note
  void openNoteBox({String? docID}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: TextField(
                controller: textEditingController,
              ),
              actions: [
                //button to save
                ElevatedButton(
                    onPressed: () {
                      if (docID == null) {
                        firestoreService.addNote(textEditingController.text);
                      } else {
                        firestoreService.UpdateNote(
                            docID, textEditingController.text);
                      }

                      //clear text controller
                      textEditingController.clear();
                      Navigator.pop(context);
                    },
                    child: Text('Add'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Day ${widget.day}")),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNoteStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;

            return ListView.builder(
                itemCount: notesList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = notesList[index];

                  String docID = document.id;

                  //get note from each doc
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  String noteText = data['Ex-name'];

                  return ListTile(
                    title: Text(noteText),
                    trailing: SizedBox(
                      width: 100, // Limit the width of the trailing widget
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end, // Align buttons to the end
                        children: [
                          // Update button
                          IconButton(
                            onPressed: () {
                              openNoteBox(docID: docID);
                            },
                            icon: const Icon(Icons.settings),
                          ),

                          // Delete button
                          IconButton(
                            onPressed: () {
                              firestoreService.DeleteNote(docID);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  );
                });
          } else {
            return Text("Note notes..");
          }
        },
      ),
    );
  }
}
