import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:chunaw/app/service/vote_service.dart';
import 'package:get/get.dart';

class PradhanVoteController extends GetxController {
  var isLoading = false.obs;

  RxBool voting = false.obs;
  RxBool canVote = false.obs;
  updatevotingStatus(String docId) async {
    voting.value = await PradhanService.getVoting(docId: docId);
  }

  List<UserModel> userList = List<UserModel>.empty(growable: true);
  getTopTenPosts({required String locationText, required int level}) async {
    isLoading(true);

    print("ishwar:loc getting data for $locationText and $level");
    userList.clear();
    var res = await VoteService.getHighestUpvotedUsers(locationText, level);
    userList.addAll(res);
    print("ishwar:loc Vote User post List: $userList");

    isLoading(false);
  }

  updateListOnVote({required String locationText, required int level}) async {
    userList.clear();
    var res = await VoteService.getHighestUpvotedUsers(locationText, level);
    userList.addAll(res);
    print("Vote User post List: $userList");
    print("Post List: $userList");
    Get.forceAppUpdate();
  }
}
