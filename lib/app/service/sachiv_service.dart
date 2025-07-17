import 'dart:developer';

import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SachivService {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static Future<UserModel> fetchSachivId({required String docId}) async {
    try {
      DocumentSnapshot sachivSnapshot = await FirebaseFirestore.instance
          .collection(SACHIV_DB)
          .doc(docId)
          .get();
      log("Doc id $docId");
      if (sachivSnapshot.exists) {
        // Get the data map from the snapshot
        Map<String, dynamic> data =
            sachivSnapshot.data() as Map<String, dynamic>;

        // Check if Pradhan available
        if (data['sachiv_model'] != null && data['sachiv_id'] != "") {
          return UserModel.specialModel(data['sachiv_model']);
        } else {
          return UserModel.empty();
        }
      } else {
        return UserModel.empty();
      }
    } catch (error) {
      print('Error fetching Sachiv IDs and doc IDs: $error');
      return UserModel.empty();
    }
  }

  static Future<void> addImpDetailInSachiv(
      {required String docId,
      required String locationName,
      required int level}) async {
    try {
      // Reference to the Firestore document
      DocumentReference documentRef =
          FirebaseFirestore.instance.collection(SACHIV_DB).doc(docId);

      // Get the document snapshot
      DocumentSnapshot docSnapshot = await documentRef.get();
      // Check if the document exists
      if (docSnapshot.exists) {
        // Get the data map from the snapshot
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        // Check if locationText is available, if not, set it
        if (data['locationText'] == null || data['locationText'].isEmpty) {
          await documentRef.update({'locationText': locationName});
          await documentRef.update({'level': level});
        }

        // Check if voting is available, if not, set it
        if (data['sachiv_Id'] == null) {
          UserModel sachivID =
              await UserService.getHighestUpvotedUser(locationName, level);
          await documentRef.update({"sachiv_Id": sachivID.id});
          await documentRef.update({"sachiv_model": sachivID.toSpecialJson()});
        }
      } else {
        UserModel sachivID =
            await UserService.getHighestUpvotedUser(locationName, level);
        FirebaseFirestore.instance.collection(SACHIV_DB).doc(docId).set({
          'locationText': locationName,
          'level': level,
          'sachiv_Id': sachivID.id,
          "sachiv_model": sachivID.toSpecialJson()
        });
      }
    } catch (error) {
      // Handle errors
      print('Error updating location and voting: $error');
    }
  }
}
