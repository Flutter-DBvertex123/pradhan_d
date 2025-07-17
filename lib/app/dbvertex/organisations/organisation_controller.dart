import 'dart:io';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../models/followers_model.dart';
import '../../service/location_service.dart';
import '../../service/user_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_toast.dart';

class OrganisationController extends GetxController {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final addressController = TextEditingController();

  final isLoading = false.obs;
  final visibility = 'Private'.obs;

  final organisationIcon = Rx<File?>(null);
  final organizationImage = RxString('');

  final countryLoading = false.obs;
  final stateLoading = false.obs;
  final cityLoading = false.obs;
  final postalLoading = false.obs;

  final selectedCountry = LocationModel.empty(name: 'Select Country').obs;
  final selectedState = LocationModel.empty(name: 'Select State').obs;
  final selectedCity = LocationModel.empty(name: 'Select City').obs;
  final selectedPostal = LocationModel.empty(name: 'Select Postal').obs;

  final countryList = <LocationModel>[].obs;
  List<LocationModel> stateList = [];
  List<LocationModel> cityList = [];
  List<LocationModel> postalList = [];

  @override
  void onInit() {
    getCountry();
    super.onInit();
  }

  Future<void> initialize(String organizationId) async {
    isLoading.value = true;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(USER_DB)
          .doc(organizationId)
          .get();
      final data = snapshot.data();
      nameController.text = data?['name'] ?? '';
      descController.text = data?['userdesc'] ?? '';
      addressController.text = data?['organization_address'] ?? '';

      organizationImage.value = data?['image'] ?? '';
      visibility.value = data?['visibility'] ?? 'Private';
    } catch (_) {}

    isLoading.value = false;
  }

  Future<bool> validate(bool updating) async {
    if (nameController.text.trim().isEmpty) {
      longToastMessage('Please enter organisation name.');
      return false;
    }
    if (descController.text.trim().isEmpty) {
      longToastMessage('Please enter organisation description.');
      return false;
    }
    if (addressController.text.trim().isEmpty && !updating) {
      longToastMessage('Please enter organisation address.');
      return false;
    }
    if (selectedCountry.value.id == '' && !updating) {
      longToastMessage('Please select organisation\'s country.');
      return false;
    }
    if (selectedState.value.id == '' && !updating) {
      longToastMessage('Please select organisation\'s state.');
      return false;
    }
    if (selectedCity.value.id == '' && !updating) {
      longToastMessage('Please select organisation\'s city.');
      return false;
    }
    if (selectedPostal.value.id == '' && !updating) {
      longToastMessage('Please select organisation\'s postal.');
      return false;
    }
    return true;
  }

  Future<String> uploadAndReturnIcon(String name) async {
    String imageUrl = "";
    if (organisationIcon.value != null) {
      Reference reference = FirebaseStorage.instance.ref(USER_DB).child(name);

      final mimeType = lookupMimeType(organisationIcon.value!.path);

      UploadTask uploadTask = reference.putFile(
        organisationIcon.value!,
        SettableMetadata(contentType: mimeType),
      );

      try {
        TaskSnapshot snapshot = await uploadTask.timeout(Duration(minutes: 5));
        imageUrl = await snapshot.ref.getDownloadURL();
      } on FirebaseException catch (e) {
        longToastMessage(e.message ?? e.toString());
      }
    }
    return imageUrl.isEmpty ? organizationImage.value : imageUrl;
  }

  Future<bool> createOrganisation(String? organizationId) async {
    bool isUpdating = organizationId != null;

    if (!await validate(isUpdating)) {
      return false;
    }

    if (organisationIcon.value == null && !isUpdating) {
      final iconStatus = await showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          title: Text('Missing Organization Icon'),
          content: Text(
              'Adding an icon to your organisation enhances its recognition and appeal. Would you like to add it now?'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(result: true); // Proceed later
              },
              child: Text(
                'Skip for Now',
                style: TextStyle(color: AppColors.gradient1),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back(result: false); // Proceed to add icon
              },
              child: Text(
                'Add Icon',
                style: TextStyle(color: AppColors.gradient1),
              ),
            ),
          ],
        ),
      );

      if (!iconStatus) {
        return false;
      }
    }

    loadingcontroller.updateLoading(true);

    try {
      final reference =
          FirebaseFirestore.instance.collection(USER_DB).doc(organizationId);

      String image = await uploadAndReturnIcon(reference.id);

      final organisation = {
        if (!isUpdating)
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch.toString(),
        if (!isUpdating) 'fcm': '',
        if (!isUpdating) "level": 1,
        if (!isUpdating) 'oadmin': getPrefValue(Keys.USERID),
        if (!isUpdating)
          'username': nameController.text.toLowerCase().trim()
            ..replaceAll(RegExp(r'[^a-zA-Z0-9_.\s]+'), '')
                .replaceAll(RegExp(r'\s+'), '_'),
        'name': nameController.text.trim().capitalizeFirst,
        'userdesc': descController.text.trim(),
        'visibility': visibility.value,
        if (!isUpdating) 'organization_address': addressController.text.trim(),
        'image': image,
        if (!isUpdating) 'country': selectedCountry.value.toJson(),
        if (!isUpdating) 'state': selectedState.value.toJson(),
        if (!isUpdating) 'city': selectedCity.value.toJson(),
        if (!isUpdating) 'postal': selectedPostal.value.toJson(),
        if (!isUpdating) "is_organization": true,
        if (!isUpdating) 'upvote_count': 0,
        if (!isUpdating) 'id': reference.id,
      };
      if (isUpdating) {
        await reference.update(organisation);
      } else {
        await reference.set(organisation);
        final followerModel = FollowerModel(
            followerId: FirebaseAuth.instance.currentUser!.uid,
            followeeId: reference.id,
            createdAt: Timestamp.now());
        await UserService.addFollowers(followerModel: followerModel);

        await FirebaseFirestore.instance.collection(PRADHAN_DB).doc(reference.id).set({
          'pradhan_id': "",
          "pradhan_model": {
            "fcm": "",
            "id": "",
            "image": "",
            "level": "",
            "name": "",
            "userdesc": "",
            "username": ""
          },
          "pradhan_status": "",
          "voting": false,
        });
      }
      loadingcontroller.updateLoading(false);
      return true;
    } catch (error) {
      print("ishwar:new: $error");
      longToastMessage(
          'Something went wrong while ${isUpdating ? 'updating' : 'creating'} organisation.');
    }

    loadingcontroller.updateLoading(false);
    return false;
  }

  //Camera Actions
  cameraAction(BuildContext context) {
    showAdaptiveActionSheet(
      title: Text(
        "Select Option",
        style: TextStyle(fontSize: 25),
      ),
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: Text("Camera", style: TextStyle(color: AppColors.gradient2)),
          onPressed: (c) {
            Get.back();
            getImageFromCamera(context);
          },
        ),
        BottomSheetAction(
          title: Text(
            "Gallery",
            style: TextStyle(color: AppColors.gradient2),
          ),
          onPressed: (c) {
            Get.back();
            getImageFromGallery(context);
          },
        )
      ],
      cancelAction: CancelAction(
        title: Text("Cancel"),
        onPressed: (c) {
          Get.back();
          return;
        },
      ),
      context: context,
    );

    // showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Future getImageFromCamera(BuildContext context) async {
    var image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 20);
    debugPrint("$image");
    // imageFile.value = File(image!.path);
    cropView(image);
  }

  Future getImageFromGallery(BuildContext context) async {
    var image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 20);
    debugPrint("$image");
    // imageFile.value = File(image!.path);
    cropView(image!);
  }

  cropView(var image) async {
    CroppedFile? croppedFile = await ImageCropper()
        .cropImage(sourcePath: image.path,  uiSettings: [
      AndroidUiSettings(
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
        ],
        toolbarTitle: "Crop",
        toolbarColor: AppColors.gradient2,
        toolbarWidgetColor: AppColors.white,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: false,
      ),
      IOSUiSettings(
        minimumAspectRatio: 1.0,
      )
    ]);
    organisationIcon.value = File(croppedFile!.path);
  }

  getCountry() async {
    countryLoading(true);
    countryList.value = await LocationService.getCountry();

    // sorting the country list
    countryList.sort((a, b) => a.name.compareTo(b.name));

    // ! What did the below commented line did? Commenting it didn't impact anything. But when it was active, it introduced a bug where the state value was cleared automatically during build()
    // selectedState.value = LocationModel.empty(name: "Select State");
    countryLoading(false);
  }

  getState() async {
    if (selectedCountry.value.id.isEmpty) {
      longToastMessage("Select Country First.");
    } else {
      stateLoading(true);
      stateList = await LocationService.getState(selectedCountry.value.id);

      // sorting the states
      stateList.sort((a, b) => a.name.compareTo(b.name));

      stateLoading(false);
    }
  }

  getCity() async {
    if (selectedState.value.id.isEmpty) {
      longToastMessage("Select State First.");
    } else {
      cityLoading(true);
      cityList = await LocationService.getCity(
          selectedCountry.value.id, selectedState.value.id);

      // sorting the cities
      cityList.sort((a, b) => a.name.compareTo(b.name));

      cityLoading(false);
    }
  }

  getPostal() async {
    if (selectedCity.value.id.isEmpty) {
      longToastMessage("Select City First.");
    } else {
      postalLoading(true);
      postalList = await LocationService.getPostal(selectedCountry.value.id,
          selectedState.value.id, selectedCity.value.id);

      // sorting the postals
      postalList.sort((a, b) => a.name.compareTo(b.name));
      postalLoading(false);
    }
  }

  // methods to reset selected data
  void resetState() {
    selectedState.value = LocationModel.empty(name: "Select State");
  }

  void resetCity() {
    selectedCity.value = LocationModel.empty(name: "Select City");
  }

  void resetPostal() {
    selectedPostal.value = LocationModel.empty(name: "Select Postal");
  }
}
