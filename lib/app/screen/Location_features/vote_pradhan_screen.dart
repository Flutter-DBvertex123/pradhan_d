
import 'dart:convert';
import 'package:chunaw/app/controller/auth/profile_process_controller.dart';
import 'package:chunaw/app/controller/location_features/pradhan_vote_controller.dart';
import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/screen/Location_features/user_card.dart';
import 'package:chunaw/app/screen/Location_features/voting_timer.dart';
import 'package:chunaw/app/screen/home/comment_card.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/location_service.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_fonts.dart';
import '../../widgets/app_drop_down.dart';

class VotePradhanScreen extends StatefulWidget {
  const VotePradhanScreen(
      {super.key,
        required this.locationText,
        required this.locationId,
        required this.locationName,
        required this.level});
  final String locationText;
  final String locationId;
  final String locationName;
  final int level;

  @override
  State<VotePradhanScreen> createState() => _VotePradhanScreenState();
}

class _VotePradhanScreenState extends State<VotePradhanScreen> {
  final PradhanVoteController welcomeController =
  Get.put(PradhanVoteController());
  final TextEditingController commentController = TextEditingController();
  final now = DateTime.now();
  final ProfileProcessController processController =
  Get.put(ProfileProcessController(), tag: "UpdateProfile");
  final preferedElectionLocation = getPrefValue(Keys.PREFERRED_ELECTION_LOCATION);
  Map<String,dynamic>? prefElectionLoc;
  @override
  void initState()  {
    super.initState();
    welcomeController.updatevotingStatus(widget.locationId);


    welcomeController.getTopTenPosts(
        locationText: widget.locationText, level: widget.level);
    Future.delayed(Duration(seconds: 1), () {
      setState(() {});
    });
  }
  LocationModel? selectedPref;
//Getting Home location of user for identify area level locations
 /* Future<List<LocationModel>?> getUserCurrentLocationPref() async {
    prefElectionLoc = json.decode(preferedElectionLocation);
    final state = getPrefValue(Keys.STATE);
    final country = getPrefValue(Keys.COUNTRY);
    final city = getPrefValue(Keys.CITY);
    final stateId =  json.decode(state)['id'];
    print('dss : - stateId $stateId');
    final countryId = json.decode(country)['id'];
    final cityId = json.decode(city)['id'];

    if(widget.level == 1){
      return await LocationService.getPostal(countryId, stateId, cityId);

    }else if(widget.level == 2){
      return  LocationService.getCity(countryId, stateId);

    }else if(widget.level == 3){
      return await LocationService.getState(countryId);

    }else{
      return  await LocationService.getCountry();
    }
  }*/
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              welcomeController.getTopTenPosts(
                  locationText: widget.locationText, level: widget.level);
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Obx(() =>
                    welcomeController.voting.value
                        ? Container()
                        : VotingTimerWidget()),
                    userArea(),
                    commentView(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Obx(
              () =>
          !welcomeController.voting.value
              ? Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 20,
              top: 20,
            ),
            child: Text(
              "Voting is not started yet, you can comment once voting is started",
              textAlign: TextAlign.center,
            ),
          )
              : [
            locationModelFromJson(getPrefValue(Keys.POSTAL)).id,
            locationModelFromJson(getPrefValue(Keys.CITY)).id,
            locationModelFromJson(getPrefValue(Keys.STATE)).id,
            "India",
            "1-India"
          ].contains(widget.locationId)
              ? commentField()
              : const SizedBox(),
        ),
        // if voting is not started and is not a guest, only then show the buttons
        if (!welcomeController.voting.value &&
            !Pref.getBool(Keys.IS_GUEST_LOGIN, false))
          selectPreferredElectionLocationButton(),
      ],
    );
  }

  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>
  selectPreferredElectionLocationButton() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(getPrefValue(Keys.USERID))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            snapshot.data == null) {
          return const SizedBox();
        }

        // grabbing the data
        final doc = snapshot.data!.data();

        // grabbing the user level
        final userLevel = doc!['level'];

        // if current level is less than or equals to user level, only then we show the 'fight election from this location' button
        if (widget.level > userLevel) {
          return const SizedBox();
        }

        // grabbing the preferred election location
        final preferredElectionLocation = doc['preferred_election_location'];
        final preferredElectionLocationMap = preferredElectionLocation != null
            ? LocationModel.fromJson(preferredElectionLocation)
            : LocationModel.empty();

        //if no preferred election location is selected and user level matches the current level of welcome location page, we are fighting election from the current location by default
        // or, if preferred election location is selected and this is the preferred location, then we are fighting electing from the current location
        if ((preferredElectionLocationMap.text.isEmpty &&
            int.parse(getPrefValue(Keys.LEVEL)) == widget.level) ||
            preferredElectionLocationMap.text == widget.locationText) {
          return
            AppButton(
              onPressed: () async {
                // if this is the default location and we try to unmark it
                if (preferredElectionLocationMap.text.isEmpty &&
                    int.parse(getPrefValue(Keys.LEVEL)) == widget.level) {
                  showSnackBar(
                    context,
                    message: 'This is your default location and can not be unchecked.',
                    duration: const Duration(seconds: 1),
                  );
                  return;
                }

                await UserService.updateUserWithGivenFields(
                  userId: getPrefValue(Keys.USERID),
                  data: {
                    'preferred_election_location': LocationModel.empty()
                        .toJson(),
                  },
                  navigateToHomeAfterUpdate: false,
                );

                // load the users again
                welcomeController.getTopTenPosts(
                    locationText: widget.locationText, level: widget.level);
              },
              fontSize: 14,
              buttonText: 'Fighting election from this location.',

            );
        } else {
          return AppButtonOutlined(
            onPressed: () async {
              await UserService.updateUserWithGivenFields(
                userId: getPrefValue(Keys.USERID),
                data: {
                  'preferred_election_location': {
                    'id': widget.locationId,
                    'name': widget.locationName,
                    'text': widget.locationText,
                  }
                },
                navigateToHomeAfterUpdate: false,
              );

              welcomeController.getTopTenPosts(
                  locationText: widget.locationText, level: widget.level);
            },
            buttonText: 'Fight election from this location',
          );
          /*Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 15,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 10, top: 10),
                child: OutlinedButton(
                  style: ButtonStyle(
                    side: WidgetStateProperty.all<BorderSide>(
                        BorderSide(color: AppColors.gradient2)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13.0),
                          side: BorderSide(color: AppColors.gradient2)),
                    ),
                    splashFactory: InkRipple.splashFactory,
                    elevation: WidgetStateProperty.all(50),
                    minimumSize: WidgetStateProperty.all(
                        Size(Get.width / 9, 50)),
                    // backgroundColor: MaterialStateProperty.all(Colors.transparent),
                    // elevation: MaterialStateProperty.all(3),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                  onPressed: () async {
                    if(selectedPref != null){
                      await UserService.updateUserWithGivenFields(
                          userId: getPrefValue(Keys.USERID),
                          data: {
                            'preferred_election_location': {
                              'id': selectedPref!.id,
                              'name': selectedPref!.name,
                              'text': selectedPref!.text,
                            }
                          }
                      );
                    }else{
                      await UserService.updateUserWithGivenFields(
                        userId: getPrefValue(Keys.USERID),
                        data: {
                          'preferred_election_location': {
                            'id': widget.locationId,
                            'name': widget.locationName,
                            'text': widget.locationText,
                          }
                        },
                        navigateToHomeAfterUpdate: false,
                      );
                    }


                    welcomeController.getTopTenPosts(
                        locationText: widget.locationText, level: widget.level);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 10,
                        bottom: 10,
                        right: 15,
                        left: 15
                    ),
                    child: Row(

                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Text(
                          'Fight election from this location',
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: AppFonts.Montserrat,

                            // fontWeight: FontWeight.w700,
                            color: AppColors.gradient2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                *//*AppButtonOutlined(
                  onPressed: () async {
                    await UserService.updateUserWithGivenFields(
                      userId: getPrefValue(Keys.USERID),
                      data: {
                        'preferred_election_location': {
                          'id': widget.locationId,
                          'name': widget.locationName,
                          'text': widget.locationText,
                        }
                      },
                      navigateToHomeAfterUpdate: false,
                    );

                    welcomeController.getTopTenPosts(
                        locationText: widget.locationText, level: widget.level);
                  },
                  buttonText: 'Fight election from this location',
                ),*//*
              ),
              OutlinedButton(
                style: ButtonStyle(
                  side: WidgetStateProperty.all<BorderSide>(
                      BorderSide(color: AppColors.gradient2)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13.0),
                        side: BorderSide(color: AppColors.gradient2)),
                  ),
                  splashFactory: InkRipple.splashFactory,
                  elevation: WidgetStateProperty.all(50),
                  minimumSize: WidgetStateProperty.all(
                      Size(Get.width / 9, 50)),
                  // backgroundColor: MaterialStateProperty.all(Colors.transparent),
                  // elevation: MaterialStateProperty.all(3),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                onPressed: () async {
                  List<LocationModel>? list =  await getUserCurrentLocationPref();
                  print('dssss : - ${list!.first.name}');
                  showSelectLocationActionSheet(context,list!);
                },
                child: Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                    ),
                    child: Icon(Icons.arrow_drop_down_circle_outlined,
                      color: AppColors.primaryColor, size: 20,)
                ),
              ),
            ],
          );*/
        }
      },
    );
  }

  Widget commentView() {
    DateTime startOfMonth = DateTime(now.year, now.month);
    DateTime endOfMonth =
    DateTime(now.year, now.month + 1).subtract(Duration(days: 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 10.h),
        Divider(height: 2, color: AppColors.greyTextColor),
        SizedBox(height: 10.h),
        StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection(PRADHAN_DB)
                .doc(widget.locationId)
                .collection(COMMENT_DB)
                .where('createdAt',
                isGreaterThanOrEqualTo: startOfMonth,
                isLessThanOrEqualTo: endOfMonth)
                .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                Center(child: CupertinoActivityIndicator());
              }
              if (!snapshot.hasData) {
                Container();
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 16.0.sp,
                            right: 16.0.sp,
                            top: 16.0.sp,
                            bottom: 0.0.sp),
                        child: CommentCardWidget(
                            commentModel: CommentModel.fromJson(
                                snapshot.data!.docs[index].id,
                                snapshot.data!.docs[index].data())),
                      ),
                    );
                  },
                );
              }
              return Container();
            }),
        Obx(() =>
        !welcomeController.voting.value
            ? const SizedBox()
            : [
          locationModelFromJson(getPrefValue(Keys.POSTAL)).id,
          locationModelFromJson(getPrefValue(Keys.CITY)).id,
          locationModelFromJson(getPrefValue(Keys.STATE)).id,
          "India",
          "1-India"
        ].contains(widget.locationId)
            ? const SizedBox()
            : Text(
          "You can only comment in your location, you will only be able to comment on your level",
          textAlign: TextAlign.center,
        )),
      ],
    );
  }

  Widget commentField() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 5, bottom: 5, top: 10, right: 5),
      height: 60,
      width: double.infinity,
      // color: Colors.black,
      child: Row(
        children: <Widget>[
          Expanded(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    border: Border.all(color: Colors.black54)),
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                      hintText: "Type Here...",
                      border: InputBorder.none,
                      prefix: Text("    "),
                      contentPadding: EdgeInsets.only(bottom: 5.0)),
                ),
              )),
          SizedBox(width: 15),
          InkWell(
            onTap: () {
              // if is guest login, ask to login
              if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
                AppRoutes.navigateToLogin(removeGuestLogin: true);
                return;
              }

              CommentModel commentModel = CommentModel(
                  postId: widget.locationId,
                  commentId: commentController.text,
                  userId: getPrefValue(Keys.USERID),
                  createdAt: Timestamp.now(),
                  comment: commentController.text);
              PradhanService.addCommentPradhanLocation(
                  commentModel: commentModel);
              commentController.text = "";
            },
            child: Icon(
              Icons.send,
              color: AppColors.gradient1,
            ),
          ),
          SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget userArea() {
    return Obx(
          () =>
      welcomeController.isLoading.value
          ? ListView.builder(
        shrinkWrap: true,
        itemCount: 10,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 10),
        itemBuilder: (BuildContext context, int index) {
          return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.only(
                    left: 16.0.sp,
                    right: 16.0.sp,
                    top: 9.0.sp,
                    bottom: 9.0.sp),
                child: userShimmer(),
              ));
        },
      )
          : ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: welcomeController.userList.length,
        padding: EdgeInsets.only(top: 10),
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: UserCard(
              userModel: welcomeController.userList[index],
              upvote: welcomeController.voting.value &&
                  (upvoteCheck() == widget.locationId),
              onVoteUpdateFun: () {
                welcomeController.getTopTenPosts(
                    locationText: widget.locationText,
                    level: widget.level);
              },
            ),
          );
        },
      ),
    );
  }

  // Widget userAreaSnapShoted() {
  //   return StreamBuilder(
  //       stream: VoteService.getHighestUpvotedUsersSnapshot(
  //           widget.locationText, widget.level),
  //       builder: (context, snapshot) {
  //         if (snapshot.hasData) {
  //           return ListView.builder(
  //             shrinkWrap: true,
  //             physics: ClampingScrollPhysics(),
  //             itemCount: snapshot.data!.docs.length,
  //             padding: EdgeInsets.only(top: 10),
  //             itemBuilder: (BuildContext context, int index) {
  //               UserModel userModel =
  //                   UserModel.fromJson(snapshot.data!.docs[index].data());
  //               return Padding(
  //                 padding: EdgeInsets.only(bottom: 10),
  //                 child: UserCard(
  //                   userModel: userModel,
  //                   upvote: welcomeController.voting.value &&
  //                       (upvoteCheck() == widget.locationId),
  //                   // onVoteUpdateFun: () {
  //                   //   welcomeController.getTopTenPosts(
  //                   //       locationText: widget.locationText,
  //                   //       level: widget.level);
  //                   // },
  //                 ),
  //               );
  //             },
  //           );
  //         }

  //         return ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: 10,
  //           padding: EdgeInsets.only(top: 10),
  //           itemBuilder: (BuildContext context, int index) {
  //             return Card(
  //                 shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10)),
  //                 child: Padding(
  //                   padding: EdgeInsets.only(
  //                       left: 16.0.sp,
  //                       right: 16.0.sp,
  //                       top: 9.0.sp,
  //                       bottom: 9.0.sp),
  //                   child: userShimmer(),
  //                 ));
  //           },
  //         );
  //       });
  // }

  String upvoteCheck() {
    switch (widget.level) {
      case 1:
        return locationModelFromJson(getPrefValue(Keys.POSTAL)).id;
      case 2:
        return locationModelFromJson(getPrefValue(Keys.CITY)).id;
      case 3:
        return locationModelFromJson(getPrefValue(Keys.STATE)).id;
      case 4:
        return locationModelFromJson(getPrefValue(Keys.COUNTRY)).id;

      default:
        return locationModelFromJson(getPrefValue(Keys.POSTAL)).id;
    }
  }

  showSelectLocationActionSheet(BuildContext ctx,List<LocationModel> list) {
    showModalBottomSheet(

        context: ctx,
        builder: (context) {
          return SizedBox(
            height: Get.height / 5,
            width: Get.width,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                spacing: 30,

                children: [
                  Text('Change Election Location', style: TextStyle(fontSize: 18,color: AppColors.primaryColor)),
                  AppDropDown(
                      items: list.map((unit){
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(
                            unit.name,
                          ),
                        );
                      }).toList(),
                      onChanged: (e){
                        print('dss :- on the click of select location $e');
                        setState(() {
                          selectedPref = e;
                          Get.back();
                        });
                      },
                    hint : (selectedPref == null) ?  (prefElectionLoc?['name'].isEmpty) ? 'Select Location' : prefElectionLoc!['name'] : selectedPref!.name)
                ],
              ),
            ),
          );
        });
  }
}





















/*
import 'package:chunaw/app/controller/location_features/pradhan_vote_controller.dart';
import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/screen/Location_features/user_card.dart';
import 'package:chunaw/app/screen/Location_features/voting_timer.dart';
import 'package:chunaw/app/screen/home/comment_card.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class VotePradhanScreen extends StatefulWidget {
  const VotePradhanScreen(
      {super.key,
      required this.locationText,
      required this.locationId,
      required this.locationName,
      required this.level});
  final String locationText;
  final String locationId;
  final String locationName;
  final int level;

  @override
  State<VotePradhanScreen> createState() => _VotePradhanScreenState();
}

class _VotePradhanScreenState extends State<VotePradhanScreen> {
  final PradhanVoteController welcomeController =
      Get.put(PradhanVoteController());
  final TextEditingController commentController = TextEditingController();
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    welcomeController.updatevotingStatus(widget.locationId);

    welcomeController.getTopTenPosts(
        locationText: widget.locationText, level: widget.level);
    Future.delayed(Duration(seconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              welcomeController.getTopTenPosts(
                  locationText: widget.locationText, level: widget.level);
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Obx(() => welcomeController.voting.value
                        ? Container()
                        : VotingTimerWidget()),
                    userArea(),
                    commentView(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Obx(
          () => !welcomeController.voting.value
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 20,
                    top: 20,
                  ),
                  child: Text(
                    "Voting is not started yet, you can comment once voting is started",
                    textAlign: TextAlign.center,
                  ),
                )
              : [
                  locationModelFromJson(getPrefValue(Keys.POSTAL)).id,
                  locationModelFromJson(getPrefValue(Keys.CITY)).id,
                  locationModelFromJson(getPrefValue(Keys.STATE)).id,
                  "India",
                  "1-India"
                ].contains(widget.locationId)
                  ? commentField()
                  : const SizedBox(),
        ),
        // if voting is not started and is not a guest, only then show the buttons
        if (!welcomeController.voting.value &&
            !Pref.getBool(Keys.IS_GUEST_LOGIN, false))
          selectPreferredElectionLocationButton(),
      ],
    );
  }

  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>
      selectPreferredElectionLocationButton() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(getPrefValue(Keys.USERID))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError ||
            snapshot.data == null) {
          return const SizedBox();
        }

        // grabbing the data
        final doc = snapshot.data!.data();

        // grabbing the user level
        final userLevel = doc!['level'];

        // if current level is less than or equals to user level, only then we show the 'fight election from this location' button
        if (widget.level > userLevel) {
          return const SizedBox();
        }

        // grabbing the preferred election location
        final preferredElectionLocation = doc['preferred_election_location'];
        final preferredElectionLocationMap = preferredElectionLocation != null
            ? LocationModel.fromJson(preferredElectionLocation)
            : LocationModel.empty();

        //if no preferred election location is selected and user level matches the current level of welcome location page, we are fighting election from the current location by default
        // or, if preferred election location is selected and this is the preferred location, then we are fighting electing from the current location
        if ((preferredElectionLocationMap.text.isEmpty &&
                int.parse(getPrefValue(Keys.LEVEL)) == widget.level) ||
            preferredElectionLocationMap.text == widget.locationText) {
          return AppButton(
            onPressed: () async {
              // if this is the default location and we try to unmark it
              if (preferredElectionLocationMap.text.isEmpty &&
                  int.parse(getPrefValue(Keys.LEVEL)) == widget.level) {
                showSnackBar(
                  context,
                  message: 'This is your default location and can not be unchecked.',
                  duration: const Duration(seconds: 1),
                );
                return;
              }

              await UserService.updateUserWithGivenFields(
                userId: getPrefValue(Keys.USERID),
                data: {
                  'preferred_election_location': LocationModel.empty().toJson(),
                },
                navigateToHomeAfterUpdate: false,
              );

              // load the users again
              welcomeController.getTopTenPosts(locationText: widget.locationText, level: widget.level);
            },
            fontSize: 14,
            buttonText: 'Fighting election from this location.',
          );
        } else {
          return AppButtonOutlined(
            onPressed: () async {
              await UserService.updateUserWithGivenFields(
                userId: getPrefValue(Keys.USERID),
                data: {
                  'preferred_election_location': {
                    'id': widget.locationId,
                    'name': widget.locationName,
                    'text': widget.locationText,
                  }
                },
                navigateToHomeAfterUpdate: false,
              );

              welcomeController.getTopTenPosts(
                  locationText: widget.locationText, level: widget.level);
            },
            buttonText: 'Fight election from this location',
          );
        }
      },
    );
  }

  Widget commentView() {
    DateTime startOfMonth = DateTime(now.year, now.month);
    DateTime endOfMonth =
        DateTime(now.year, now.month + 1).subtract(Duration(days: 1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 10.h),
        Divider(height: 2, color: AppColors.greyTextColor),
        SizedBox(height: 10.h),
        StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection(PRADHAN_DB)
                .doc(widget.locationId)
                .collection(COMMENT_DB)
                .where('createdAt',
                    isGreaterThanOrEqualTo: startOfMonth,
                    isLessThanOrEqualTo: endOfMonth)
                .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                Center(child: CupertinoActivityIndicator());
              }
              if (!snapshot.hasData) {
                Container();
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 16.0.sp,
                            right: 16.0.sp,
                            top: 16.0.sp,
                            bottom: 0.0.sp),
                        child: CommentCardWidget(
                            commentModel: CommentModel.fromJson(
                                snapshot.data!.docs[index].id,
                                snapshot.data!.docs[index].data())),
                      ),
                    );
                  },
                );
              }
              return Container();
            }),
        Obx(() => !welcomeController.voting.value
            ? const SizedBox()
            : [
                locationModelFromJson(getPrefValue(Keys.POSTAL)).id,
                locationModelFromJson(getPrefValue(Keys.CITY)).id,
                locationModelFromJson(getPrefValue(Keys.STATE)).id,
                "India",
                "1-India"
              ].contains(widget.locationId)
                ? const SizedBox()
                : Text(
                    "You can only comment in your location, you will only be able to comment on your level",
                    textAlign: TextAlign.center,
                  )),
      ],
    );
  }

  Widget commentField() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(left: 5, bottom: 5, top: 10, right: 5),
      height: 60,
      width: double.infinity,
      // color: Colors.black,
      child: Row(
        children: <Widget>[
          Expanded(
              child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.black54)),
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                  hintText: "Type Here...",
                  border: InputBorder.none,
                  prefix: Text("    "),
                  contentPadding: EdgeInsets.only(bottom: 5.0)),
            ),
          )),
          SizedBox(width: 15),
          InkWell(
            onTap: () {
              // if is guest login, ask to login
              if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
                AppRoutes.navigateToLogin(removeGuestLogin: true);
                return;
              }

              CommentModel commentModel = CommentModel(
                  postId: widget.locationId,
                  commentId: commentController.text,
                  userId: getPrefValue(Keys.USERID),
                  createdAt: Timestamp.now(),
                  comment: commentController.text);
              PradhanService.addCommentPradhanLocation(
                  commentModel: commentModel);
              commentController.text = "";
            },
            child: Icon(
              Icons.send,
              color: AppColors.gradient1,
            ),
          ),
          SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget userArea() {
    return Obx(
      () => welcomeController.isLoading.value
          ? ListView.builder(
              shrinkWrap: true,
              itemCount: 10,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 10),
              itemBuilder: (BuildContext context, int index) {
                return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: 16.0.sp,
                          right: 16.0.sp,
                          top: 9.0.sp,
                          bottom: 9.0.sp),
                      child: userShimmer(),
                    ));
              },
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: welcomeController.userList.length,
              padding: EdgeInsets.only(top: 10),
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: UserCard(
                    userModel: welcomeController.userList[index],
                    upvote: welcomeController.voting.value &&
                        (upvoteCheck() == widget.locationId),
                    onVoteUpdateFun: () {
                      welcomeController.getTopTenPosts(
                          locationText: widget.locationText,
                          level: widget.level);
                    },
                  ),
                );
              },
            ),
    );
  }

  // Widget userAreaSnapShoted() {
  //   return StreamBuilder(
  //       stream: VoteService.getHighestUpvotedUsersSnapshot(
  //           widget.locationText, widget.level),
  //       builder: (context, snapshot) {
  //         if (snapshot.hasData) {
  //           return ListView.builder(
  //             shrinkWrap: true,
  //             physics: ClampingScrollPhysics(),
  //             itemCount: snapshot.data!.docs.length,
  //             padding: EdgeInsets.only(top: 10),
  //             itemBuilder: (BuildContext context, int index) {
  //               UserModel userModel =
  //                   UserModel.fromJson(snapshot.data!.docs[index].data());
  //               return Padding(
  //                 padding: EdgeInsets.only(bottom: 10),
  //                 child: UserCard(
  //                   userModel: userModel,
  //                   upvote: welcomeController.voting.value &&
  //                       (upvoteCheck() == widget.locationId),
  //                   // onVoteUpdateFun: () {
  //                   //   welcomeController.getTopTenPosts(
  //                   //       locationText: widget.locationText,
  //                   //       level: widget.level);
  //                   // },
  //                 ),
  //               );
  //             },
  //           );
  //         }

  //         return ListView.builder(
  //           shrinkWrap: true,
  //           physics: NeverScrollableScrollPhysics(),
  //           itemCount: 10,
  //           padding: EdgeInsets.only(top: 10),
  //           itemBuilder: (BuildContext context, int index) {
  //             return Card(
  //                 shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10)),
  //                 child: Padding(
  //                   padding: EdgeInsets.only(
  //                       left: 16.0.sp,
  //                       right: 16.0.sp,
  //                       top: 9.0.sp,
  //                       bottom: 9.0.sp),
  //                   child: userShimmer(),
  //                 ));
  //           },
  //         );
  //       });
  // }

  String upvoteCheck() {
    switch (widget.level) {
      case 1:
        return locationModelFromJson(getPrefValue(Keys.POSTAL)).id;
      case 2:
        return locationModelFromJson(getPrefValue(Keys.CITY)).id;
      case 3:
        return locationModelFromJson(getPrefValue(Keys.STATE)).id;
      case 4:
        return locationModelFromJson(getPrefValue(Keys.COUNTRY)).id;

      default:
        return locationModelFromJson(getPrefValue(Keys.POSTAL)).id;
    }
  }
}
*/
