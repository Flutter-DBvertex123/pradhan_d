import 'dart:math';

import 'package:chunaw/app/models/like_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/v4.dart';

import 'collection_name.dart';

class VoteService {
  static Future<List<UserModel>> getHighestUpvotedUsers(
      String locationText, int level) async {
    String locQuery = "postal.text";
    switch (level) {
      case 1:
        locQuery = "postal.text";
        break;
      case 2:
        locQuery = "city.text";
        break;
      case 3:
        locQuery = "state.text";
        break;
      case 4:
        locQuery = "country.text";
        break;
      default:
        locQuery = "postal.text";
    } 

    try {
      // final QuerySnapshot snapshot = await FirebaseFirestore.instance
      //     .collection(USER_DB)
      //     .where(locQuery, isEqualTo: locationText)
      //     .where("level", isEqualTo: level)
      //     .orderBy("upvote_count", descending: true)
      //     .limit(10)
      //     .get();

      // grab users who prefer this location for fighting election
      // if the user doesn't prefer this location, then check whether the location and level matches or not
      final baseQuery = FirebaseFirestore.instance
          .collection(USER_DB)
          .where(
            Filter.or(
              Filter(
                'preferred_election_location.text',
                isEqualTo: locationText,
              ),
              Filter.and(
                Filter(locQuery, isEqualTo: locationText),
                Filter('level', isEqualTo: level),
              ),
            ),
          )
          .orderBy("upvote_count", descending: true);

      List<UserModel> users = [];

      // whether this is the first request or not
      bool isFirst = true;

      // variable to hold the response
      late QuerySnapshot response;

      // while the users are not equals 10
      while (users.length < 10) {
        // if is first request
        if (isFirst) {
          print('first request');
          // no longer first
          isFirst = false;

          // getting the response
          response = await baseQuery.limit(10).get();
        } else {
          print('follow up request');
          // if not the first query, request the next set of docs
          response = await baseQuery
              .startAfterDocument(response.docs.last)
              .limit(10)
              .get();
        }

        print('response.docs: ${response.docs}');
        print('response.docs.isNotEmpty: ${response.docs.isNotEmpty}');

        // if there are some docs, process them
        if (response.docs.isNotEmpty) {
          print('inside if statement');
          for (var element in response.docs) {
            final elementData = element.data() as Map;

            print('elementData: $elementData');
            print('elementData.runtimeType: ${elementData.runtimeType}');

            final containsKey =
                elementData.containsKey('preferred_election_location');

            // if key is not there, then the user doesn't have a preferred location and this is the default location, so add him
            // otherwise if the key is there and this is the preferred location of the user, add him
            if (!containsKey ||
                element['preferred_election_location']['text'] ==
                    locationText) {
              print('user added');
              users.add(
                  UserModel.fromJson(element.data() as Map<String, dynamic>));
            }
          }
        } else {
          // if no more docs, just break the loop
          break;
        }
      }

      // return only the first 10 results
      return users.sublist(0, min(users.length, 10));
    } catch (e) {
      print(e);
      return [];
    }
  }

  // static Stream<QuerySnapshot<Map<String, dynamic>>>
  //     getHighestUpvotedUsersSnapshot(String locationText, int level) {
  //   String locQuery = "postal.text";
  //   switch (level) {
  //     case 1:
  //       locQuery = "postal.text";
  //       break;
  //     case 2:
  //       locQuery = "city.text";
  //       break;
  //     case 3:
  //       locQuery = "state.text";
  //       break;
  //     case 4:
  //       locQuery = "country.text";
  //       break;
  //     default:
  //       locQuery = "postal.text";
  //   }
  //   // return FirebaseFirestore.instance
  //   //     .collection(USER_DB)
  //   //     .where(locQuery, isEqualTo: locationText)
  //   //     .where("level", isEqualTo: level)
  //   //     .orderBy("upvote_count", descending: true)
  //   //     .limit(10)
  //   //     .snapshots()
  //   //     .map((e) => e);
  //   return FirebaseFirestore.instance
  //       .collection(USER_DB)
  //       .where(
  //         Filter.or(
  //           Filter(
  //             'preferred_election_location.text',
  //             isEqualTo: locationText,
  //           ),
  //           Filter.and(
  //             Filter(locQuery, isEqualTo: locationText),
  //             Filter('level', isEqualTo: level),
  //           ),
  //         ),
  //       )
  //       .orderBy("upvote_count", descending: true)
  //       .snapshots();
  // }

  static updateUserUpvoteForToday(String userId, int incrementValue) async {
    try {
      await FirebaseFirestore.instance.collection(USER_DB).doc(userId).update({
        "todays_upvote": FieldValue.increment(incrementValue),
      });
    } catch (e) {
      await FirebaseFirestore.instance.collection(USER_DB).doc(userId).update({
        "todays_upvote": 0,
      });
    } finally {
      FirebaseFirestore.instance
          .collection(USER_DB)
          .doc(userId)
          .get()
          .then((value) {
        int vote = value.get("todays_upvote");
        Pref.setInt(Keys.TODAY_UPVOTE, vote);
        print(Pref.getInt(Keys.TODAY_UPVOTE));
      });
    }
  }

  static upvoteUser(
      {required UpLikeModel upvoteModel, required PostModel postModel}) async {
    try {
      final docId = UuidV4().generate();

      await Future.wait([
        FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(upvoteModel.postUserId)
            .collection(UPVOTE_DB)
            .doc(docId)
            .set(upvoteModel.toJson()),
        FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(upvoteModel.postUserId)
            .update({
          "upvote_count": FieldValue.increment(1),
          "oneday_vote": FieldValue.increment(1),
          "weekly_vote": FieldValue.increment(1)
        }),
        FirebaseFirestore.instance
            .collection(POST_DB)
            .doc(upvoteModel.postId)
            .collection(UPVOTE_DB)
            .doc(docId)
            .set(upvoteModel.toJson()),
        FirebaseFirestore.instance
            .collection(POST_DB)
            .doc(upvoteModel.postId)
            .update({
          "upvote_count": FieldValue.increment(1),
        }),
      ]);
      updateUserUpvoteForToday(upvoteModel.userId, 1);
      updatePostLevel(upvoteModel: upvoteModel, postModel: postModel);
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static pradhanVotingUpvote({required UpLikeModel upvoteModel}) async {
    try {
      await Future.wait([
        FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(upvoteModel.postUserId)
            .collection(UPVOTE_DB)
            .add(upvoteModel.toJson()),
        FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(upvoteModel.postUserId)
            .update({
          "upvote_count": FieldValue.increment(1),
          "weekly_vote": FieldValue.increment(1)
          // "oneday_vote": FieldValue.increment(1),
        }),
      ]);
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> unupvoteUser({
    required String postUserId,
    required String upvoteId,
    required String postid,
    required UpLikeModel upvoteModel,
    required PostModel postModel,
  }) async {
    print("ishwar:new: ${upvoteId}");
    try {
      await Future.wait([
        FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(postUserId)
            .collection(UPVOTE_DB)
            .doc(upvoteId)
            .delete(),
        FirebaseFirestore.instance.collection(USER_DB).doc(postUserId).update({
          "upvote_count": FieldValue.increment(-1),
          "oneday_vote": FieldValue.increment(-1),
          "weekly_vote": FieldValue.increment(-1),
        }),
        FirebaseFirestore.instance
            .collection(POST_DB)
            .doc(postid)
            .collection(UPVOTE_DB)
            .doc(upvoteId)
            .delete(),
        FirebaseFirestore.instance.collection(POST_DB).doc(postid).update({
          "upvote_count": FieldValue.increment(-1),
        })
      ]);
      print("unvote done");

      // updating user's today's upvotes
      updateUserUpvoteForToday(upvoteModel.userId, -1);

      // updating post level
      updatePostLevel(upvoteModel: upvoteModel, postModel: postModel);
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> unVotePradhan({
    required String userId,
    required String upvoteId,
  }) async {
    try {
      await Future.wait([
        FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(userId)
            .collection(UPVOTE_DB)
            .doc(upvoteId)
            .delete(),
        FirebaseFirestore.instance.collection(USER_DB).doc(userId).update({
          "upvote_count": FieldValue.increment(-1),
          "weekly_vote": FieldValue.increment(-1)
        }),
      ]);
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static updatePostLevel(
      {required UpLikeModel upvoteModel, required PostModel postModel}) async {
    var response = await FirebaseFirestore.instance
        .collection(USER_DB)
        .doc(upvoteModel.postUserId)
        .collection(UPVOTE_DB)
        .where('post_id', isEqualTo: postModel.postId)
        .get();
    print("upvote count ${response.docs.length}");
    if (response.docs.length > 20) {
      print("Condition 10");
      updatePostShowLevel(level: 4, postModel: postModel);
    } else if (response.docs.length > 10) {
      print("Condition 5");
      updatePostShowLevel(level: 3, postModel: postModel);
    } else if (response.docs.length > 5) {
      print("Condition 2");
      updatePostShowLevel(level: 2, postModel: postModel);
    } else {
      print("Condition else");
    }
  }

  static upgradePostLevel(
      {required UpLikeModel upvoteModel,
      required int level,
      required PostModel postModel,
      required bool isOrganization}) async {
    int inc = 0;
    switch (level) {
      case 1:
        inc = 2;
        break;
      case 2:
        inc = 5;
        break;
      case 3:
        inc = 7;
        break;
      case 4:
        longToastMessage("Post is on highest level");
        break;
      default:
        inc = 2;
    }
    for (int i = 0; i < inc; i++) {
      upvoteUser(upvoteModel: upvoteModel, postModel: postModel);
    }
  }

  static upgradePostLevelPradhan(
      {required UpLikeModel upvoteModel,
      required int level,
      required bool isOrganization,
      required PostModel postModel}) async {
    int inc = 0;
    switch (level) {
      case 1:
        inc = 5;
        break;
      case 2:
        inc = 10;
        break;
      case 3:
        inc = 20;
        break;
      case 4:
        longToastMessage("Post is on highest level");
        break;
      default:
        inc = 5;
    }
    for (int i = 0; i < inc; i++) {
      upvoteUser(upvoteModel: upvoteModel, postModel: postModel);
    }
  }

  static Future<bool> updatePostShowLevel(
      {required PostModel postModel, required int level}) async {
    try {
      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(postModel.postId)
          .update({
        "show_level": FieldValue.arrayUnion([level]),
        "level": level
      });
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }
}
