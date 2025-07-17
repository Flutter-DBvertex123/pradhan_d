import 'dart:developer';

import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PradhanService {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  static Future<bool> addCommentPradhanLocation(
      {required CommentModel commentModel}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(PRADHAN_DB)
          .doc(commentModel.postId)
          .collection(COMMENT_DB)
          .add(commentModel.toJson());
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<void> addImpDetailInPradhan(
      {required String docId,
      required String locationName,
      required String locationText,
      required int level}) async {
    try {
      // Reference to the Firestore document
      print(locationText);
      DocumentReference documentRef =
          FirebaseFirestore.instance.collection(PRADHAN_DB).doc(docId);

      // Get the document snapshot
      DocumentSnapshot docSnapshot = await documentRef.get();

      // Check if the document exists
      if (docSnapshot.exists) {
        // Get the data map from the snapshot
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        // Check if locationText is available, if not, set it
        if (data['locationText'] == null || data['locationText'].isEmpty) {
          await documentRef.update({'locationText': locationText});
        }

        // Check if voting is available, if not, set it
        if (data['voting'] == null) {
          await documentRef.update({'voting': false});
        }
        if (data['pradhan_status'] == null) {
          await documentRef.update({'pradhan_status': ""});
        }
        if (data['pinned_post'] == null) {
          await documentRef.update({'pinned_post': ""});
        }
        if (data['pradhan_id'] == null) {
          UserModel pradhanId =
              await UserService.getHighestUpvotedUser(locationText, level);
          log(pradhanId.toJson().toString());
          await documentRef.update({
            'pradhan_id': pradhanId.id,
            "pradhan_model": pradhanId.toSpecialJson(),
            'level': level,
          });
        }
      } else {
        UserModel pradhanId =
            await UserService.getHighestUpvotedUser(locationText, level);
        log(pradhanId.toJson().toString());
        FirebaseFirestore.instance.collection(PRADHAN_DB).doc(docId).set({
          'locationText': locationText,
          'pradhan_status': "",
          'voting': false,
          'level': level,
          'pradhan_id': pradhanId.id,
          "pradhan_model": pradhanId.toSpecialJson()
        });
      }
    } catch (error) {
      // Handle errors
      print('Error updating location and voting: $error');
    }
  }

  static Future<bool> getVoting({required String docId}) async {
    try {
      // Reference to the Firestore document
      DocumentReference documentRef =
          FirebaseFirestore.instance.collection(PRADHAN_DB).doc(docId);

      // Get the document snapshot
      DocumentSnapshot docSnapshot = await documentRef.get();

      // Check if the document exists
      if (docSnapshot.exists) {
        // Get the data map from the snapshot
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        // Check if voting is available, if not, set it
        if (data['voting'] != null) {
          return data['voting'];
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (error) {
      // Handle errors
      print('Error getting voting: $error');
      return false;
    }
  }

  static Future<PradhanData> fetchPradhanData({required String docId}) async {
    try {
      DocumentSnapshot pradhanSnapshot = await FirebaseFirestore.instance
          .collection(PRADHAN_DB)
          .doc(docId)
          .get();

      if (pradhanSnapshot.exists) {
        // Get the data map from the snapshot
        Map<String, dynamic> data =
            pradhanSnapshot.data() as Map<String, dynamic>;

        String pradhanId = data['pradhan_id'] ?? "";
        String pradhanStatus = data['pradhan_status'] ?? "";
        String pinnedPost = data['pinned_post'] ?? "";
        UserModel pradhanModel = UserModel.specialModel(
            data['pradhan_model'] as Map<String, dynamic>);

        return PradhanData(
            pradhanId: pradhanId,
            pradhanStatus: pradhanStatus,
            pradhanModel: pradhanModel,
            pinnedPost: pinnedPost);
      } else {
        return PradhanData(
          pradhanId: "",
          pinnedPost: "",
          pradhanStatus: "",
          pradhanModel: UserModel.empty(),
        );
      }
    } catch (error) {
      print('Error fetching pradhan data: $error');
      return PradhanData(
        pradhanId: "",
        pinnedPost: "",
        pradhanStatus: "",
        pradhanModel: UserModel.empty(),
      );
    }
  }

  static Future<void> setPradhanStatus(
      {required String docId, required String pradhanStatus}) async {
    try {
      await FirebaseFirestore.instance
          .collection(PRADHAN_DB)
          .doc(docId)
          .update({'pradhan_status': pradhanStatus});
      print('Pradhan status updated successfully');
    } catch (error) {
      print('Error updating pradhan status: $error');
    }
  }

  static Future<void> setPinnedPost(
      {required String docId, required String pinnedPost}) async {
    try {
      await FirebaseFirestore.instance
          .collection(PRADHAN_DB)
          .doc(docId)
          .update({'pinned_post': pinnedPost});
      print('Pradhan pinned post updated successfully');
    } catch (error) {
      print('Error updating pinned post: $error');
    }
  }

  // static Future<String> fetchPradhanId({required String docId}) async {
  //   try {
  //     DocumentSnapshot pradhanSnapshot = await FirebaseFirestore.instance
  //         .collection(PRADHAN_DB)
  //         .doc(docId)
  //         .get();

  //     if (pradhanSnapshot.exists) {
  //       // Get the data map from the snapshot
  //       Map<String, dynamic> data =
  //           pradhanSnapshot.data() as Map<String, dynamic>;

  //       // Check if Pradhan available
  //       if (data['pradhan_id'] != null || data['pradhan_id'] != "") {
  //         return data['pradhan_id'];
  //       } else {
  //         return "";
  //       }
  //     } else {
  //       return "";
  //     }
  //   } catch (error) {
  //     print('Error fetching pradhan ID: $error');
  //     return "";
  //   }
  // }

  // static Future<String> fetchPradhanStatus({required String docId}) async {
  //   try {
  //     DocumentSnapshot pradhanSnapshot = await FirebaseFirestore.instance
  //         .collection(PRADHAN_DB)
  //         .doc(docId)
  //         .get();

  //     if (pradhanSnapshot.exists) {
  //       // Get the data map from the snapshot
  //       Map<String, dynamic> data =
  //           pradhanSnapshot.data() as Map<String, dynamic>;

  //       // Check if Pradhan available
  //       if (data['pradhan_status'] != null || data['pradhan_status'] != "") {
  //         return data['pradhan_status'];
  //       } else {
  //         return "";
  //       }
  //     } else {
  //       return "";
  //     }
  //   } catch (error) {
  //     print('Error fetching pradhan status: $error');
  //     return "";
  //   }
  // }

  // static Future<UserModel> fetchPradhanModel({required String docId}) async {
  //   try {
  //     DocumentSnapshot pradhanSnapshot = await FirebaseFirestore.instance
  //         .collection(PRADHAN_DB)
  //         .doc(docId)
  //         .get();

  //     if (pradhanSnapshot.exists) {
  //       // Get the data map from the snapshot
  //       Map<String, dynamic> data =
  //           pradhanSnapshot.data() as Map<String, dynamic>;

  //       // Check if Pradhan available
  //       if (data['pradhan_model'] != null || data['pradhan_model'] != "") {
  //         return UserModel.specialModel(
  //             data['pradhan_model'] as Map<String, dynamic>);
  //       } else {
  //         return UserModel.empty();
  //       }
  //     } else {
  //       return UserModel.empty();
  //     }
  //   } catch (error) {
  //     print('Error fetching pradhan model: $error');
  //     return UserModel.empty();
  //   }
  // }
}

class PradhanData {
  final String pradhanId;
  final String pradhanStatus;
  final String pinnedPost;
  final UserModel pradhanModel;

  PradhanData({
    required this.pradhanId,
    required this.pinnedPost,
    required this.pradhanStatus,
    required this.pradhanModel,
  });
}
