import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  List<PostModel> postList = List<PostModel>.empty(growable: true);
  String userId = "";
  // List<UserModel> userListDisplay = List<UserModel>.empty(growable: true);

  // variable to hold the last doc
  DocumentSnapshot? lastDoc;

  int limit = 10;
  getPosts({bool nextSet = false}) async {
    isLoading(true);

    // if we are not asking for next set then
    if (!nextSet) {
      // clearing the posts and the last doc reference
      postList.clear();
      lastDoc = null;
    } else {
      // if we are asking for the next set
      // if the last doc is already null, we can't give the next set
      if (lastDoc == null) {
        isLoading(false);
        return;
      }
    }

    QuerySnapshot<Map<String, dynamic>> res;

    var baseQuery = FirebaseFirestore.instance
        .collection(POST_DB)
        .where("user_id", isEqualTo: userId)
        .limit(limit)
        .orderBy("createdAt", descending: true);

    // flag variable for the loop
    // if we are requesting next set, it should be false on initialization
    bool isFirst = !nextSet;

    // if this is the first iteration, then load the first set
    if (isFirst) {
      res = await baseQuery.limit(limit).get();
      isFirst = false;
    } else {
      // otherwise, load the next set
      res = await baseQuery.startAfterDocument(lastDoc!).limit(limit).get();
    }

    // if the docs are not empty, set the last doc
    lastDoc = res.docs.isEmpty ? null : res.docs.last;

    for (var element in res.docs) {
      postList.add(PostModel.fromJson(element.data()));
    }
    print("Post List: $postList");

    isLoading(false);
  }
}
