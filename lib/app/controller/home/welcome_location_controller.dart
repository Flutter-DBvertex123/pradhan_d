import 'dart:developer';

import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/post_service.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class WelcomeLocationController extends GetxController {
  var isLoading = false.obs;
  var isStatusLoading = false.obs;
  var pradhanId = "".obs;
  var pradhanStatus = "".obs;
  var pinpostModel = PostModel.empty().obs;
  Rx<UserModel> pradhanModel = UserModel.empty().obs;

  int limit = 20;

  getPradhanId(String docId) async {
    isStatusLoading.value = true;

    final results = await PradhanService.fetchPradhanData(docId: docId);
    pradhanId.value = results.pradhanId;
    Get.forceAppUpdate();
    pradhanModel.value = results.pradhanModel;
    pradhanStatus.value = results.pradhanStatus;
    log("Pinned Post: ${results.pinnedPost}");
    if (results.pinnedPost != "") {
      pinpostModel.value =
          await PostService.getPost(results.pinnedPost) ?? PostModel.empty();
      print("Pin post model: ${pinpostModel.value.postId}");
    }

    isStatusLoading.value = false;
  }

  List<PostModel> postList = List<PostModel>.empty(growable: true);
  getPosts(List fullAdd) async {
    isLoading(true);
    postList.clear();
    var res = await FirebaseFirestore.instance
        .collection(POST_DB)
        .orderBy("createdAt", descending: true)
        .where("full_add", arrayContainsAny: fullAdd)
        .limit(limit)
        .get();

    for (var element in res.docs) {
      // print("data ${element.data()}");
      postList.add(PostModel.fromJson(element.data()));
      // if (element.get("id") == DatabaseService.getUid()) {
      // } else if (element.get("verified") == false) {
      // } else if (element.get("role") == 0) {
      // } else {
      //   userList.add(UserModel.fromJson(element.data()));
      // }
    }
    print("Post List: $postList");

    isLoading(false);
  }
}
