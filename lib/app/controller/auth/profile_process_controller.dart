import 'dart:convert';
import 'dart:io';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/location_service.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:chunaw/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chunaw/app/utils/parties_data.dart';
import 'package:mime/mime.dart';

class ProfileProcessController extends GetxController {
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController userdescController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController affiliateTextController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  RxBool countryLoading = false.obs;
  RxBool stateLoading = false.obs;
  RxBool cityLoading = false.obs;
  RxBool postalLoading = false.obs;
  Rx<File> profilePhoto = File("").obs;
  Rx<File> affiliatePhoto = File("").obs;
  UserModel userData = UserModel.empty();
  Rx<LocationModel> selectedCountry =
      LocationModel.empty(name: "Select Country").obs;
  Rx<LocationModel> selectedState =
      LocationModel.empty(name: "Select State").obs;
  Rx<LocationModel> selectedPostal =
      LocationModel.empty(name: "Select Postal").obs;
  Rx<LocationModel> selectedCity = LocationModel.empty(name: "Select City").obs;
  RxList countryList = [].obs;
  List<LocationModel> stateList = [];
  List<LocationModel> cityList = [];
  List<LocationModel> postalList = [];
  @override
  void onInit() {
    getCountry();
    super.onInit();
  }

  saveProfileData() {
    print(affiliateImagePreDefinedPath.value);
    if (nameController.text.isEmpty) {
      longToastMessage("Name is required.");
    } else if (usernameController.text.isEmpty) {
      longToastMessage("Username is required.");
    } else {
      userData.id = FirebaseAuth.instance.currentUser!.uid;
      userData.name = nameController.text;
      userData.username = usernameController.text;
      userData.userdesc = '';
      userData.affiliateText = '';
      userData.isOrganization = !isIndividual.value;
      userData.organizationAddress = addressController.text;
    }
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

  saveLocationData(bool isGuestLogin) {
    if (selectedCountry.value.id == "") {
      longToastMessage("Country is required.");
    } else if (selectedState.value.id == "") {
      longToastMessage("State is required.");
    } else if (selectedCity.value.id == "") {
      longToastMessage("City is required.");
    } else if (selectedPostal.value.id == "") {
      longToastMessage("Postal is required.");
    } else {
      userData.state = selectedState.value;
      userData.city = selectedCity.value;
      userData.country = selectedCountry.value;
      userData.postal = selectedPostal.value;
      // AppRoutes.navigateToUploadImageScreen();

      // creating the account
      if (!isGuestLogin) {
        createAccount();
      }
    }
  }

  Future<String> uploadFile(File file, bool setProfileImage) async {
    Reference reference = FirebaseStorage.instance
        .ref(USER_DB)
        .child((setProfileImage ? userData.id : '${userData.id}-affiliate'));

    print('user id: ${userData.id}');
    print('full path: ${reference.fullPath}');

    final mimeType = lookupMimeType(file.path);

    UploadTask uploadTask = reference.putFile(
      file,
      SettableMetadata(contentType: mimeType),
    );
    String imageUrl = "";

    print("ishwar: uploading image: ${file} - ${userData.id}");
    try {
      TaskSnapshot snapshot = await uploadTask.timeout(Duration(seconds: 5));
      print("ishwar: uploaded");
      imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } on FirebaseException catch (e) {
      print("ishwar: uploaded $e");
      longToastMessage(e.message ?? e.toString());
      return "";
    }
  }

  Future<String> uploadBytes(String imagePath) async {
    Reference reference =
        FirebaseStorage.instance.ref(USER_DB).child('${userData.id}-affiliate');

    // loading the bytes of the image
    ByteData bytes = await rootBundle.load(imagePath);

    UploadTask uploadTask = reference.putData(bytes.buffer.asUint8List());
    String imageUrl = "";
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } on FirebaseException catch (e) {
      longToastMessage(e.message ?? e.toString());
      return "";
    }
  }

  var imageFile = File("").obs;
  var affiliateImageFile = File('').obs;
  var affiliateImagePreDefinedPath = ''.obs;
  var isIndividual = true.obs;

  //Camera Actions
  cameraAction(BuildContext context, bool setProfileImage) {
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
            getImageFromCamera(context, setProfileImage);
          },
        ),
        BottomSheetAction(
          title: Text(
            "Gallery",
            style: TextStyle(color: AppColors.gradient2),
          ),
          onPressed: (c) {
            Get.back();
            getImageFromGallery(context, setProfileImage);
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

  Future getImageFromCamera(BuildContext context, bool setProfileImage) async {
    var image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 20);
    debugPrint("$image");
    // imageFile.value = File(image!.path);
    cropView(image, setProfileImage);
  }

  Future getImageFromGallery(BuildContext context, bool setProfileImage) async {
    var image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 20);
    debugPrint("$image");
    // imageFile.value = File(image!.path);
    cropView(image!, setProfileImage);
  }

  cropView(var image, bool setProfileImage) async {
    CroppedFile? croppedFile = await ImageCropper()
        .cropImage(sourcePath: image.path, uiSettings: [
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
    if (setProfileImage) {
      imageFile.value = File(croppedFile!.path);
    } else {
      affiliateImageFile.value = File(croppedFile!.path);

      // resetting the affiliate image pre defined path
      affiliateImagePreDefinedPath.value = '';

      // resetting the affiliate text as well if one of the pre-existing party name is selected
      if (parties.keys.contains(affiliateTextController.text)) {
        affiliateTextController.text = '';
      }
    }
  }

  createAccount() async {
    loadingcontroller.updateLoading(true);
    userData.image = '';

    // if affiliate image has value then we upload it
    // if (affiliateImageFile.value.path.isNotEmpty) {
    //   userData.affiliateImage =
    //       await uploadFile(affiliateImageFile.value, false);
    // } else if (affiliateImagePreDefinedPath.value.isNotEmpty) {
    //   // if the pre defined image has a value then we upload those bytes
    //   print(affiliateImagePreDefinedPath.value);
    //   userData.affiliateImage =
    //       await uploadBytes(affiliateImagePreDefinedPath.value);
    // }

    userData.affiliateImage = '';

    try {
      final value = await UserService.createAccount(userData: userData);

      if (value) {
        AppRoutes.navigateOffHomeTabScreen();

        // setting the selected states, default to the current home one
        await setPrefValue(
          Keys.PREFERRED_STATES,
          jsonEncode(
            [locationModelFromJson(getPrefValue(Keys.STATE)).name],
          ),
        );
      }
    } finally {
      loadingcontroller.updateLoading(false);
    }
  }

  Future<void> updateLocationData() async {
    if (selectedCountry.value.id == "") {
      longToastMessage("Country is required.");
    } else if (selectedState.value.id == "") {
      longToastMessage("State is required.");
    } else if (selectedCity.value.id == "") {
      longToastMessage("City is required.");
    } else if (selectedPostal.value.id == "") {
      longToastMessage("Postal is required.");
    } else {
      loadingcontroller.updateLoading(true);

      // grabbing the current state
      final currentState = locationModelFromJson(getPrefValue(Keys.STATE)).name;

      // grabbing the new state
      final newState = selectedState.value.name;

      // if they are not same, we must update shared preferences
      if (currentState != newState) {
        final currentPreferredStates =
            (jsonDecode(getPrefValue(Keys.PREFERRED_STATES)) as List);

        // removing current state from preferred states
        currentPreferredStates.remove(currentState);

        // adding new state in place
        currentPreferredStates.add(newState);

        // updating the preferred states
        setPrefValue(Keys.PREFERRED_STATES, jsonEncode(currentPreferredStates));
      }

      // grabbing the data we need
      final state = selectedState.value;
      final city = selectedCity.value;
      final country = selectedCountry.value;
      final postal = selectedPostal.value;

      try {
        // if is a guest user
        if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
          await setPrefValue(Keys.STATE, jsonEncode(state.toJson()));
          await setPrefValue(Keys.CITY, jsonEncode(city.toJson()));
          await setPrefValue(Keys.COUNTRY, jsonEncode(country.toJson()));
          await setPrefValue(Keys.POSTAL, jsonEncode(postal.toJson()));

          loadingcontroller.updateLoading(false);
          AppRoutes.navigateOffHomeTabScreen();
        } else {
          await UserService.updateUserWithGivenFields(
            userId: FirebaseAuth.instance.currentUser!.uid,
            data: {
              'postal': postal.toJson(),
              'city': city.toJson(),
              'state': state.toJson(),
              'country': country.toJson(),
            },
          );
        }
      } catch (e) {
        longToastMessage("Try Again...");
        loadingcontroller.updateLoading(false);
      }
    }
  }

  updateData() async {
    if (nameController.text.isEmpty) {
      longToastMessage("Name is required.");
    } else if (usernameController.text.isEmpty) {
      longToastMessage("Username is required.");
    } else if (selectedCountry.value.id == "") {
      longToastMessage("Country is required.");
    } else if (!isIndividual.value && addressController.text.isEmpty) {
      longToastMessage('Organization address is required.');
    } else if (selectedState.value.id == "") {
      longToastMessage("State is required.");
    } else if (selectedCity.value.id == "") {
      longToastMessage("City is required.");
    } else if (selectedPostal.value.id == "") {
      longToastMessage("Postal is required.");
    } else {
      // if the organization name is set
      if (affiliateTextController.text.isNotEmpty) {
        // but the organization icon is missing (predefined, custom, or existing)
        if (affiliateImageFile.value.path.isEmpty &&
            affiliateImagePreDefinedPath.value.isEmpty &&
            getPrefValue(Keys.AFFILIATE_PHOTO).isEmpty) {
          longToastMessage('Please provide the organization icon');
          return;
        }
      } else {
        // else if the text is empty but the image is provided (either new or existing is there)
        if (affiliateImageFile.value.path.isNotEmpty ||
            affiliateImagePreDefinedPath.value.isNotEmpty ||
            getPrefValue(Keys.AFFILIATE_PHOTO).isNotEmpty) {
          longToastMessage('Please provide the organization name');
          return;
        }
      }

      loadingcontroller.updateLoading(true);

      // grabbing the current state
      final currentState = locationModelFromJson(getPrefValue(Keys.STATE)).name;

      // grabbing the new state
      final newState = selectedState.value.name;

      // if they are not same, we must update shared preferences
      if (currentState != newState) {
        final currentPreferredStates =
            (jsonDecode(getPrefValue(Keys.PREFERRED_STATES)) as List);

        // removing current state from preferred states
        currentPreferredStates.remove(currentState);

        // adding new state in place
        currentPreferredStates.add(newState);

        // updating the preferred states
        setPrefValue(Keys.PREFERRED_STATES, jsonEncode(currentPreferredStates));
      }

      // setting up the user id
      userData.id = FirebaseAuth.instance.currentUser!.uid;

      // uploading the images
      if (imageFile.value.path != "") {
        print("ishwar: uploading image...");
        userData.image = await uploadFile(imageFile.value, true);
        print("ishwar: uploaded image...");

      } else {
        // if no new image is set then we revert back to the old one
        userData.image = getPrefValue(Keys.PROFILE_PHOTO);
      }

      if (affiliateImageFile.value.path != "") {
        print("uploading affiliate image...");
        userData.affiliateImage =
            await uploadFile(affiliateImageFile.value, false);
      } else if (affiliateImagePreDefinedPath.value.isNotEmpty) {
        userData.affiliateImage =
            await uploadBytes(affiliateImagePreDefinedPath.value);
      } else {
        // if no new image is set then we revert back to the old one
        userData.affiliateImage = getPrefValue(Keys.AFFILIATE_PHOTO);
      }

      // setting the rest of the data
      userData.name = nameController.text;
      userData.username = usernameController.text;
      userData.userdesc = userdescController.text;
      userData.state = selectedState.value;
      userData.city = selectedCity.value;
      userData.country = selectedCountry.value;
      userData.postal = selectedPostal.value;
      userData.affiliateText =
          !isIndividual.value ? userData.name : affiliateTextController.text;
      userData.isOrganization = !isIndividual.value;
      userData.organizationAddress = addressController.text;
      try {
        await UserService.updateUser(userData: userData);

        // updating the user values in shared prefs
        await UserService.setUserValues();

        loadingcontroller.updateLoading(false);
      } catch (e) {
        longToastMessage("Try Again...");
        loadingcontroller.updateLoading(false);
      }
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
