import 'dart:convert';

import 'package:chunaw/app/models/followers_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:chunaw/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'collection_name.dart';

class UserService {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static Future<bool> createAccount({required UserModel userData}) async {
    try {
      loadingcontroller.updateLoading(true);
      await FirebaseFirestore.instance
          .collection(USER_DB)
          .doc(userData.id)
          .set({
        'id': userData.id,
        'name': userData.name,
        'username': userData.username,
        'userdesc': userData.userdesc,
        'postal': userData.postal.toJson(),
        'image': userData.image,
        'affiliate_image': userData.affiliateImage,
        'affiliate_text': userData.affiliateText,
        "is_organization": userData.isOrganization,
        "organization_address": userData.organizationAddress,
        'city': userData.city.toJson(),
        'state': userData.state.toJson(),
        'country': userData.country.toJson(),
        "level": 1,
        "vote_count": 0,
        "oneday_vote": 0,
        "todays_upvote": 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch.toString(),
        'fcm': "",
      });
      await setUserValues();
      loadingcontroller.updateLoading(false);
      AppRoutes.navigateOffHomeTabScreen();
      return true;
    } catch (e) {
      print(e);
      loadingcontroller.updateLoading(false);
      // longToastMessage("Try again");
      longToastMessage(e.toString());
      return false;
    }
  }

  static Future<bool> updateUser({required UserModel userData}) async {
    try {
      loadingcontroller.updateLoading(true);
      await FirebaseFirestore.instance
          .collection(USER_DB)
          .doc(userData.id)
          .update({
        'name': userData.name,
        'username': userData.username,
        'userdesc': userData.userdesc,
        'postal': userData.postal.toJson(),
        'image': userData.image,
        'affiliate_image': userData.affiliateImage,
        'city': userData.city.toJson(),
        'state': userData.state.toJson(),
        'country': userData.country.toJson(),
        'affiliate_text': userData.affiliateText,
        'is_organization': userData.isOrganization,
        'organization_address': userData.organizationAddress,
      });
      await setUserValues();
      loadingcontroller.updateLoading(false);
      AppRoutes.navigateOffHomeTabScreen();
      return true;
    } catch (e) {
      print(e);
      loadingcontroller.updateLoading(false);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> updateUserWithGivenFields({
    required String userId,
    required Map<Object, Object> data,
    bool navigateToHomeAfterUpdate = true,
  }) async {
    try {
      loadingcontroller.updateLoading(true);
      await FirebaseFirestore.instance
          .collection(USER_DB)
          .doc(userId)
          .update(data);
      await setUserValues();
      loadingcontroller.updateLoading(false);
      if (navigateToHomeAfterUpdate) {
        AppRoutes.navigateOffHomeTabScreen();
      }
      return true;
    } catch (e) {
      print(e);
      loadingcontroller.updateLoading(false);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<void> updateFcm(
      {required String userId, required String fcm}) async {
    try {
      // loadingcontroller.updateLoading(true);
      await FirebaseFirestore.instance.collection(USER_DB).doc(userId).update({
        'fcm': fcm,
      });
    } catch (e) {
      print(e);
    }
  }

  static setUserValues() async {
    UserModel? user =
        await UserService.getUserData(FirebaseAuth.instance.currentUser!.uid);
    if (user != null) {
      await setPrefValue(Keys.NAME, user.name);
      await setPrefValue(Keys.PHONE, user.phone);
      await setPrefValue(Keys.USERNAME, user.username);
      await setPrefValue(Keys.USERID, user.id);
      await setPrefValue(Keys.PROFILE_PHOTO, user.image);
      await setPrefValue(Keys.AFFILIATE_PHOTO, user.affiliateImage);
      await setPrefValue(Keys.AFFILIATE_TEXT, user.affiliateText);
      await setPrefValue(Keys.ADMIN, user.admin.toString());
      await setPrefValue(Keys.USER_DESC, user.userdesc);
      await setPrefValue(Keys.STATE, jsonEncode(user.state.toJson()));
      await setPrefValue(Keys.CITY, jsonEncode(user.city.toJson()));
      await setPrefValue(Keys.PREFERRED_ELECTION_LOCATION,
          jsonEncode(user.preferredElectionLocation.toJson()));
      await setPrefValue(Keys.COUNTRY, jsonEncode(user.country.toJson()));
      await setPrefValue(Keys.POSTAL, jsonEncode(user.postal.toJson()));
      await setPrefValue(Keys.LEVEL, user.level.toString());
      await setPrefValue(Keys.IS_ORGANIZATION, user.isOrganization.toString());
      await setPrefValue(Keys.ORGANIZATION_ADDRESS, user.organizationAddress);
      await setPrefValue(Keys.UPVOTE_COUNT, user.upvoteCount.toString());
      await Pref.setBool(Keys.IS_GUEST_LOGIN, false);
    }
  }

  static Future<bool> userExists(userId) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(USER_DB)
        .where('id', isEqualTo: userId)
        .get();
    final List<DocumentSnapshot<Object?>> documents = result.docs;
    if (documents.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  static Future<UserModel?> getUserData(userId) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(USER_DB)
        .where('id', isEqualTo: userId)
        .get();
    final List<DocumentSnapshot<Object?>> documents = result.docs;
    if (documents.isNotEmpty) {
      return UserModel.fromJson(documents[0].data() as Map<String, dynamic>);
    } else {
      return null;
    }
  }

  static Future<bool> addFollowers(
      {required FollowerModel followerModel}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(USER_DB)
          .doc(followerModel.followeeId)
          .collection(FOLLOWERS_DB)
          .add(followerModel.toJson());
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> deleteFollowers(
      {required String userId, required String followId}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(USER_DB)
          .doc(userId)
          .collection(FOLLOWERS_DB)
          .doc(followId)
          .delete();
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static getHighestUpvotedUser(String locationText, int level) async {
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
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(USER_DB)
          .where(locQuery, isEqualTo: locationText)
          .where("level", isEqualTo: level)
          .orderBy("upvote_count", descending: true)
          .limit(1)
          .get();
      print("loc query: $locQuery, level: $level, locationText: $locationText");
      if (snapshot.docs.isNotEmpty) {
        final highestUpvotedPost = snapshot.docs.first.data();
        print('Highest Upvoted Post: $highestUpvotedPost');

        return UserModel.fromJson(highestUpvotedPost as Map<String, dynamic>);
      } else {
        print('No posts found');
        return UserModel.empty();
      }
    } catch (e) {
      print(e);
      return UserModel.empty();
    }
  }
}
