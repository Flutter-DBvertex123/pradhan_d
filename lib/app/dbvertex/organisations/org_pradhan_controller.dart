import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:get/get.dart';

import '../../service/pradhan_service.dart';

class OrgPradhanController extends GetxController{
  final String organizationId;

  OrgPradhanController(this.organizationId);

  final pradhanId = ''.obs;
  final pradhan = Rx<UserModel?>(null);

  String pradhanStatus = '';

  final isCurrentUserPradhaan = RxBool(false);

  @override
  void onInit() {
    initialize();
    super.onInit();
  }

  Future<void> initialize() async {
    try {
      final results = await PradhanService.fetchPradhanData(docId: organizationId);
      pradhanStatus = results.pradhanStatus;
      pradhan.value = results.pradhanModel;
      pradhanId.value = results.pradhanId;
      isCurrentUserPradhaan.value = pradhanId.isNotEmpty && pradhanId.value == getPrefValue(Keys.USERID);
      print("ishwar:new :: pradhan -> ${pradhan.value?.toJson()}");
    } catch (error) {
      print("ishwar:new :: error -> $error");
    }
  }
}