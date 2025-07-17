import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/service/location_service.dart';
import 'package:chunaw/main.dart';
import 'package:get/get.dart';

class LocationAdminController extends GetxController {
  RxBool stateLoading = false.obs;
  RxBool cityLoading = false.obs;
  RxBool pincodeLoading = false.obs;
  String stateId = "";
  String cityId = "";

  List<LocationModel> stateList = List<LocationModel>.empty(growable: true).obs;
  List<LocationModel> cityList = List<LocationModel>.empty(growable: true).obs;
  List<LocationModel> postalList =
      List<LocationModel>.empty(growable: true).obs;

  getStates() async {
    stateLoading(true);
    stateList = await LocationService.getState("1-India");
    stateLoading(false);
    update();
  }

  getCity() async {
    cityLoading(true);
    print(stateId);
    cityList = await LocationService.getCity("1-India", stateId);
    cityLoading(false);
    update();
  }

  getPostal() async {
    pincodeLoading(true);
    postalList = await LocationService.getPostal("1-India", stateId, cityId);
    pincodeLoading(false);
    update();
  }

  addState(LocationModel locationModel) async {
    loadingcontroller.updateLoading(true);
    await LocationService.addState(
        locationModel: locationModel, countryId: "1-India");
    getStates();
    loadingcontroller.updateLoading(false);
    Get.back();
  }

  addCity(LocationModel locationModel) async {
    loadingcontroller.updateLoading(true);
    await LocationService.addCity(
        locationModel: locationModel, countryId: "1-India", stateId: stateId);
    getCity();
    loadingcontroller.updateLoading(false);
    Get.back();
  }

  addPostal(LocationModel locationModel) async {
    loadingcontroller.updateLoading(true);
    await LocationService.addPostal(
        locationModel: locationModel,
        countryId: "1-India",
        cityId: cityId,
        stateId: stateId);
    getPostal();
    loadingcontroller.updateLoading(false);
    Get.back();
  }
}
