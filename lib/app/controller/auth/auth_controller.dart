import 'dart:convert';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/enums.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:chunaw/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  TextEditingController phoneController = TextEditingController();
  String? _verificationId;
  String? uid;
  String? token;
  int? forceResendingToken;
  //var conCode = "+48";
  RxString selectedCountryCode = "+91".obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  signInwithPhone({ScreenOps screenOps = ScreenOps.login}) async {
    if (phoneController.text.isEmpty) {
      longToastMessage("Phone Number Required");
      return;
    }
    loadingcontroller.updateLoading(true);
    // if (screen == "OTP") {
    //   // Get.dialog(Dialog(
    //   //   backgroundColor: Colors.transparent,
    //   //   child: Center(child: CircularProgressIndicator()),
    //   // ));
    // }
    debugPrint("InsignIn");
    verificationCompleted(PhoneAuthCredential phoneAuthCredential) async {
      print("yash: verification complated PhoneAuth credential: $phoneAuthCredential");

    }
    verificationFailed(FirebaseAuthException authException) {
      debugPrint("auth Exeception ${authException.message}");
      longToastMessage("Invalid Number ");
      loadingcontroller.updateLoading(false);
    }

    codeSent(String verificationId, [int? forceResendingToken]) async {
      print("yash: codeSent forceResending token: $forceResendingToken");
      this.forceResendingToken = forceResendingToken;
      print("yash: codeSent verification ID token: $verificationId");

      _verificationId = verificationId;
      if (screenOps == ScreenOps.login) {
        // longToastMessage("OTP Sent");
        debugPrint("$_verificationId $token");
        AppRoutes.navigateToVerifyMobile();
        loadingcontroller.updateLoading(false);
        // Get.to(
        //     VerificationScreen("${phoneController.text}", _verificationId, token));
      } else {
        longToastMessage("Your OTP has been resent");
        debugPrint("codeSent: $verificationId");
        loadingcontroller.updateLoading(false);
      }
    }

    codeAutoRetrievalTimeout(String verificationId) {
      debugPrint('before verificationId: $verificationId');
      _verificationId = verificationId;
      debugPrint('after verificationId: $_verificationId');
    }
    try {
      debugPrint("In try block");
      print("Mobile Code: ${selectedCountryCode.value}${phoneController.text}");
      print("forceResendingToken: $forceResendingToken");
      await _auth.verifyPhoneNumber(
          phoneNumber: "${selectedCountryCode.value}${phoneController.text}",
          timeout: const Duration(seconds: 5),
          verificationCompleted: verificationCompleted,
          forceResendingToken: forceResendingToken,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    } on FirebaseAuthException catch (e) {
      longToastMessage("${e.message}");
      loadingcontroller.updateLoading(false);
    }
  }

  void verifyOTP(context, {required String smsCode}) async {
    if (smsCode != "") {
      final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: smsCode);
      try {
        loadingcontroller.updateLoading(true);
        debugPrint("IshwarInv: Starting");
        try {
          await FirebaseAuth.instance.signInWithCredential(
            credential,
          );
        } catch (err) {
          debugPrint("Ignored error: $err");
        }
        debugPrint("IshwarInv: authenticated");
        if (FirebaseAuth.instance.currentUser?.uid != null) {
          if (await UserService.userExists(
              FirebaseAuth.instance.currentUser!.uid)) {
            await setUserValues();

            // setting the selected states, default to the current home one
            await setPrefValue(
              Keys.PREFERRED_STATES,
              jsonEncode(
                [locationModelFromJson(getPrefValue(Keys.STATE)).name],
              ),
            );

            AppRoutes.navigateOffHomeTabScreen();
          } else {
            AppRoutes.navigateOffProfileData(isGuestLogin: false);
          }
        }
        loadingcontroller.updateLoading(false);
      } catch (e) {
        debugPrint("$e : uid=${FirebaseAuth.instance.currentUser?.uid}");
        loadingcontroller.updateLoading(false);
        longToastMessage("Please enter valid OTP");
      }
    } else {
      longToastMessage("Please enter OTP");
    }
  }

  Future signInWithGoogle() async {
    loadingcontroller.updateLoading(true);
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    try {
      UserCredential user = await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (err) {
      debugPrint("Ignored error(uid=${FirebaseAuth.instance.currentUser?.uid}): $err");
    }
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      if (await UserService.userExists(FirebaseAuth.instance.currentUser?.uid)) {
        // we set the values first in prefs
        await setUserValues();

        // setting the selected states, default to the current home one
        await setPrefValue(
          Keys.PREFERRED_STATES,
          jsonEncode(
            [locationModelFromJson(getPrefValue(Keys.STATE)).name],
          ),
        );

        AppRoutes.navigateOffHomeTabScreen();
      } else {
        AppRoutes.navigateOffProfileData(isGuestLogin: false);
      }
    }
    loadingcontroller.updateLoading(false);
  }

  setUserValues() async {
    UserModel? user =
        await UserService.getUserData(FirebaseAuth.instance.currentUser!.uid);
    if (user != null) {
      await setPrefValue(Keys.NAME, user.name);
      await setPrefValue(Keys.PHONE, user.phone);
      await setPrefValue(Keys.USERNAME, user.username);
      await setPrefValue(Keys.USERID, user.id);
      await setPrefValue(Keys.PROFILE_PHOTO, user.image);
      await setPrefValue(Keys.AFFILIATE_PHOTO, user.affiliateImage);
      await setPrefValue(Keys.AFFILIATE_TEXT, user.affiliateText);
      await setPrefValue(Keys.ADMIN, user.admin.toString());
      await setPrefValue(Keys.USER_DESC, user.userdesc);
      await setPrefValue(Keys.STATE, jsonEncode(user.state.toJson()));
      await setPrefValue(Keys.CITY, jsonEncode(user.city.toJson()));
      await setPrefValue(Keys.COUNTRY, jsonEncode(user.country.toJson()));
      await setPrefValue(Keys.PREFERRED_ELECTION_LOCATION,
          jsonEncode(user.preferredElectionLocation.toJson()));
      await setPrefValue(Keys.POSTAL, jsonEncode(user.postal.toJson()));
      await setPrefValue(Keys.LEVEL, user.level.toString());
      await setPrefValue(Keys.IS_ORGANIZATION, user.isOrganization.toString());
      await setPrefValue(Keys.ORGANIZATION_ADDRESS, user.organizationAddress);
      await setPrefValue(Keys.UPVOTE_COUNT, user.upvoteCount.toString());
      await Pref.setBool(Keys.IS_GUEST_LOGIN, false);
    }
  }
}
