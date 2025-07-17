import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/like_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static Future<bool> createPost({required PostModel postModel}) async {
    try {
      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(postModel.postId)
          .set(postModel.toJson());
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> updatePost({required PostModel postModel}) async {
    try {
      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(postModel.postId)
          .update(
            postModel.toJson(
              removeCreatedAt: true,
            ),
          );
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<PostModel?> getPost(postId) async {
    final DocumentSnapshot<Map<String, dynamic>> result =
        await FirebaseFirestore.instance.collection(POST_DB).doc(postId).get();
    print("postId $postId");
    print("postId exists: ${result.exists} ${result.data()}");
    if (result.exists) {
      return PostModel.fromJson(result.data()!);
    } else {
      return null;
    }
  }

  static Future<bool> updatePostShowLevel(
      {required PostModel postModel, required int level}) async {
    try {
      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(postModel.postId)
          .update({
        "show_level": FieldValue.arrayUnion([level])
      });
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> addCommentPost(
      {required CommentModel commentModel}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(POST_DB)
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

  static Future<bool> addSpecialComment(
      {required CommentModel commentModel}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(commentModel.postId)
          .update({
        "special_comment": commentModel.toJson(),
      });
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> deleteCommentPost(
      {required String postid, required String commentId}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(postid)
          .collection(COMMENT_DB)
          .doc(commentId)
          .delete();
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  // method to delete a post
  static Future<bool> deletePost(PostModel postModel) async {
    try {
      // deleting the post media as well
      if (postModel.postVideo.isNotEmpty) {
        await FirebaseStorage.instance
            .ref(POST_DB)
            .child(postModel.postId)
            .delete();
      } else {
        // if a post image is there, delete that
        if (postModel.postImage != null && postModel.postImage!.isNotEmpty) {
          await FirebaseStorage.instance
              .ref(POST_DB)
              .child(postModel.postId)
              .delete();
        } else {
          // deleting the images
          final imagesCount = postModel.postImages.length;

          for (int i = 0; i < imagesCount; i++) {
            await FirebaseStorage.instance
                .ref(POST_DB)
                .child('${postModel.postId}-$i')
                .delete();
          }
        }
      }

      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(postModel.postId)
          .delete();
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Couldn't delete the post. Please try again later");
      return false;
    }
  }

  static Future<bool> likePost({required UpLikeModel likeModel}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(likeModel.postId)
          .collection(LIKE_DB)
          .add(likeModel.toJson());
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> unlikePost(
      {required String postid, required String likeId}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(postid)
          .collection(LIKE_DB)
          .doc(likeId)
          .delete();
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> upvotePost(
      {required UpLikeModel upvoteModel, required String postingUser}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).
      await Future.wait([
        FirebaseFirestore.instance
            .collection(POST_DB)
            .doc(upvoteModel.postId)
            .collection(UPVOTE_DB)
            .add(upvoteModel.toJson()),
        FirebaseFirestore.instance
            .collection(POST_DB)
            .doc(upvoteModel.postId)
            .update({
          "upvote_count": FieldValue.increment(1),
        }),
      ]);
      updateUserUpvoteForToday(upvoteModel.userId);
      updateUserLevel(
          postingUser: postingUser,
          upvoteModel: upvoteModel,
          postId: upvoteModel.postId);
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static updateUserUpvoteForToday(String userId) {
    try {
      FirebaseFirestore.instance.collection(USER_DB).doc(userId).update({
        "todays_upvote": FieldValue.increment(1),
      });
    } catch (e) {
      FirebaseFirestore.instance.collection(USER_DB).doc(userId).update({
        "todays_upvote": 0,
      });
    }
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

  static Future<bool> upvotePostLevel(
      {required UpLikeModel upvoteModel,
      required String postingUser,
      required int inc}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).
      for (var i = 0; i < inc; i++) {
        await Future.wait([
          FirebaseFirestore.instance
              .collection(POST_DB)
              .doc(upvoteModel.postId)
              .collection(UPVOTE_DB)
              .add(upvoteModel.toJson()),
          FirebaseFirestore.instance
              .collection(POST_DB)
              .doc(upvoteModel.postId)
              .update({
            "upvote_count": FieldValue.increment(1),
          }),
        ]);
      }
      updateUserLevel(
          postingUser: postingUser,
          upvoteModel: upvoteModel,
          postId: upvoteModel.postId);
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> unupvotePost(
      {required String postid, required String upvoteId}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await Future.wait([
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
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static updateUserLevel(
      {required UpLikeModel upvoteModel,
      required String postingUser,
      required String postId}) async {
    var response = await FirebaseFirestore.instance
        .collection(POST_DB)
        .doc(upvoteModel.postId)
        .collection(UPVOTE_DB)
        .get();
    print("upvote count ${response.docs.length}");
    if (response.docs.length > 9) {
      print("Condition 10");
      levelChange(level: 4, postingUser: postingUser, postId: postId);
    } else if (response.docs.length > 4) {
      print("Condition 5");
      levelChange(level: 3, postingUser: postingUser, postId: postId);
    } else if (response.docs.length > 1) {
      print("Condition 2");
      levelChange(level: 2, postingUser: postingUser, postId: postId);
    } else {
      print("Condition else");
    }
  }

  static levelChange(
      {required int level,
      required String postingUser,
      required String postId}) {
    UserService.getUserData(postingUser).then((value) {
      print("Current Level ${value!.level}");
      if (value.level < level) {
        print("Update Level $level");
        FirebaseFirestore.instance.collection(POST_DB).doc(postId).update({
          "show_level": FieldValue.arrayUnion([level]),
        });
      } else {
        print("Not updating ");
      }
    });
  }

  // Future<UserModel> getHighestUpvotedPost(String location) async {
  //   try {
  //     final QuerySnapshot snapshot = await FirebaseFirestore.instance
  //         .collection(POST_DB)
  //         .where("location", isEqualTo: location)
  //         .orderBy("upvote_count", descending: true)
  //         .limit(1)
  //         .get();

  // if (snapshot.docs.isNotEmpty) {
  //   final highestUpvotedPost = snapshot.docs.first.data();
  //   print('Highest Upvoted Post: $highestUpvotedPost');
  //   UserModel? model =
  //       await UserService.getUserData(snapshot.docs.first.get("user_id"));

  //   return model!;
  // } else {
  //   print('No posts found');
  //   return UserModel.empty();
  // }
  // } catch (e) {
  //   print(e);
  //   return UserModel.empty();
  // }
  // }
}
