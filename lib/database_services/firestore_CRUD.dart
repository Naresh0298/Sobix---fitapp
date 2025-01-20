import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get userId => _auth.currentUser?.uid;

  // Helper to get the reference to a specific date's exercise log subcollection
  CollectionReference getNotesForExerciseLog(String date) {
    _checkUserLoggedIn();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(date)
        .collection('exercise-log');
  }

  // Helper to get the reference to a specific date's total-lift-log subcollection
  CollectionReference getNotesForTotalLiftLog(String date) {
    _checkUserLoggedIn();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('entries')
        .doc(date)
        .collection('total-lift-log');
  }

  // Helper to get the reference to the daily progress collection
  CollectionReference getDailyProgress() {
    _checkUserLoggedIn();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('daily-progress');
  }

  // Helper to get the reference to the active-dates collection
  CollectionReference getActiveDates() {
    _checkUserLoggedIn();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('active-dates');
  }

  // Helper method to check if the user is logged in
  void _checkUserLoggedIn() {
    if (userId == null) {
      throw Exception("User not logged in");
    }
  }

  // Helper method to calculate total lift for an exercise
  double updateTotalLift(int sets, int reps, double weight) {
    return (weight * reps) * sets;
  }

  // CREATE: Add a new exercise log, update the total lift for the day (past or present), and update active dates
  Future<void> addExerciseLog(String date, String exerciseName, int sets,
      int reps, double weight) async {
    _checkUserLoggedIn();

    // Get references to the collections
    var notesExercise = getNotesForExerciseLog(date);
    var notesTotalLift = getNotesForTotalLiftLog(date);
    var activeDatesRef = getActiveDates();

    // Add exercise log
    await notesExercise.add({
      'exercise-name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the active-dates collection to mark the date as active
    await activeDatesRef.doc(date).set({
      'date': date,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Recalculate total lift after the exercise is added
    await _updateTotalLift(date, notesTotalLift);
  }

  // Add or update daily progress log for the day
  Future<void> addDailyProgress(String date, double totalLift) async {
    _checkUserLoggedIn();

    var dailyProgressRef = getDailyProgress();

    var dailyProgressDoc =
        await dailyProgressRef.where('date', isEqualTo: date).limit(1).get();

    if (dailyProgressDoc.docs.isEmpty) {
      // If no entry exists, create a new one
      await dailyProgressRef.add({
        'total-lift': totalLift,
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // If an entry exists, update it
      await dailyProgressDoc.docs.first.reference.update({
        'total-lift': totalLift,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    print("Daily progress updated successfully.");
  }

  // Update total lift and daily progress after adding/updating exercise log
  Future<void> _updateTotalLift(
      String date, CollectionReference notesTotalLift) async {
    var exercises = await getNotesForExerciseLog(date).get();

    double totalLift = 0.0;
    for (var doc in exercises.docs) {
      totalLift += updateTotalLift(doc['sets'], doc['reps'], doc['weight']);
    }

    // Now update or add total lift to the daily-progress collection
    await addDailyProgress(date, totalLift);
  }

  // READ: Get notes for a specific date from exercise log
  Stream<QuerySnapshot> getNotesForDateStream(String date) {
    var notesRef = getNotesForExerciseLog(date);
    return notesRef.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get notes for a specific date from total-lift-log
  Stream<QuerySnapshot> getTotalLiftForDateStream(String date) {
    var notesRef = getNotesForTotalLiftLog(date);
    return notesRef.orderBy('timestamp', descending: true).snapshots();
  }

  // READ: Get daily progress for a specific date
  Stream<QuerySnapshot> getDailyProgressForDateStream(String date) {
    var notesRef = getDailyProgress();
    return notesRef.where('date', isEqualTo: date).snapshots();
  }

  // READ: Get all daily progress data for graphing (returns all data)
  Stream<List<Map<String, dynamic>>> getAllDailyProgress() {
    _checkUserLoggedIn();
    return getDailyProgress().orderBy('date').snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'date': data['date'],
          'total-lift': data['total-lift'] ?? 0,
        };
      }).toList();
    });
  }

  // UPDATE: Update a note by its ID for a specific date
  Future<void> updateExerciseLog(String date, String docID, String exerciseName,
      int new_sets, int new_reps, double new_weight) async {
    _checkUserLoggedIn();

    var notesExercise = getNotesForExerciseLog(date);
    var notesTotalLift = getNotesForTotalLiftLog(date);

    await notesExercise.doc(docID).update({
      'exercise-name': exerciseName,
      'sets': new_sets,
      'reps': new_reps,
      'weight': new_weight,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Recalculate total lift after the exercise is updated
    await _updateTotalLift(date, notesTotalLift);
  }

  // DELETE: Delete a note by its ID for a specific date
  Future<void> deleteExerciseLog(String date, String docID) async {
    _checkUserLoggedIn();

    final notesRef = getNotesForExerciseLog(date);
    final notesLiftRef = getNotesForTotalLiftLog(date);

    try {
      await notesRef.doc(docID).delete();
      await _updateTotalLift(date, notesLiftRef);
      print("Successfully deleted the note and updated total lift for $date.");
    } catch (e) {
      print("Error deleting note: $e");
    }
  }
}
