import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/controller/home/welcome_location_controller.dart';
import 'package:chunaw/app/dbvertex/area_pradhan_page.dart';
import 'package:chunaw/app/dbvertex/organisations/area_organizations_screen.dart';
import 'package:chunaw/app/dbvertex/promoters_screen.dart';
import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/screen/Location_features/vote_pradhan_screen.dart';
import 'package:chunaw/app/screen/home/post_card.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/post_service.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/enums.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'pradhan_status_card.dart';

class WelcomeLocationPage extends StatefulWidget {
  const WelcomeLocationPage({
    Key? key,
    required this.locationName, //Vishakhapatnam
    required this.locationId, //1-Vishakhapatnam
    required this.locationText,
    required this.level, //VSKP
    required this.isHome,
  }) : super(key: key);
  final String locationName;
  final String locationText;
  final String locationId;
  final int level;
  final bool isHome;

  @override
  State<WelcomeLocationPage> createState() => _WelcomeLocationPageState();
}

class _WelcomeLocationPageState extends State<WelcomeLocationPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  final WelcomeLocationController welcomeController =
      Get.put(WelcomeLocationController());
  @override
  void initState() {
    super.initState();
    log("Welcome page ${widget.locationId}, ${widget.locationName}, ${widget.locationText}");
    tabController =
        TabController(length: widget.level == 1 ? 5 : 4, vsync: this);
    welcomeController.getPosts([widget.locationName]);
    initialProcess();
  }

  // to hold the status whether we deleted any post or not
  bool deletedAnyPost = false;

  // list of post ids along with their timers
  final List<Map> postIdsWithViewUpdateTimers = [];

  // already seen post ids
  final Set<String> alreadySeenPostIds = {};

  initialProcess() async {
    // navigating to the vote tab initially
    // tabController.animateTo(1);

    await PradhanService.addImpDetailInPradhan(
        docId: widget.locationId,
        locationName: widget.locationName,
        locationText: widget.locationText,
        level: widget.level);
    await welcomeController.getPradhanId(widget.locationId);
    print("Pradhan ID: ${welcomeController.pradhanId}");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: deletedAnyPost);
        return false;
      },
      child: Scaffold(
        appBar: AppBarCustom(
          leadingBack: true,
          popValue: deletedAnyPost,
          trailling: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.gradient1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.hardEdge,
                  child: Obx(() => welcomeController.isStatusLoading.value
                      ? CircleAvatar(
                          radius: 20.r,
                          backgroundColor: AppColors.gradient1,
                          child: Center(
                              child: CircularProgressIndicator(
                            color: AppColors.highlightColor,
                          )),
                        )
                      : CachedNetworkImage(
                          placeholder: (context, error) {
                            return CircleAvatar(
                              radius: 20.r,
                              backgroundColor: AppColors.gradient1,
                              child: Center(
                                  child: CircularProgressIndicator(
                                color: AppColors.highlightColor,
                              )),
                            );
                          },
                          errorWidget: (context, error, stackTrace) {
                            return Image.asset(
                              AppAssets.brokenImage,
                              fit: BoxFit.fitHeight,
                              width: 160.0,
                              height: 160.0,
                            );
                          },
                          imageUrl: welcomeController.pradhanModel.value.image,
                          // .replaceAll('\', '//'),
                          fit: BoxFit.cover,
                          // width: 160.0,
                          height: 160.0,
                        )),
                )),
          ),
          title: 'Welcome to \n ${widget.locationName}',
          scaffoldKey: null,
          elevation: 0,
          bottom: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Theme(
              data: ThemeData(
                  primarySwatch: getMaterialColor(AppColors.primaryColor)),
              child: TabBar(
                  controller: tabController,
                  onTap: (index) {
                    welcomeController.getPosts([widget.locationName]);
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
                  indicatorSize: TabBarIndicatorSize.tab,
                  // indicatorPadding: EdgeInsets.symmetric(horizontal: 20.0),
                  isScrollable: false,
                  // tabAlignment: TabAlignment.start,
                  tabs: [
                    //        Tab(text: "Posts"),
                    Tab(text: "Vote"),
                    if (widget.level == 1) Tab(text: "Groups"),
                    Tab(text: "Pradhaan"),
                    Tab(text: "Promoter"),
                  ]),
            ),
          ),
        ),
        body: TabBarView(controller: tabController, children: [
          // postsArea(),
          VotePradhanScreen(
            locationText: widget.locationText,
            locationId: widget.locationId,
            locationName: widget.locationName,
            level: widget.level,
          ),
          if (widget.level == 1)
            AreaOrganizationsScreen(locationId: widget.locationId),
          AreaPradhanPage(
            showAppbar: false,
            suffix: widget.locationId,
          ),
          PromotersScreen(
            locationId: widget.locationId,
          )
        ]),
      ),
    );
  }

  Widget postsArea() {
    return Column(
      children: [
        // Obx(() => welcomeController.isStatusLoading.value
        //     ? shimmerWidget(
        //         child: Card(
        //           margin: const EdgeInsets.symmetric(
        //               horizontal: 20.0, vertical: 10),
        //           child: Container(
        //             width: double.infinity,
        //             height: 60,
        //             decoration: BoxDecoration(
        //               borderRadius: BorderRadius.only(
        //                 topLeft: Radius.circular(25),
        //                 topRight: Radius.circular(25),
        //                 bottomLeft: Radius.circular(25),
        //                 bottomRight: Radius.circular(25),
        //               ),
        //             ),
        //           ),
        //         ),
        //       )
        //     : PradhanStatusCard(locationId: widget.locationId)),
        PradhanStatusCard(locationId: widget.locationId),

        Flexible(
          child: Obx(() {
            final isCurrentUserPradhaan = welcomeController
                    .pradhanId.value.isNotEmpty &&
                welcomeController.pradhanId.value == getPrefValue(Keys.USERID);

            return welcomeController.isLoading.value
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    itemCount: 10,
                    padding: EdgeInsets.only(top: 10),
                    itemBuilder: (BuildContext context, int index) {
                      return PostShimmer();
                    },
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Obx(() =>
                            welcomeController.pinpostModel.value.postId != ""
                                ? VisibilityDetector(
                                    key: ValueKey(welcomeController
                                        .pinpostModel.value.postId),
                                    onVisibilityChanged: (info) {
                                      onVisibilityChanged(
                                        info,
                                        welcomeController.pinpostModel.value,
                                      );
                                    },
                                    child: PostCard(
                                      postModel:
                                          welcomeController.pinpostModel.value,
                                      tabIndex: widget.level,
                                      pinned: true,
                                      postOption: isCurrentUserPradhaan
                                          ? PostOption.pradhan
                                          : PostOption.none,
                                      pinPostCallback: () {
                                        PradhanService.setPinnedPost(
                                            docId: widget.locationId,
                                            pinnedPost: "");
                                        welcomeController.pinpostModel.value =
                                            PostModel.empty();
                                      },
                                      onDeleteCompleted: () {
                                        // removing this post as pinned
                                        setState(() {
                                          PradhanService.setPinnedPost(
                                              docId: widget.locationId,
                                              pinnedPost: "");

                                          welcomeController
                                              .getPosts([widget.locationName]);

                                          welcomeController.pinpostModel.value =
                                              PostModel.empty();
                                        });

                                        // setting the status of deleting
                                        deletedAnyPost = true;
                                      },
                                    ),
                                  )
                                : Container()),
                        SingleChildScrollView(
                          // shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(top: 10),
                          child: Column(
                            children: List.generate(
                                welcomeController.postList.length, (index) {
                              final postModel =
                                  welcomeController.postList[index];
                              if (postModel.postId ==
                                  welcomeController.pinpostModel.value.postId) {
                                return Container();
                              } else if (postModel.showlevel
                                      .contains(widget.level) ||
                                  widget.isHome) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index ==
                                            welcomeController.postList.length -
                                                1
                                        ? 100
                                        : 0,
                                  ),
                                  child: VisibilityDetector(
                                    key: ValueKey(postModel.postId),
                                    onVisibilityChanged: (info) {
                                      onVisibilityChanged(
                                        info,
                                        postModel,
                                      );
                                    },
                                    child: PostCard(
                                      postModel: postModel,
                                      level: widget.level,
                                      tabIndex: widget.level,
                                      updateLevelCallback: () {
                                        welcomeController
                                            .getPosts([widget.locationName]);
                                      },
                                      pinPostCallback: () async {
                                        PradhanService.setPinnedPost(
                                          docId: widget.locationId,
                                          pinnedPost: postModel.postId,
                                        );
                                        await welcomeController
                                            .getPradhanId(widget.locationId);
                                      },
                                      pradhanComment: () {
                                        pradhanComment(postModel.postId);
                                      },
                                      postOption: isCurrentUserPradhaan
                                          ? PostOption.pradhan
                                          : PostOption.none,
                                      onDeleteCompleted: () {
                                        welcomeController
                                            .getPosts([widget.locationName]);
                                        // setting the status of deleting
                                        deletedAnyPost = true;
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                return Container(
                                  height: index ==
                                          welcomeController.postList.length - 1
                                      ? 100
                                      : 0,
                                );
                              }
                            }),
                          ),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                  );
          }),
        ),
      ],
    );
  }

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
                  welcomeController.getPosts([widget.locationName]);
                } else {
                  Get.back();
                }
              },
              buttonText: "Pradhaan Comment")
        ],
      ),
    ));
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
