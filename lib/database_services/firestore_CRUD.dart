import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirestoreService {
//get user uid from firebase

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get userId => _auth.currentUser?.uid;

//get collection of notes
  // Reference to the user's notes collection
  CollectionReference get notes {
    if (userId == null) {
      throw Exception("User not logged in");
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notes');
  }

//CREATE : add a new data (note)
  Future<void> addNote(String note) {
    return notes.add({
      'Ex-name': note,
      'timestamp': Timestamp.now(),
    });
  }

//READ : get data from DB

  Stream<QuerySnapshot> getNoteStream() {
    final noteStream = notes.orderBy('timestamp', descending: true).snapshots();

    return noteStream;
  }

//UPDATE : update data given a doc id

  Future<void> UpdateNote(String docID, String newNote) {
    return notes.doc(docID).update({
      'Ex-name': newNote,
      'timestamp': Timestamp.now(),
    });
  }

//DELETE : delete notes given a doc id

  Future<void> DeleteNote(String docID) {
    return notes.doc(docID).delete();
  }
}
