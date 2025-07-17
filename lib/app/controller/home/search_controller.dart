import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class SearchingController extends GetxController {
  var isLoading = false.obs;
  List<UserModel> userList = List<UserModel>.empty(growable: true);
  // List<UserModel> userListDisplay = List<UserModel>.empty(growable: true);

  getUsers(String text) async {
    isLoading(true);
    userList.clear();
    var res = await FirebaseFirestore.instance
        .collection(USER_DB)
        // .where("user_id", isNotEqualTo: getPrefValue(Keys.USERID))
        .where("name", isNotEqualTo: text.toLowerCase())
        .orderBy("name")
        .startAt([
      text,
    ]).endAt([
      '$text\uf8ff',
    ]).get();

    for (var element in res.docs) {
      // print("data ${element.data()}");
      userList.add(UserModel.fromJson(element.data()));
      // if (element.get("id") == DatabaseService.getUid()) {
      // } else if (element.get("verified") == false) {
      // } else if (element.get("role") == 0) {
      // } else {
      //   userList.add(UserModel.fromJson(element.data()));
      // }
    }
    print("User List: $userList");

    isLoading(false);
  }
}
