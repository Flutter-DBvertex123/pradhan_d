import 'package:chunaw/app/dbvertex/organisations/organisation_details_screen.dart';
import 'package:chunaw/app/dbvertex/organisations/organisation_screen.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/screen/auth/login_screen.dart';
import 'package:chunaw/app/screen/auth/mobile_login.dart';
import 'package:chunaw/app/screen/auth/profile_data.dart';
import 'package:chunaw/app/screen/auth/profile_update.dart';
// import 'package:chunaw/app/screen/auth/upload_image_screen.dart';
import 'package:chunaw/app/screen/auth/verify_mobile.dart';
import 'package:chunaw/app/screen/home/add_post_screen.dart';
import 'package:chunaw/app/screen/home/comment_page.dart';
import 'package:chunaw/app/screen/home/create_poll_page.dart';
import 'package:chunaw/app/screen/home/create_post_screen.dart';
import 'package:chunaw/app/screen/home/download_pradhaan_card_screen.dart';
import 'package:chunaw/app/screen/home/home_tab_screen.dart';
import 'package:chunaw/app/screen/home/my_profile_screen.dart';
import 'package:chunaw/app/screen/Location_features/welcome_location_page.dart';
import 'package:chunaw/app/screen/home/videos_scrollview_screen.dart';
import 'package:get/get.dart';

class AppRoutes {
  static navigateOffLogin() {
    Get.offAll(() => LoginScreen(
          removeGuestLogin: false,
        ));
  }

  static navigateToMobileLogin() {
    Get.to(() => MoibleLogin());
  }

  static navigateToVerifyMobile() {
    Get.to(() => VerifyMobile());
  }

  static navigateOffProfileData({required bool isGuestLogin}) {
    Get.offAll(() => ProfileData(
          isGuestLogin: isGuestLogin,
        ));
  }

  static navigateToProfileData({required bool isGuestLogin}) {
    Get.to(() => ProfileData(
          isGuestLogin: isGuestLogin,
        ));
  }

  static navigateToLogin({bool removeGuestLogin = true}) {
    Get.to(() => LoginScreen(removeGuestLogin: removeGuestLogin));
  }

  static navigateToCreatePollPage(int level) {
    Get.to(() => CreatePollPage(
          level: level,
        ));
  }

  static navigateToVideosScrollview({required int? level}) {
    Get.to(
      () => VideosScrollviewScreen(
        level: level,
      ),
    );
  }

  static navigateToAddPost(
      {PostModel? existingPost, String? organizationId}) async {
    // return await Get.to(() => AddPostScreen(existingPost: existingPost, organizationId: organizationId));
    return await Get.to(() => CreatePostScreen(
        postModel: existingPost, organizationId: organizationId));
  }

  static Future<bool> navigateToWelcomePage(String name, String locationId,
      String text, int level, bool isHome) async {
    final reload = await Get.to(
      () => WelcomeLocationPage(
        locationName: name,
        locationId: locationId,
        locationText: text,
        level: level,
        isHome: isHome,
      ),
    );

    print('reload: $reload');

    return reload;
  }

  static navigateToProfileUpdate() {
    Get.to(() => ProfileUpdate());
  }

  // static navigateToUploadImageScreen() {
  //   Get.to(() => UploadImageScreen());
  // }

  static navigateToComment(PostModel postModel) {
    Get.to(() => CommentPage(postModel: postModel));
  }

  static navigateOffHomeTabScreen() {
    Get.offAll(() => HomeTabScreen());
  }

  static navigateToDownloadPradhaanCard(
      {required String fundsRaised,
      required String autoFund,
      required String imageUrl,
      required bool isPradhaanAtHisLevel,
      required String name,
      required String userLevelLocation,
      required String votesReceived,
      required String designation}) {
    Get.to(() => DownloadPradhaanCardScreen(
          designation: designation,
          fundsRaised: fundsRaised,
          autoFund: autoFund,
          imageUrl: imageUrl,
          isPradhaanAtHisLevel: isPradhaanAtHisLevel,
          name: name,
          userLevelLocation: userLevelLocation,
          votesReceived: votesReceived,
        ));
  }

  static navigateToMyProfile(
      {required String userId,
      required bool isOrganization,
      required bool back}) {
    if (isOrganization) {
      Get.to(() => OrganisationDetailsScreen(organisationId: userId));
    } else {
      Get.to(() => MyProfileScreen(userId: userId, back: back));
    }
  }
}
