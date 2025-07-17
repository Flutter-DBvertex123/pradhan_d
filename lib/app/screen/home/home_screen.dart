import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:chunaw/app/controller/home/home_controller.dart';
import 'package:chunaw/app/controller/home/welcome_location_controller.dart';
import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/screen/Location_features/pradhan_status_card.dart';
import 'package:chunaw/app/screen/home/location_bottom_sheet.dart';
import 'package:chunaw/app/screen/home/post_card.dart';
import 'package:chunaw/app/screen/home/select_states_screen.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/polls_service.dart';
import 'package:chunaw/app/service/post_service.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:chunaw/app/service/sachiv_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/enums.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_drawer.dart';
import 'package:chunaw/app/widgets/app_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../dbvertex/widgets/AdCard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(this._controller, {Key? key}) : super(key: key);

  final TabController _controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  // scroll controller for the list view of posts
  final ScrollController _scrollController = ScrollController();

  // welcome location controller
  final welcomeController = Get.put(WelcomeLocationController());

  @override
  void initState() {
    super.initState();
    tabController = widget._controller;

    _scrollController.addListener(() {
      // if scroll controller reaches bottom, load another set of data
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {
        // getting the next set of posts if we are not already loading
        if (!homeController.isLoading.value) {
          homeController.getPosts(
            tabController.index,
            nextSet: true,
          );
        }
      }
    });

    tabController.addListener(() {
      // loading pradhan details
      setState(() {
        isLoadingPradhanDetails = true;
      });

      loadPradhanDetails().then((value) => setState(() {
            isLoadingPradhanDetails = false;
          }));
    });
  }

  // whether we are loading pradhaan details or not
  bool isLoadingPradhanDetails = false;

  Future<void> loadPradhanDetails() async {
    await PradhanService.addImpDetailInPradhan(
        docId: getLatestWelcomeScreenLocId(),
        locationName: getLatestWelcomeScreenName(),
        locationText: getLatestWelcomeScreenText(),
        level: tabController.index);
    await welcomeController.getPradhanId(getLatestWelcomeScreenLocId());
    print("Pradhan ID: ${welcomeController.pradhanId}");
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
  }

  final HomeController homeController = Get.put(HomeController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // list of post ids along with their timers
  final List<Map> postIdsWithViewUpdateTimers = [];

  // already seen post ids
  final Set<String> alreadySeenPostIds = {};

  @override
  Widget build(BuildContext context) {
    final isCurrentUserPradhaan =
        welcomeController.pradhanId.value.isNotEmpty &&
            welcomeController.pradhanId.value == getPrefValue(Keys.USERID);

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onStatePreferenceUpdated: () {
          if (tabController.index == 0) {
            homeController.getPosts(tabController.index);
          }
        },
      ),
      backgroundColor: AppColors.scaffoldBgColor,
      appBar: AppBarCustom(
        showSearch: true,
        title: '',
        scaffoldKey: _scaffoldKey,
        bottom: Theme(
          data: ThemeData(
              primarySwatch: getMaterialColor(AppColors.primaryColor)),
          child: TabBar(
              controller: tabController,
              onTap: (index) {
                switch (index) {
                  case 0:
                    homeController.filterby.value = 1;
                    break;
                  case 1:
                    homeController.filterby.value = 1;
                    SachivService.addImpDetailInSachiv(
                        docId: getLatestWelcomeScreenLocId(),
                        locationName: getLatestWelcomeScreenText(),
                        level: 1);
                    break;
                  case 2:
                    homeController.filterby.value = 2;
                    SachivService.addImpDetailInSachiv(
                        docId: getLatestWelcomeScreenLocId(),
                        locationName: getLatestWelcomeScreenText(),
                        level: 2);
                    break;
                  case 3:
                    homeController.filterby.value = 3;
                    SachivService.addImpDetailInSachiv(
                        docId: getLatestWelcomeScreenLocId(),
                        locationName: getLatestWelcomeScreenText(),
                        level: 3);
                    break;
                  case 4:
                    homeController.filterby.value = 4;
                    SachivService.addImpDetailInSachiv(
                        docId: getLatestWelcomeScreenLocId(),
                        locationName: getLatestWelcomeScreenText(),
                        level: 4);
                    break;
                  default:
                    homeController.filterby.value = 1;
                    break;
                }
                setState(() {});
                homeController.getPosts(index);
                homeController.getSachiv(index);
              },
              physics: ClampingScrollPhysics(),
              labelPadding: EdgeInsets.symmetric(horizontal: 5),
              indicatorColor: AppColors.black,
              unselectedLabelStyle: TextStyle(
                  color: AppColors.black,
                  fontFamily: 'Montserrat',
                  fontSize: 14.sp,
                  letterSpacing:
                      0 /*percentages not used in flutter. defaulting to zero*/,
                  fontWeight: FontWeight.normal,
                  height: 1),
              unselectedLabelColor: AppColors.black,
              labelColor: AppColors.black,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: "Home"),
                // Obx(() => Tab(text: homeController.selectedPostal.value.text)),
                Tab(
                    text:
                        locationModelFromJson(getPrefValue(Keys.POSTAL)).text),
                Tab(text: locationModelFromJson(getPrefValue(Keys.CITY)).text),
                Tab(text: locationModelFromJson(getPrefValue(Keys.STATE)).text),
                Tab(
                    text:
                        locationModelFromJson(getPrefValue(Keys.COUNTRY)).text),
              ]),
        ),
      ),
      body: Column(
        children: [
          Column(
            children: [
              SizedBox(height: tabController.index == 0 ? 10.h : 15.h),
              if (tabController.index != 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 10,
                    spacing: 10,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final reload = await AppRoutes.navigateToWelcomePage(
                            getLatestWelcomeScreenName(),
                            getLatestWelcomeScreenLocId(),
                            getLatestWelcomeScreenText(),
                            getLatestLevel(),
                            tabController.index == 0,
                          );

                          if (reload) {
                            setState(() {
                              homeController.getPosts(tabController.index);
                            });
                          }
                        },
                        child: Container(
                          // width: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.black),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey
                                    .withOpacity(0.5), // Shadow color
                                spreadRadius: 2, // Spread radius
                                blurRadius: 5, // Blur radius
                                offset: Offset(0, 3), // Offset from the top
                              ),
                            ],
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(15),
                          ),

                          // alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, right: 10, bottom: 3, top: 3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Obx(
                                  () => Text(
                                    getFilteredText(homeController
                                        .filterby.value), //filter text here
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Image.asset(
                                  AppAssets.voteActiveImage,
                                  height: 18,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (getPollsFuture() != null)
                        StreamBuilder(
                          stream: getPollsFuture(),
                          builder: (context, snapshot) {
                            // if it is loading or there was an error or the data is null
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                snapshot.hasError ||
                                snapshot.data == null) {
                              return const SizedBox();
                            }

                            // grabbing the documents
                            final docs = snapshot.data!.docs;

                            // if docs are empty, return
                            if (docs.isEmpty) {
                              return const SizedBox();
                            }

                            // sorting the polls
                            docs.sort((a, b) =>
                                a['created_at'].compareTo(b['created_at']) *
                                -1);

                            return GestureDetector(
                              onTap: () async {
                                showModalBottomSheetForPolls(docs);
                              },
                              child: Icon(
                                Icons.poll_outlined,
                                color: Colors.black,
                                size: 22,
                              ),
                            );
                          },
                        ),
                      // if (tabController.index != 0)
                      //   Obx(
                      //     () => homeController.areaSachiv.value.id != ""
                      //         ? Padding(
                      //             padding: EdgeInsets.symmetric(horizontal: 10),
                      //             child: SachivProfileCard(
                      //                 userModel: homeController.areaSachiv.value),
                      //           )
                      //         : Container(),
                      //   ),
                      // getFilterWidget(),
                      // Obx(
                      //   () => welcomeController.pradhanId.value ==
                      //           getPrefValue(Keys.USERID)
                      //       ? GestureDetector(
                      //           onTap: () async {
                      //             AppRoutes.navigateToCreatePollPage(
                      //                 tabController.index);
                      //           },
                      //           child: Container(
                      //             // width: 40,
                      //             decoration: BoxDecoration(
                      //               border: Border.all(color: AppColors.black),
                      //               boxShadow: [
                      //                 BoxShadow(
                      //                   color: Colors.grey
                      //                       .withOpacity(0.5), // Shadow color
                      //                   spreadRadius: 2, // Spread radius
                      //                   blurRadius: 5, // Blur radius
                      //                   offset:
                      //                       Offset(0, 3), // Offset from the top
                      //                 ),
                      //               ],
                      //               color: AppColors.primaryColor,
                      //               borderRadius: BorderRadius.circular(15),
                      //             ),

                      //             // alignment: Alignment.center,
                      //             child: Padding(
                      //               padding: const EdgeInsets.only(
                      //                   left: 10.0,
                      //                   right: 10,
                      //                   bottom: 3,
                      //                   top: 3),
                      //               child: Row(
                      //                 mainAxisSize: MainAxisSize.min,
                      //                 children: [
                      //                   Text(
                      //                     'Create Poll',
                      //                     style: TextStyle(
                      //                       fontSize: 12,
                      //                       color: Colors.white,
                      //                     ),
                      //                   ),
                      //                   const SizedBox(
                      //                     width: 5,
                      //                   ),
                      //                   Icon(
                      //                     Icons.edit,
                      //                     color: Colors.white,
                      //                     size: 15,
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //           ),
                      //         )
                      //       : const SizedBox(),
                      // )
                    ],
                  ),
                ),
            ],
          ),
          (getPrefValue(Keys.PREFERRED_STATES).isEmpty ||
                      jsonDecode(getPrefValue(Keys.PREFERRED_STATES))
                          .isEmpty) &&
                  tabController.index == 0
              ? Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'Please choose your Preferred States',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'We will only show you posts from the selected states.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                                builder: (context) => SelectStatesScreen()),
                          )
                              .then(
                            (value) {
                              // once we are done selecting the states, getting the posts for the home
                              if (value) {
                                setState(() {
                                  homeController.getPosts(0);
                                });
                              }
                            },
                          );
                        },
                        child: Text('Continue'),
                      ),
                    ],
                  ),
                )
              : Expanded(
                  child: Obx(
                    () => homeController.isLoading.value &&
                            homeController.lastDoc == null
                        ? ListView.builder(
                            itemCount: 10,
                            padding: EdgeInsets.only(top: 10),
                            itemBuilder: (BuildContext context, int index) {
                              return PostShimmer();
                            },
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () async {
                                    print(
                                        'getting posts for level: ${tabController.index}');
                                    homeController
                                        .getPosts(tabController.index);
                                    homeController
                                        .getSachiv(tabController.index);
                                  },
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.only(top: 10),
                                    controller: _scrollController,
                                    child: Column(
                                      children: [
                                        if (!isLoadingPradhanDetails &&
                                            tabController.index != 0)
                                          PradhanStatusCard(
                                              locationId:
                                                  getLatestWelcomeScreenLocId()),
                                        if (welcomeController
                                            .pinpostModel.value.showlevel
                                            .contains(tabController.index))
                                          welcomeController.pinpostModel.value
                                                      .postId !=
                                                  ""
                                              ? VisibilityDetector(
                                                  key: ValueKey(
                                                      welcomeController
                                                          .pinpostModel
                                                          .value
                                                          .postId),
                                                  onVisibilityChanged: (info) {
                                                    onVisibilityChanged(
                                                      info,
                                                      welcomeController
                                                          .pinpostModel.value,
                                                    );
                                                  },
                                                  child: PostCard(
                                                    postModel: welcomeController
                                                        .pinpostModel.value,
                                                    tabIndex:
                                                        tabController.index,
                                                    pinned: true,
                                                    postOption:
                                                        isCurrentUserPradhaan
                                                            ? PostOption.pradhan
                                                            : PostOption.none,
                                                    updateLevelCallback: () {
                                                      homeController.getPosts(
                                                          tabController.index);
                                                    },
                                                    pinPostCallback: () {
                                                      PradhanService.setPinnedPost(
                                                          docId:
                                                              getLatestWelcomeScreenLocId(),
                                                          pinnedPost: "");
                                                      welcomeController
                                                              .pinpostModel
                                                              .value =
                                                          PostModel.empty();
                                                    },
                                                    onDeleteCompleted: () {
                                                      // removing this post as pinned
                                                      setState(() {
                                                        PradhanService
                                                            .setPinnedPost(
                                                                docId:
                                                                    getLatestWelcomeScreenLocId(),
                                                                pinnedPost: "");

                                                        homeController.getPosts(
                                                            tabController
                                                                .index);

                                                        welcomeController
                                                                .pinpostModel
                                                                .value =
                                                            PostModel.empty();
                                                      });
                                                    },
                                                  ),
                                                )
                                              : Container(),
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount:
                                              homeController.postList.length,
                                          separatorBuilder: (context, index) {
                                            return homeController
                                                        .adList[index] !=
                                                    null
                                                ? AdCard(
                                                    adModel: homeController
                                                        .adList[index]!,
                                                    onVisible: (ad) {
                                                      homeController.viewAd(ad);
                                                    })
                                                : SizedBox();
                                          },
                                          itemBuilder: (context, index) {
                                            final postModel =
                                                homeController.postList[index];

                                            if (postModel.postId ==
                                                welcomeController.pinpostModel
                                                    .value.postId) {
                                              return Container();
                                            }

                                            if (postModel.showlevel.contains(
                                                    tabController.index) ||
                                                (tabController.index == 0 &&
                                                    !postModel.showlevel
                                                        .contains(1))) {
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: index + 1 ==
                                                          homeController
                                                              .postList.length
                                                      ? 100
                                                      : 0,
                                                ),
                                                child: VisibilityDetector(
                                                  key: ValueKey(
                                                      postModel.postId),
                                                  onVisibilityChanged: (info) {
                                                    onVisibilityChanged(
                                                        info, postModel);
                                                  },
                                                  child: PostCard(
                                                    tabIndex:
                                                        tabController.index,
                                                    postModel: postModel,
                                                    level: tabController.index,
                                                    updateLevelCallback: () {
                                                      homeController.getPosts(
                                                          tabController.index);
                                                    },
                                                    pinPostCallback: () async {
                                                      PradhanService
                                                          .setPinnedPost(
                                                        docId:
                                                            getLatestWelcomeScreenLocId(),
                                                        pinnedPost:
                                                            postModel.postId,
                                                      );
                                                      await welcomeController
                                                          .getPradhanId(
                                                              getLatestWelcomeScreenLocId());
                                                    },
                                                    pradhanComment: () {
                                                      pradhanComment(
                                                          postModel.postId);
                                                    },
                                                    postOption:
                                                        isCurrentUserPradhaan
                                                            ? PostOption.pradhan
                                                            : PostOption.none,
                                                    onDeleteCompleted: () {
                                                      homeController.getPosts(
                                                          tabController.index);
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
                                            return Container(
                                              height: index + 1 ==
                                                      homeController
                                                          .postList.length
                                                  ? 100
                                                  : 0,
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // FIXME: THIS SEEMS TO BE LOADING WHEN INDIA POSTS ARE LOADING, WE SWITCH BACK TO STATE AND INVALID POSTS LOAD. THEN WE REFRESH AND IT SHOWS UP.
                              if (homeController.isLoading.value &&
                                  homeController.lastDoc != null)
                                LinearProgressIndicator(
                                  color: AppColors.primaryColor,
                                  backgroundColor:
                                      AppColors.primaryColor.withOpacity(.5),
                                ),
                            ],
                          ),
                  ),
                )
        ],
      ),
    );
  }

  // RestartableTimer _onPostVisibilityChanged({
  //   required VisibilityInfo info,
  //   required PostModel postModel,
  // }) {
  // setting the timer up
  // final restartableTimer = RestartableTimer(
  //   const Duration(seconds: 5),
  //   () {
  //     final bool isPostIdInSet = postIdsOfUpdatedViewCountsAndStillVisible
  //         .firstWhere(
  //           (entry) => entry.postId == postModel.postId,
  //           orElse: () => PostViewCountUpdateTimer.empty(),
  //         )
  //         .postId
  //         .isNotEmpty;

  // if the view fraction is greater than 90%
  //     if (info.visibleFraction > .9) {
  // if the post id is not in set, add it and update the view count
  //       if (!isPostIdInSet) {
  //         print('current view fraction: ${info.visibleFraction}');
  //         print('updated view count of ${postModel.postDesc}');

  //         FirebaseFirestore.instance
  //             .collection(POST_DB)
  //             .doc(postModel.postId)
  //             .set(
  //           {
  //             'views_count': FieldValue.increment(1),
  //           },
  //           SetOptions(merge: true),
  //         ).then((value) {
  // adding the post id and a sample timer in set
  //           postIdsOfUpdatedViewCountsAndStillVisible.add(
  //             PostViewCountUpdateTimer(
  //               postId: postModel.postId,
  //               timer: RestartableTimer(Duration.zero, () {}),
  //             ),
  //           );
  //         });
  //       } else {
  //         print('ignoring as is already updated count');
  //       }
  //     } else if (info.visibleFraction < .1) {
  // if less than 10% of the area is visible
  // and if we have already updated the view count of this post, remove it
  // so that the next time it comes to view, we can count that as a new view count
  //       if (isPostIdInSet) {
  //         postIdsOfUpdatedViewCountsAndStillVisible.removeWhere(
  //           (entry) => entry.postId == postModel.postId,
  //         );

  //         print('removing post id');
  //       }
  //     }

  //     print('');
  //   },
  // );

  // return restartableTimer;
  // }

  TextEditingController specialcommentController = TextEditingController();
  pradhanComment(String postId) {
    Get.dialog(Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: specialcommentController,
            limit: 60,
          ),
          SizedBox(height: 10),
          AppButton(
              onPressed: () async {
                CommentModel commentModel = CommentModel(
                    postId: postId,
                    commentId: "",
                    userId: getPrefValue(Keys.USERID),
                    createdAt: Timestamp.now(),
                    comment: specialcommentController.text);
                bool add = await PostService.addSpecialComment(
                    commentModel: commentModel);
                if (add) {
                  Get.back();
                  specialcommentController.clear();
                  homeController.getPosts(tabController.index);
                } else {
                  Get.back();
                }
              },
              buttonText: "Pradhaan Comment")
        ],
      ),
    ));
  }

  Stream<QuerySnapshot<Object?>>? getPollsFuture() {
    // if tab index is 1
    if (tabController.index == 1) {
      return PollsService.getPollsForPostal();
    } else if (tabController.index == 2) {
      return PollsService.getPollsForCity();
    } else if (tabController.index == 3) {
      return PollsService.getPollsForState();
    } else if (tabController.index == 4) {
      return PollsService.getPollsForCountry();
    }

    return null;
  }

  Widget getFilterWidget() {
    return tabController.index != 0 && tabController.index != 4
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  switch (tabController.index) {
                    case 0:
                    case 1:
                      homeController.getPostal();
                      showDailog();
                      break;
                    case 2:
                      homeController.getCity();
                      showDailog();
                      break;
                    case 3:
                      homeController.getStates();
                      showDailog();
                      break;
                    case 4:
                      break;
                    default:
                      break;
                  }

                  // showDailog();
                },
                child: Container(
                  // width: 40,
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // Shadow color
                          spreadRadius: 2, // Spread radius
                          blurRadius: 5, // Blur radius
                          offset: Offset(0, 3), // Offset from the top
                        ),
                      ],
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(15)),
                  // alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10.0, right: 5, bottom: 3, top: 3),
                    child: Row(
                      children: [
                        Obx(() => Text(
                              getLatestText(homeController.filterby.value),
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                              ),
                            )),
                        Icon(Icons.keyboard_arrow_down_outlined,
                            color: AppColors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              if (homeController.selectedPostal.value.id !=
                      locationModelFromJson(getPrefValue(Keys.POSTAL)).id ||
                  homeController.selectedCity.value.id !=
                      locationModelFromJson(getPrefValue(Keys.CITY)).id ||
                  homeController.selectedState.value.id !=
                      locationModelFromJson(getPrefValue(Keys.STATE)).id) ...[
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    homeController.selectedPostal.value =
                        locationModelFromJson(getPrefValue(Keys.POSTAL));
                    homeController.selectedCity.value =
                        locationModelFromJson(getPrefValue(Keys.CITY));
                    homeController.selectedState.value =
                        locationModelFromJson(getPrefValue(Keys.STATE));
                    setState(() {});
                    homeController.getPosts(homeController.filterby.value);
                    homeController.getSachiv(homeController.filterby.value);
                  },
                  child: Icon(Icons.cancel_outlined, size: 20),
                )
              ]
            ],
          )
        : Container();
  }

  String getLatestText(int value) {
    switch (homeController.filterby.value) {
      case 0:
      case 1:
        return homeController.selectedPostal.value.text;

      case 2:
        return homeController.selectedCity.value.text;
      case 3:
        return homeController.selectedState.value.text;
      case 4:
        return "IND";
      default:
        return homeController.selectedState.value.text;
    }
  }

  String getLatestWelcomeScreenName() {
    switch (tabController.index) {
      case 0:
        return locationModelFromJson(getPrefValue(Keys.CITY)).name;
      case 1:
        return homeController.selectedPostal.value.name;

      case 2:
        return homeController.selectedCity.value.name;
      case 3:
        return homeController.selectedState.value.name;
      case 4:
        return "India";
      default:
        return homeController.selectedState.value.name;
    }
  }

  String getLatestWelcomeScreenText() {
    switch (tabController.index) {
      case 0:
        return locationModelFromJson(getPrefValue(Keys.CITY)).text;
      case 1:
        return homeController.selectedPostal.value.text;

      case 2:
        return homeController.selectedCity.value.text;
      case 3:
        return homeController.selectedState.value.text;
      case 4:
        return "IND";
      default:
        return homeController.selectedState.value.text;
    }
  }

  int getLatestLevel() {
    switch (tabController.index) {
      case 0:
        return 2;
      case 1:
        return 1;

      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 4;

      default:
        return 4;
    }
  }

  String getLatestWelcomeScreenLocId() {
    switch (tabController.index) {
      case 0:
        return locationModelFromJson(getPrefValue(Keys.CITY)).id;
      case 1:
        return homeController.selectedPostal.value.id;

      case 2:
        return homeController.selectedCity.value.id;
      case 3:
        return homeController.selectedState.value.id;
      case 4:
        return "1-India";

      default:
        return homeController.selectedState.value.id;
    }
  }

  String getFilteredText(int value) {
    switch (value) {
      case 0:
        return "${locationModelFromJson(getPrefValue(Keys.POSTAL)).name}, ${locationModelFromJson(getPrefValue(Keys.CITY)).text}, ${locationModelFromJson(getPrefValue(Keys.STATE)).text}";
      case 1:
        return homeController.selectedPostal.value.name;
      case 2:
        return homeController.selectedCity.value.name;
      case 3:
        return homeController.selectedState.value.name;
      case 4:
        return "India";
      default:
        return homeController.selectedState.value.text;
    }
  }

  showDailog() {
    Get.bottomSheet(LocationBottomSheet());
  }

  void showModalBottomSheetForPolls(List<QueryDocumentSnapshot> polls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * .7,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 3,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...polls.map((poll) {
                          return StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('polls')
                                .doc(poll.id)
                                .snapshots(),
                            builder: (context, snapshot) {
                              // if waiting or no data
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  snapshot.hasError ||
                                  snapshot.data == null) {
                                return const SizedBox();
                              }

                              // grabbing the data
                              final data = snapshot.data;

                              // grabbing the document data
                              final docData = data!.data();

                              // if doc data is null, just return
                              if (docData == null) {
                                return const SizedBox();
                              }

                              // grabbing the data we need
                              final String title = docData!['question'];

                              final List options = docData['options'];

                              final String status = docData['status'];

                              // calculating total votes
                              int totalVotes = 0;
                              for (int i = 0; i < options.length; i++) {
                                totalVotes += (options[i]['count'] as int);
                              }

                              // if status is inactive, return
                              if (status == 'inactive') {
                                return const SizedBox();
                              }

                              return _buildPollCard(
                                  title, options, poll, totalVotes);
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Container _buildPollCard(String title, List<dynamic> options,
      QueryDocumentSnapshot<Object?> poll, int totalVotes) {
    // if is guest login
    final isGuestLogin = Pref.getBool(Keys.IS_GUEST_LOGIN, false);

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1.5, color: AppColors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 10,
          ),
          ...options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  // if guest tries to vote, send him to login
                  if (isGuestLogin) {
                    AppRoutes.navigateToLogin();
                    return;
                  }

                  // grabbing the poll doc
                  final pollDoc = FirebaseFirestore.instance
                      .collection('polls')
                      .doc(poll.id);

                  // grabbing the doc and creating/accessing the collection
                  final participantsCollection =
                      pollDoc.collection('participants');

                  // grabbing the query snapshot for getting the current user participant
                  final querySnapshot = await participantsCollection
                      .where(
                        'userId',
                        isEqualTo: getPrefValue(Keys.USERID),
                      )
                      .get();

                  // grabbing the docs from the snapshot
                  final docs = querySnapshot.docs;

                  // if this user has already participated
                  if (docs.isNotEmpty) {
                    // grabbing the doc
                    final userDoc = participantsCollection.doc(docs.first.id);

                    // grabbing the previous option id
                    final previousOptionId = docs.first.data()['voted'];

                    // deciding whether the user is choosing new option or not
                    bool hasChosenAnother = previousOptionId != option['id'];

                    // if user has chosen another
                    if (hasChosenAnother) {
                      // updating the doc
                      userDoc.update({
                        'voted': option['id'],
                      });

                      // update the count in options as well
                      await pollDoc.update({
                        'options': options.map((o) {
                          // if option text is of the current, update the count
                          if (o['id'] == option['id']) {
                            return updateKey(
                              o,
                              'count',
                              o['count'] + 1,
                            );
                          } else if (o['id'] == previousOptionId) {
                            return updateKey(
                              o,
                              'count',
                              o['count'] - 1,
                            );
                          }

                          return o;
                        }).toList()
                      });
                    }
                  } else {
                    // adding the user doc
                    await participantsCollection.doc().set(
                      {
                        'userId': getPrefValue(Keys.USERID),
                        'voted': option['id'],
                      },
                    );

                    // update the count in options as well
                    await pollDoc.update({
                      'options': options.map((o) {
                        // if option text is of the current, update the count
                        if (o['text'] == option['text']) {
                          return updateKey(
                            o,
                            'count',
                            o['count'] + 1,
                          );
                        }

                        return o;
                      }).toList()
                    });
                  }
                },
                child: Row(
                  children: [
                    if (!isGuestLogin)
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('polls')
                                .doc(poll.id)
                                .collection('participants')
                                .where('userId',
                                    isEqualTo: getPrefValue(Keys.USERID))
                                .snapshots(),
                            builder: (context, snapshot) {
                              // if waiting or if there is an error if there is no data
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  snapshot.hasError ||
                                  snapshot.data == null) {
                                return Checkbox(
                                  value: false,
                                  onChanged: null,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                );
                              }

                              final data = snapshot.data;

                              // grabbing the docs
                              final docs = data!.docs;

                              // grabbing the selected value
                              final selectedId = docs.isEmpty
                                  ? ''
                                  : docs.first.data()['voted'];

                              return Checkbox(
                                value: selectedId == option['id'],
                                fillColor: MaterialStateProperty.all(
                                    selectedId == option['id']
                                        ? AppColors.primaryColor
                                        : Colors.transparent),
                                onChanged: null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                side: BorderSide(width: 1),
                              );
                            }),
                      ),
                    if (isGuestLogin)
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: false,
                          onChanged: null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          side: BorderSide(width: 1),
                        ),
                      ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(option['text']),
                              ),
                              // const SizedBox(
                              //   width: 10,
                              // ),
                              // Text(
                              //   option['count']
                              //       .toString(),
                              // ),
                            ],
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          LinearProgressIndicator(
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(50),
                            color: AppColors.primaryColor,
                            value: totalVotes == 0
                                ? 0
                                : (option['count'] as int) / totalVotes,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          // Text(
          //   'Total votes: $totalVotes',
          //   style: TextStyle(
          //     fontStyle: FontStyle.italic,
          //   ),
          // ),
          const SizedBox(
            height: 10,
          ),
          if (!isGuestLogin)
            Obx(
              () {
                final userId = getPrefValue(Keys.USERID);

                if (welcomeController.pradhanId.value == userId &&
                    poll.get('created_by') == userId) {
                  return GestureDetector(
                    onTap: () async {
                      final confirmDeletion = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Are you sure?'),
                              content: Text(
                                  'Once this poll is deleted, it can not be recovered'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                  child: Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Text('Yes'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirmDeletion) {
                        setState(() {
                          _handlePollDeletion(poll.id);
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.delete,
                          color: AppColors.primaryColor,
                          size: 22,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          'Delete',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.primaryColor),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox();
              },
            )
        ],
      ),
    );
  }

  Future<void> _handlePollDeletion(String pollId) async {
    try {
      await FirebaseFirestore.instance
          .collection(POLLS_DB)
          .doc(pollId)
          .delete();
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, message: e.toString());
      }
    }
  }

  // method to update a key of a map and return the updated map
  Map updateKey(Map map, dynamic keyToBeUpdated, dynamic valueToBeUpdated) {
    Map updated = map.map(
      (key, value) => key == keyToBeUpdated
          ? MapEntry(key, valueToBeUpdated)
          : MapEntry(key, value),
    );

    return updated;
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
