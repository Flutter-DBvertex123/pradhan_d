import 'dart:convert';

import 'package:chewie/chewie.dart';
import 'package:chunaw/app/controller/home/home_controller.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:video_player/video_player.dart';

class VideoScrollviewController extends GetxController {
  // whether we are loading the next set
  RxBool isLoadingNextSet = false.obs;

  // actual loaded posts
  RxList<PostModel> postModels = <PostModel>[].obs;

  // last loaded post model
  Rx<PostModel> lastPostModel = PostModel.empty().obs;

  // initial video's seconds played so far
  int secondsPlayedSoFar = 0;

  // home controller
  final homeController = Get.put(HomeController());

  // limit of how many posts to fetch at a time from the server
  final int limit = 10;

  // to add the initial post model in
  void addInitialPostModel(
    PostModel postModel,
    int secondsPlayedSoFar,
  ) {
    postModels.add(postModel);
    lastPostModel.value = postModel;
    this.secondsPlayedSoFar = secondsPlayedSoFar;
  }

  // to clear
  void clear() {
    isLoadingNextSet.value = false;
    postModels.clear();
    lastPostModel.value = PostModel.empty();
  }

  // to load the next set and add the post models in
  Future<void> loadNextSetInLevel({
    required int level,
  }) async {
    // if last post model is null, we don't have anything to load
    if (lastPostModel.value.postId.isEmpty) {
      return;
    }

    isLoadingNextSet(true);

    // selected postal, city, and state values
    final selectedPostal = homeController.selectedPostal.value;
    final selectedCity = homeController.selectedCity.value;
    final selectedState = homeController.selectedState.value;

    var res;

    // generating the base query
    late final Query baseQuery;

    switch (level) {
      case 0:
        // getting the selected states
        final List selectedStates = getPrefValue(Keys.PREFERRED_STATES).isEmpty
            ? []
            : jsonDecode(getPrefValue(Keys.PREFERRED_STATES));

        // grabbing the docs where the follower id matches the current user
        final docsWhereFollowerIdMatches = await FirebaseFirestore.instance
            .collectionGroup(FOLLOWERS_DB)
            .where(
              'follower_id',
              isEqualTo: getPrefValue(Keys.USERID),
            )
            .get();

        // list to store the user ids of users/organizations that we are following
        final List userIdsOfUsersWeAreFollowing = [];

        // going through each doc
        for (QueryDocumentSnapshot doc in docsWhereFollowerIdMatches.docs) {
          // grabbing the followee id
          final followeeId = (doc.data() as Map)['followee_id'];

          // grabbing the user id and adding that to the list
          userIdsOfUsersWeAreFollowing.add(followeeId);
        }

        print('we following: $userIdsOfUsersWeAreFollowing');

        baseQuery = FirebaseFirestore.instance.collection(POST_DB).where(
              userIdsOfUsersWeAreFollowing.isNotEmpty
                  ? Filter.and(
                      Filter.or(
                        Filter("full_add", arrayContainsAny: selectedStates),
                        Filter("user_id",
                            whereIn: userIdsOfUsersWeAreFollowing),
                      ),
                      Filter("post_video", isNotEqualTo: ""),
                    )
                  : Filter.and(
                      Filter("full_add", arrayContainsAny: selectedStates),
                      Filter("post_video", isNotEqualTo: ""),
                    ),
            );

        break;
      case 1:
        baseQuery = FirebaseFirestore.instance.collection(POST_DB).where(
              Filter.and(
                Filter("full_add", arrayContainsAny: [selectedPostal.name]),
                Filter("post_video", isNotEqualTo: ""),
              ),
            );

        break;
      case 2:
        baseQuery = FirebaseFirestore.instance.collection(POST_DB).where(
              Filter.and(
                Filter("full_add", arrayContainsAny: [selectedCity.name]),
                Filter("post_video", isNotEqualTo: ""),
              ),
            );
        break;
      case 3:
        baseQuery = FirebaseFirestore.instance.collection(POST_DB).where(
              Filter.and(
                Filter("full_add", arrayContainsAny: [selectedState.name]),
                Filter("post_video", isNotEqualTo: ""),
              ),
            );
        break;
      case 4:
        baseQuery = FirebaseFirestore.instance.collection(POST_DB).where(
              Filter.and(
                Filter("show_level", arrayContains: 4),
                Filter("post_video", isNotEqualTo: ""),
              ),
            );
        break;
      default:
    }

    // to hold the count of valid documents we found
    int validDocumentsCount = 0;

    // looping in
    while (validDocumentsCount < 5) {
      // otherwise, load the next set
      res = await baseQuery
          .where(
            'createdAt',
            isLessThan: lastPostModel.value.createdAt,
          )
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      // updating last post model
      lastPostModel.value = res.docs.isEmpty
          ? PostModel.empty()
          : PostModel.fromJson(res.docs.last.data());

      for (var element in res.docs) {
        // creating the post
        final post = PostModel.fromJson(element.data());

        print(post.showlevel);

        // if level is 0
        if (level == 0) {
          // valid documents are only the once where show_level doesn't contain level 1
          if (!post.showlevel.contains(1)) {
            postModels.add(post);
            validDocumentsCount++;
          }
        } else {
          // if current document can be shown on this level, it is a valid document
          if (post.showlevel.contains(level)) {
            postModels.add(post);
            validDocumentsCount++;
          }
        }
      }

      print("Post List: $postModels");

      // if there is no last doc, break
      if (lastPostModel.value.postId.isEmpty) {
        break;
      }
    }

    isLoadingNextSet(false);
  }

  // to load the next set of a person's profile
  Future<void> loadNextSetInProfile() async {
    // if last doc is empty, we ignore as we can't fetch any more
    if (lastPostModel.value.postId.isEmpty) {
      return;
    }

    // getting the user id of the user we want to load the videos of
    final userId = lastPostModel.value.userId;

    isLoadingNextSet(true);

    QuerySnapshot<Map<String, dynamic>> res;

    // creating the base query
    var baseQuery = FirebaseFirestore.instance
        .collection(POST_DB)
        .where(
          Filter.and(
            Filter("user_id", isEqualTo: userId),
            Filter("post_video", isNotEqualTo: ""),
          ),
        )
        .limit(limit);

    // executing query
    res = await baseQuery
        .where('createdAt', isLessThan: lastPostModel.value.createdAt)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    // if the docs are not empty, set the last doc
    lastPostModel.value = res.docs.isEmpty
        ? PostModel.empty()
        : PostModel.fromJson(res.docs.last.data());

    for (var element in res.docs) {
      postModels.add(PostModel.fromJson(element.data()));
    }
    print("Post List: $postModels");

    isLoadingNextSet(false);
  }
}
