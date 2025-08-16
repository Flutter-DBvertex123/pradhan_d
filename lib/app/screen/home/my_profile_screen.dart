import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/controller/home/profile_controller.dart';
import 'package:chunaw/app/models/followers_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/screen/home/post_card.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/widgets/app_drawer.dart';
import 'package:chunaw/app/widgets/app_shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';
// ignore: depend_on_referenced_packages

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({Key? key, required this.userId, required this.back})
      : super(key: key);
  final String userId;
  final bool back;

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ProfileController profileController = Get.put(ProfileController());
  UserModel? userModel;
  bool loading = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      // if scroll controller reaches bottom, load another set of data
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {
        // getting the next set of posts if we are not already loading
        if (!profileController.isLoading.value) {
          profileController.getPosts(
            nextSet: true,
          );
        }
      }
    });

    profileController.userId = widget.userId;
    profileController.getPosts();
    getUserModel();
  }

  getUserModel() async {
    userModel = await UserService.getUserData(widget.userId);
    setState(() {
      loading = false;
    });
  }

  // list of post ids along with their timers
  final List<Map> postIdsWithViewUpdateTimers = [];

  // already seen post ids
  final Set<String> alreadySeenPostIds = {};

  @override
  Widget build(BuildContext context) {
    print('is loading: ${profileController.isLoading.value}');
    print('last doc is null: ${profileController.lastDoc == null}');

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
      appBar: AppBarCustom(
        leadingBack: true,
        title: widget.userId != getPrefValue(Keys.USERID)
            ? 'Profile'
            : 'My Profile',
        scaffoldKey: !widget.back ? _scaffoldKey : null,
        elevation: 0,
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(color: AppColors.white),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Image.asset(
                                      AppAssets.bannerImage,
                                      width: double.infinity,
                                      fit: BoxFit.fitWidth,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -70,
                                    left: 20,
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 55.r,
                                          backgroundColor:
                                              AppColors.white.withOpacity(0.3),
                                          child: Center(
                                            child: CircleAvatar(
                                              radius: 50.r,
                                              backgroundColor:
                                                  AppColors.gradient1,
                                              child: ClipOval(
                                                clipBehavior: Clip.hardEdge,
                                                child: loading
                                                    ? CircleAvatar(
                                                        radius: 55.r,
                                                        backgroundColor:
                                                            AppColors.gradient1,
                                                        child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                          color: AppColors
                                                              .highlightColor,
                                                        )),
                                                      )
                                                    : CachedNetworkImage(
                                                        placeholder:
                                                            (context, error) {
                                                          // printError();
                                                          return CircleAvatar(
                                                            radius: 55.r,
                                                            backgroundColor:
                                                                AppColors
                                                                    .gradient1,
                                                            child: Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                              color: AppColors
                                                                  .highlightColor,
                                                            )),
                                                          );
                                                        },
                                                        errorWidget: (context,
                                                            error, stackTrace) {
                                                          // printError();
                                                          return Image.asset(
                                                            AppAssets
                                                                .brokenImage,
                                                            fit: BoxFit
                                                                .fitHeight,
                                                            // width: 160.0,
                                                            height: 122.0,
                                                          );
                                                        },
                                                        imageUrl:
                                                            userModel!.image,
                                                        // .replaceAll('\', '//'),
                                                        fit: BoxFit.cover,
                                                        // width: 160.0,
                                                        height: 160.0,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (userModel!
                                            .affiliateImage.isNotEmpty)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              height: 40.w,
                                              width: 40.w,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(50.r),
                                                color: Color(0xFF1A1A1A),
                                                border: Border.all(
                                                    width: 1.5,
                                                    color: Colors.white),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(50.r),
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      userModel!.affiliateImage,
                                                  errorWidget:
                                                      (context, url, error) {
                                                    return Image.asset(
                                                      AppAssets.brokenImage,
                                                      fit: BoxFit.fitHeight,
                                                      height: 30.0,
                                                    );
                                                  },
                                                  placeholder: (context, url) {
                                                    return CircleAvatar(
                                                      radius: 20.r,
                                                      backgroundColor:
                                                          AppColors.gradient1,
                                                      child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                        color: AppColors
                                                            .highlightColor,
                                                      )),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 85.h),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    loading
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              shimmerWidget(
                                                child: Container(
                                                  height: 9,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.baseColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  width: Get.width * 0.5,
                                                ),
                                              ),
                                              SizedBox(height: 5.h),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  shimmerWidget(
                                                    child: Container(
                                                      height: 9,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.baseColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                      ),
                                                      width: Get.width * 0.2,
                                                    ),
                                                  ),
                                                  SizedBox(width: 20.w),
                                                  shimmerWidget(
                                                    child: Container(
                                                      height: 9,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.baseColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                      ),
                                                      width: Get.width * 0.2,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // if no affiliate text is there then don't show this label
                                              if (userModel!.affiliateText
                                                      .isNotEmpty &&
                                                  !userModel!.isOrganization)
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 1.w,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withOpacity(.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    userModel!.affiliateText,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              SizedBox(
                                                height: 5.h,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    userModel!.name,
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                        color: Color.fromRGBO(
                                                            1, 1, 1, 1),
                                                        fontFamily:
                                                            'Montserrat',
                                                        fontSize: 16,
                                                        letterSpacing:
                                                            0 /*percentages not used in flutter. defaulting to zero*/,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1),
                                                  ),
                                                  SizedBox(
                                                    width: 5.w,
                                                  ),

                                                  // showing the organization label if it is an organization
                                                  if (userModel!.isOrganization)
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryColor,
                                                        borderRadius: BorderRadius.circular(50),
                                                      ),
                                                      child: Text(
                                                        'ORGANIZATION',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontFamily:
                                                              'Montserrat',
                                                          height: 1,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ) else
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          //color: Colors.black54,
                                                          borderRadius: BorderRadius.circular(4)
                                                      ),

                                                      child: Padding(
                                                        // Added padding for better spacing inside the card
                                                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                                        child: StreamBuilder<
                                                            DocumentSnapshot>(
                                                          stream: FirebaseFirestore.instance.collection(USER_DB).doc(userModel!.id).snapshots(),
                                                          builder: (context, snapshot) {
                                                            // Display a loading spinner when data is loading
                                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                                              return Center(
                                                                  child: Text(
                                                                    'Fetching...',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                        12,
                                                                        color: Colors
                                                                            .white),
                                                                  )
                                                              );
                                                            }
                                                            if (snapshot
                                                                .hasError ||
                                                                !snapshot
                                                                    .hasData ||
                                                                snapshot.data ==
                                                                    null) {
                                                              return Text(
                                                                'Something went wrong!',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                    12,
                                                                    color: Colors
                                                                        .white),
                                                              );
                                                            }

                                                            // Fetch the data
                                                            final mapData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                                            return Row(
                                                              spacing: 3,
                                                              children: [
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors.black54,
                                                                borderRadius: BorderRadius.circular(4)),
                                                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                                              child: Text(
                                                              '${mapData['upvote_count'] ?? 0} Votes',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),Container(
                                                                  decoration: BoxDecoration(
                                                                      color: Colors.black54,
                                                                      borderRadius: BorderRadius.circular(4)),
                                                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                                              child: Text(
                                                              '${mapData['weekly_vote'] ?? 0} Weekly Votes',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                              ],
                                                            );

                                                            /*return Text(
                                                              '${mapData['upvote_count'] ?? 0} Votes',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            );*/
                                                          },
                                                        ),
                                                      ),
                                                    )
                                                ],
                                              ),
                                              SizedBox(
                                                height: 5.h,
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '@${userModel!.username}',
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                        color: Color.fromRGBO(
                                                            1, 1, 1, 1),
                                                        fontFamily:
                                                            'Montserrat',
                                                        fontSize: 12,
                                                        letterSpacing:
                                                            0 /*percentages not used in flutter. defaulting to zero*/,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        height: 1),
                                                  ),
                                                  SizedBox(width: 10.w),
                                                  StreamBuilder(
                                                    stream: FirebaseFirestore
                                                        .instance
                                                        .collection(USER_DB)
                                                        .doc(userModel!.id)
                                                        .collection(
                                                            FOLLOWERS_DB)
                                                        .snapshots(),
                                                    builder: (context,
                                                        AsyncSnapshot
                                                            snapshot) {
                                                      return

                                                        Container(
                                                        child: Text(
                                                          "${snapshot.data != null ? snapshot.data!.docs.length : 0} Followers",
                                                          textAlign:
                                                              TextAlign.left,
                                                          style: TextStyle(
                                                              color: Color
                                                                  .fromRGBO(1,
                                                                      1, 1, 1),
                                                              fontFamily:
                                                                  'Montserrat',
                                                              fontSize: 12,
                                                              letterSpacing:
                                                                  0 /*percentages not used in flutter. defaulting to zero*/,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              height: 1),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  SizedBox(
                                                    width: 10.w,
                                                  ),


                                                  // Container(
                                                  //   width: 120,
                                                  //   child: Column(
                                                  //     mainAxisAlignment: MainAxisAlignment.center,
                                                  //     crossAxisAlignment: CrossAxisAlignment.center,
                                                  //     children: [
                                                  //       Card(
                                                  //
                                                  //         // shadowColor: Colors.grey,
                                                  //         color: Colors.redAccent,
                                                  //         elevation: 2,
                                                  //         child: Container(
                                                  //           //color: Colors.teal,
                                                  //           // padding:
                                                  //           //     const EdgeInsets.symmetric(
                                                  //           //         horizontal: 15),
                                                  //           alignment:
                                                  //               Alignment.center,
                                                  //           child: StreamBuilder(
                                                  //             stream: FirebaseFirestore
                                                  //                 .instance
                                                  //                 .collection(USER_DB)
                                                  //                 .doc(userModel!.id)
                                                  //                 .snapshots(),
                                                  //             builder:
                                                  //                 (context, snapshot) {
                                                  //               // if loading
                                                  //               if (snapshot
                                                  //                       .connectionState ==
                                                  //                   ConnectionState
                                                  //                       .waiting) {
                                                  //                 return const SizedBox();
                                                  //               }
                                                  //
                                                  //               // grabbing the data
                                                  //               final data =
                                                  //                   snapshot.data;
                                                  //
                                                  //               // if there is an error
                                                  //               if (snapshot.hasError ||
                                                  //                   data == null) {
                                                  //                 return Text(
                                                  //                   'Something went wrong!',
                                                  //                   style: TextStyle(
                                                  //                       fontSize: 12),
                                                  //                 );
                                                  //               }
                                                  //
                                                  //               // grabbing the map data
                                                  //               final mapData =
                                                  //                   data.data() ?? {};
                                                  //
                                                  //               print(mapData);
                                                  //
                                                  //               return Row(
                                                  //                 crossAxisAlignment: CrossAxisAlignment.center,
                                                  //                 children: [
                                                  //                   SizedBox(
                                                  //                     height: 13,
                                                  //                     child: Image.asset(
                                                  //                         AppAssets
                                                  //                             .voteImage),
                                                  //                   ),
                                                  //                   const SizedBox(
                                                  //                     width: 5,
                                                  //                   ),
                                                  //                   Text(
                                                  //                     '${mapData['upvote_count'] ?? 0} Votes',
                                                  //                     style: TextStyle(
                                                  //                       fontSize: 12,
                                                  //                     ),
                                                  //                   ),
                                                  //                 ],
                                                  //               );
                                                  //             },
                                                  //           ),
                                                  //         ),
                                                  //       ),
                                                  //     ],
                                                  //   ),
                                                  // ),
                                                ],
                                              ),
                                            ],
                                          ),
                                    Flexible(
                                      child: widget.userId !=
                                              getPrefValue(Keys.USERID)
                                          ? StreamBuilder(
                                              stream: FirebaseFirestore.instance
                                                  .collection(USER_DB)
                                                  .doc(widget.userId)
                                                  .collection(FOLLOWERS_DB)
                                                  .where("follower_id",
                                                      isEqualTo: getPrefValue(
                                                          Keys.USERID))
                                                  .snapshots(),
                                              builder: (context,
                                                  AsyncSnapshot snapshot) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    if (Pref.getBool(
                                                        Keys.IS_GUEST_LOGIN,
                                                        false)) {
                                                      AppRoutes
                                                          .navigateToLogin();
                                                      return;
                                                    }

                                                    // print("follow");
                                                    if (snapshot.data != null &&
                                                        snapshot.data!.docs
                                                            .isEmpty) {
                                                      // print("follow add");
                                                      FollowerModel
                                                          followerModel =
                                                          FollowerModel(
                                                              followerId:
                                                                  FirebaseAuth
                                                                      .instance
                                                                      .currentUser!
                                                                      .uid,
                                                              followeeId:
                                                                  userModel!.id,
                                                              createdAt:
                                                                  Timestamp
                                                                      .now());
                                                      UserService.addFollowers(
                                                          followerModel:
                                                              followerModel);
                                                    } else {
                                                      // print("follow delete");
                                                      UserService
                                                          .deleteFollowers(
                                                              followId: snapshot
                                                                  .data!
                                                                  .docs[0]
                                                                  .id,
                                                              userId: userModel!
                                                                  .id);
                                                    }
                                                  },
                                                  child: Container(
                                                    // width: 40,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: AppColors
                                                                .greyTextColor,
                                                            width: 2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15)),
                                                    // alignment: Alignment.center,
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 15.0,
                                                          vertical: 6),
                                                      child: Text(
                                                        snapshot.data != null &&
                                                                snapshot
                                                                    .data!
                                                                    .docs
                                                                    .isNotEmpty
                                                            ? userModel!
                                                                    .isOrganization
                                                                ? "Joined"
                                                                : "Following"
                                                            : userModel!
                                                                    .isOrganization
                                                                ? "Join"
                                                                : "Follow",
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .greyTextColor),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              })
                                          : InkWell(
                                              onTap: () {
                                                AppRoutes
                                                    .navigateToProfileUpdate();
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  // boxShadow: [
                                                  //   BoxShadow(
                                                  //       color: AppColors.gradient1,
                                                  //       offset: Offset(4, 4),
                                                  //       blurRadius: 15.0),
                                                  //   BoxShadow(
                                                  //       color: AppColors.gradient2,
                                                  //       offset: Offset(4, 4),
                                                  //       blurRadius: 15.0)
                                                  // ],
                                                  gradient: LinearGradient(
                                                    begin: Alignment(
                                                        -0.35, -1.272),
                                                    end: Alignment(0.84, 0.87),
                                                    colors: [
                                                      AppColors.gradient1,
                                                      AppColors.gradient2
                                                    ],
                                                    stops: [0.0, 1.0],
                                                  ),
                                                  // color: AppColors.primaryColor,
                                                  shape: BoxShape.circle,
                                                  // borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Icon(
                                                    Icons.edit,
                                                    size: 25,
                                                    color: AppColors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.h),
                              loading
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          shimmerWidget(
                                            child: Container(
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: AppColors.baseColor,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              width: Get.width,
                                            ),
                                          ),
                                          SizedBox(height: 5.h),
                                          shimmerWidget(
                                            child: Container(
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: AppColors.baseColor,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              width: Get.width,
                                            ),
                                          ),
                                          SizedBox(height: 5.h),
                                          shimmerWidget(
                                            child: Container(
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: AppColors.baseColor,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              width: Get.width * 0.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24.0),
                                      child: Text(
                                        userModel!.userdesc,
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            color:
                                                Color.fromRGBO(51, 51, 51, 1),
                                            fontFamily: 'Montserrat',
                                            fontSize: 13,
                                            letterSpacing:
                                                0 /*percentages not used in flutter. defaulting to zero*/,
                                            fontWeight: FontWeight.normal,
                                            height: 1.5),
                                      ),
                                    ),
                              SizedBox(height: 18.h),
                              if (userModel!.isOrganization)
                                Container(
                                  width: 20,
                                  height: 2,
                                  color: AppColors.baseColor,
                                ),
                              if (userModel!.isOrganization)
                                SizedBox(
                                  height: 18.h,
                                ),
                              if (userModel!.isOrganization)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 2,
                                      ),
                                      Text(userModel!.organizationAddress),
                                    ],
                                  ),
                                ),
                              if (userModel!.isOrganization)
                                SizedBox(
                                  height: 18.h,
                                ),
                              Container(
                                color: AppColors.baseColor,
                                child: Obx(
                                  () => profileController.isLoading.value &&
                                          profileController.lastDoc == null
                                      ? ListView.builder(
                                          itemCount: 10,
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.only(top: 10),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return PostShimmer();
                                          },
                                        )
                                      : RefreshIndicator(
                                          onRefresh: () async {
                                            profileController.getPosts();
                                          },
                                          child: SingleChildScrollView(
                                            padding: EdgeInsets.only(top: 10),
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            child: Column(
                                              children: List.generate(
                                                profileController
                                                    .postList.length,
                                                (index) => Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: index + 1 ==
                                                            profileController
                                                                .postList.length
                                                        ? 100
                                                        : 0,
                                                  ),
                                                  child: VisibilityDetector(
                                                    key: ValueKey(
                                                        profileController
                                                            .postList[index]
                                                            .postId),
                                                    onVisibilityChanged:
                                                        (info) {
                                                      onVisibilityChanged(
                                                        info,
                                                        profileController
                                                            .postList[index],
                                                      );
                                                    },
                                                    child: PostCard(
                                                      tabIndex: null,
                                                      postModel:
                                                          profileController
                                                              .postList[index],
                                                      onDeleteCompleted: () {
                                                        setState(() {
                                                          profileController
                                                              .postList
                                                              .removeAt(index);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // if profile controller is loading and last doc is not null then we are loading some posts
                Obx(
                  () => (profileController.isLoading.value &&
                          profileController.lastDoc != null)
                      ? LinearProgressIndicator(
                          color: AppColors.primaryColor,
                          backgroundColor:
                              AppColors.primaryColor.withOpacity(.5),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
    );
  }

  void onVisibilityChanged(VisibilityInfo info, PostModel postModel) {
    // if there already is a timer running with this post id, cancel that and remove that record
    final Map? foundExisting = postIdsWithViewUpdateTimers
        .firstWhereOrNull((element) => element['postId'] == postModel.postId);

    if (foundExisting != null) {
      // cancel the timer and remove the record
      foundExisting['timer'].cancel();

      postIdsWithViewUpdateTimers
          .removeWhere((element) => element['postId'] == postModel.postId);
    }

    // create a new timer
    final timer = Timer(
      const Duration(seconds: 5),
      () {
        // if the post is more than 90% visible
        if (info.visibleFraction > .9) {
          // if the post is already seen, ignore
          if (alreadySeenPostIds.contains(postModel.postId)) {
            return;
          }

          // update the count in the DB
          FirebaseFirestore.instance
              .collection(POST_DB)
              .doc(postModel.postId)
              .set(
            {
              'views_count': FieldValue.increment(1),
            },
            SetOptions(merge: true),
          ).then((value) {
            // updaing already seen post ids
            alreadySeenPostIds.add(postModel.postId);
          });
        } else if (info.visibleFraction < .1) {
          // remove the current post id from the seen post ids
          alreadySeenPostIds
              .removeWhere((element) => element == postModel.postId);

          // remove the timer ref
          postIdsWithViewUpdateTimers.removeWhere(
            (element) => element['postId'] == postModel.postId,
          );
        }
      },
    );

    // adding the timer in the list
    postIdsWithViewUpdateTimers.add(
      {
        'postId': postModel.postId,
        'timer': timer,
      },
    );
  }
}
