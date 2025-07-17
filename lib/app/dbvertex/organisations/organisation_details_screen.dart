import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/organisations/create_organisation_screen.dart';
import 'package:chunaw/app/dbvertex/organisations/follower_card.dart';
import 'package:chunaw/app/dbvertex/organisations/organization_details_controller.dart';
import 'package:chunaw/app/dbvertex/organisations/organization_vote_screen.dart';
import 'package:chunaw/app/screen/home/add_post_screen.dart';
import 'package:chunaw/app/screen/home/create_post_screen.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../models/followers_model.dart';
import '../../screen/Location_features/pradhan_status_card.dart';
import '../../screen/home/post_card.dart';
import '../../service/user_service.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import 'org_pradhan_controller.dart';
import 'org_pradhan_status_card.dart';

import 'dart:ui' as ui;

class OrganisationDetailsScreen extends StatefulWidget {
  final String organisationId;

  const OrganisationDetailsScreen({super.key, required this.organisationId});

  @override
  State<StatefulWidget> createState() => OrganisationDetailsState();
}

class OrganisationDetailsState extends State<OrganisationDetailsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final controller = Get.put(OrganizationDetailsController(),
      tag: 'OrganizationDetailsController', permanent: true);
  late final orgPradhanController = Get.put(OrgPradhanController(widget.organisationId));

  late final TabController tabController =
      TabController(length: 4, vsync: this);

  double extraHeight = 0;

  StreamSubscription? followerStream;

  final scrollController = ScrollController();

  _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent) {
      controller.fetchPosts(widget.organisationId);
    }
  }

  @override
  void initState() {


    WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => controller.fetchPosts(widget.organisationId));
    super.initState();

    scrollController.addListener(_onScroll);

    listenToFollowers();
  }

  @override
  void dispose() {
    Get.delete<OrganizationDetailsController>(
        tag: 'OrganizationDetailsController', force: true);
    followerStream?.cancel();
    scrollController.removeListener(_onScroll);
    super.dispose();
  }

  listenToFollowers() {
    followerStream ??= FirebaseFirestore.instance
        .collection(USER_DB)
        .doc(widget.organisationId)
        .collection(FOLLOWERS_DB)
        // .where("follower_id", isEqualTo: getPrefValue(Keys.USERID))
        .snapshots()
        .listen((event) async {
      print("ishwar:new: changed followers${event.docs.map(
            (e) => e.data(),
          ).join(", ")}");

      List<FollowerModel> followers = [];
      String? myFollowId;

      try {
        for (final data in event.docs) {
          FollowerModel followerModel =
              FollowerModel.fromJson({...data.data(), 'id': data.id});
          if (followerModel.followerId == getPrefValue(Keys.USERID)) {
            myFollowId = data.id;
          }
          followers.add(followerModel);
        }
      } catch (e) {
        print("ishwar:new: $e");
      }
      if (myFollowId == null) {
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('organization_req')
              .where('org_id', isEqualTo: widget.organisationId)
              .where('user_id',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .get();
          controller.joinStatus.value =
              snapshot.docs.isNotEmpty ? 'request' : 'user';
        } catch (_) {
          controller.joinStatus.value = 'user';
        }
      } else {
        controller.joinStatus.value = 'member';
      }
      print("ishwar:new: changed followers11${followers}");

      controller.myFollowId = myFollowId ?? '';
      controller.followers.value = followers;
      controller.totalFollowers.value = followers.length;
      print("ishwar:new: ${controller.totalFollowers.value}");
      print("ishwar:new: Join status: ${controller.joinStatus.value}");
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: NestedScrollView(
            controller: scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                    centerTitle: true,
                    pinned: true,
                    leading: IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 21.0),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    title: Text(
                      'Organization Details',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    )),
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  expandedHeight:
                      MediaQuery.sizeOf(context).width * 0.910 + extraHeight,
                  flexibleSpace: FlexibleSpaceBar(background: _createDetails()),
                ),
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TabBar(
                        indicatorColor: AppColors.primaryColor,
                        labelColor: AppColors.primaryColor,
                        controller: tabController,
                        tabAlignment: TabAlignment.start,
                        isScrollable: true,
                        tabs: [
                          Tab(
                            text: 'Posts',
                          ),
                          Tab(
                            text: 'Vote',
                          ),
                          Tab(
                            text: 'Pradhaan',
                          ),
                          Tab(
                            text: 'Members',
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ];
            },
            body: Obx(() {
              if (controller.isPrivate.value == null) {
                return Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryColor),
                );
              }

              if (controller.isPrivate.value == true) {
                return Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width * 0.1),
                  child: Text(
                      'Organization is private.\nSend request to be a member.',
                      textAlign: TextAlign.center),
                ));
              }

              return TabBarView(
                controller: tabController,
                children: [
                  Container(
                    key: ValueKey('posts'),
                    color: Colors.grey[200],
                    child: _postsPage(),
                  ),
                  Container(
                    key: ValueKey('vote'),
                    color: Colors.grey[200],
                    child: OrganizationVoteScreen(organizationID: widget.organisationId),
                  ),
                  Container(
                    key: ValueKey('pradhaan'),
                    color: Colors.grey[200],
                    child: _pradhanPage(),
                  ),
                  Container(
                    key: ValueKey('followers'),
                    color: Colors.grey[200],
                    child: _membersPage(),
                  )
                ],
              );
            })),
      ),
    );
  }

  _pradhanPage() {
    if (orgPradhanController.pradhan.value == null || orgPradhanController.pradhan.value?.id.isEmpty == true) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.2),
          child: Text('Currently there is no pradhan in this organization', textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            tileColor: Colors.white,
            leading: CircleAvatar(
              radius: 22.r,
              backgroundColor: getColorBasedOnLevel(1),
              child: CircleAvatar(
                  radius: 25.r,
                  backgroundColor: AppColors.gradient1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.hardEdge,
                    child: CachedNetworkImage(
                      placeholder: (context, error) {
                        return CircleAvatar(
                          radius: 25.r,
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
                      imageUrl: orgPradhanController.pradhan.value?.image ?? '',
                      // .replaceAll('\', '//'),
                      fit: BoxFit.cover,
                      // width: 160.0,
                      height: 160.0,
                    ),
                  )),
            ),
            title: Text(orgPradhanController.pradhan.value?.name ?? ''),
            subtitle: Text("@${orgPradhanController.pradhan.value?.username}", style: TextStyle(color: AppColors.gradient1)),
            trailing: Column(
                children: [
                  Text(DateFormat("dd-MM-yyyy").format(getSunday(Timestamp.now()))),
                  SizedBox(
                    height: 1,
                  ),
                  Text("To"),
                  SizedBox(
                    height: 1,
                  ),
                  Text(DateFormat("dd-MM-yyyy").format(getSunday(Timestamp.now()).add(Duration(days: 7)))),
                ],
              )
          ),
        )
      ],
    );
  }

  DateTime getSunday(Timestamp timestamp) {
    final date = timestamp.toDate().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    return date.subtract(Duration(days: date.weekday % 7));
  }

  _postsPage() {
    return Obx(() {
      if (controller.posts.value == null) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      }
      //
      // if (controller.posts.value?.isEmpty == true) {
      //   return Center(
      //       child: Text('No post found')
      //   );
      // }

      final vertical = Column(
        children: [
          if (orgPradhanController.isCurrentUserPradhaan.value) OrgPradhanStatusCard(organizationId: widget.organisationId),
          if (controller.posts.value?.isEmpty == true)
            Expanded(
              child: Center(child: Text('No post found')),
            )
          else
            ...controller.posts.value!.map(
              (e) {
                return PostCard(
                    key: ValueKey(e.postId),
                    postModel: e,
                    onDeleteCompleted: () {
                      controller.deletePost(e);
                    },
                    tabIndex: 0);
              },
            ).toList()
          // ListView.builder(
          //   shrinkWrap: true,
          //   physics: NeverScrollableScrollPhysics(),
          //   itemCount: controller.posts.value!.length,
          //   itemBuilder: (context, index) {
          //     final postModel = controller.posts.value![index];
          //     return PostCard(key: ValueKey(postModel.postId), postModel: postModel, onDeleteCompleted: () {
          //       controller.deletePostAt(index);
          //     }, tabIndex: 0);
          //   },
          // ),
        ],
      );

      if (controller.posts.value?.isEmpty == true) {
        return vertical;
      } else {
        return SingleChildScrollView(child: vertical);
      }
    });
  }

  _membersPage() {
    return Obx(() {
      if (controller.totalFollowers.value == null) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        );
      }

      if (controller.totalFollowers.value == 0) {
        return Center(child: Text('No members found'));
      }

      return SingleChildScrollView(
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.followers.length,
          itemBuilder: (context, index) {
            final followerModel = controller.followers[index];
            return FollowerCard(
                followerModel: followerModel,
                admin: controller.admin ?? "",
                organizationId: widget.organisationId);
          },
        ),
      );
    });
  }

  double calculateTextHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: maxWidth);

    return textPainter.size.height;
  }

  _createDetails() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(USER_DB)
              .doc(widget.organisationId)
              .snapshots(),
          builder: (context, snapshot) {
            final Map<String, dynamic> data = snapshot.data?.data() ?? {};
            String orgIcon = data['image'] ?? '';
            String orgName = data['name'] ?? 'Loading...';
            String orgDesc = data['userdesc'] ?? 'Not available';
            String type = data['visibility'] ?? 'Private';
            String address = data['organization_address'] ?? '';
            String country = (data['country'] ?? {})['name'] ?? '';
            String postal = (data['postal'] ?? {})['name'] ?? '';
            String state = (data['state'] ?? {})['name'] ?? '';
            String city = (data['city'] ?? {})['name'] ?? '';
            if (data.containsKey('oadmin')) {
              controller.admin = data['oadmin'];
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                controller.iAdmin.value =
                    data['oadmin'] == getPrefValue(Keys.USERID);
                controller.isPrivate.value = !controller.iAdmin.value! &&
                    data['visibility'] == 'Private' &&
                    controller.joinStatus.value != "member";
              });
            }

            List<String> addressParts = [
              address.trim(),
              postal.trim(),
              city.trim(),
              state.trim(),
            ];

            // Filter out empty parts and join with a comma
            String finalAddressStr =
                "${addressParts.where((part) => part.isNotEmpty).join(', ')} ($country)";

            print('Formatted Address: $finalAddressStr');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _createHeader(orgIcon),
                ..._createOrgDetails(orgName, orgDesc, type, finalAddressStr)
              ],
            );
          }),
    );
  }

  List<Widget> _createOrgDetails(
      String orgName, String orgDesc, String type, String address) {
    final descStyle = TextStyle(
        color: Colors.black54,
        fontFamily: 'Montserrat',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.2);
    double descHeight = calculateTextHeight(
        text: orgDesc,
        style: descStyle,
        maxWidth: MediaQuery.sizeOf(context).width * 0.8);
    double addHeight = calculateTextHeight(
        text: address,
        style: descStyle,
        maxWidth: MediaQuery.sizeOf(context).width * 0.8);
    final totalHeight = descHeight + addHeight;
    if (totalHeight != extraHeight) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => setState(() {
            extraHeight = totalHeight;
          }));
    }
    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 15).copyWith(top: 8),
        child: Text(
          orgName,
          textAlign: TextAlign.left,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
              color: Color.fromRGBO(1, 1, 1, 1),
              fontFamily: 'Montserrat',
              fontSize: 16,
              letterSpacing:
                  0 /*percentages not used in flutter. defaulting to zero*/,
              fontWeight: FontWeight.w600,
              height: 1),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Obx(() {
          print("ishwar:new : ${controller.followers.length}");
          return Row(
            children: [
              Expanded(
                child: Text(
                  controller.totalFollowers.value == null
                      ? 'Loading...'
                      : '${controller.totalFollowers.value} members • $type Organisation',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                      height: 1),
                ),
              ),
              SizedBox(width: 12),
              Card(
                color: AppColors.primaryColor,
                elevation: 0,
                clipBehavior: Clip.hardEdge,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: InkWell(
                  onTap: () {
                    if (controller.iAdmin.value == true) {
                      Get.to(CreateOrganisationScreen(
                          organizationId: widget.organisationId));
                    } else {
                      if (controller.joinStatus.value == 'user') {
                        // print("follow add");
                        controller.join(
                          widget.organisationId,
                        );
                      } else if (controller.joinStatus.value == 'member') {
                        UserService.deleteFollowers(
                            followId: controller.myFollowId,
                            userId: widget.organisationId);
                      } else if (controller.joinStatus.value == 'request') {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text('Cancel request'),
                                  content: Text(
                                      'Do you want to cancel you request to join this organization.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Get.back(),
                                        child: Text('No',
                                            style: TextStyle(
                                                color:
                                                    AppColors.primaryColor))),
                                    TextButton(
                                        onPressed: () {
                                          controller.cancelRequest(
                                              widget.organisationId);
                                          Get.back();
                                        },
                                        child: Text('Yes',
                                            style: TextStyle(
                                                color:
                                                    AppColors.primaryColor))),
                                  ],
                                ));
                      }
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                    child: Obx(() {
                      return Text(
                        controller.iAdmin.value == null
                            ? 'Loading...'
                            : controller.iAdmin.value == true
                                ? 'Edit'
                                : controller.joinStatus.value == null
                                    ? 'Loading...'
                                    : controller.joinStatus.value == 'member'
                                        ? 'Leave'
                                        : controller.joinStatus.value ==
                                                'request'
                                            ? 'Cancel'
                                            : controller.isPrivate.value == true
                                                ? 'Request'
                                                : 'Join',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            letterSpacing:
                                0 /*percentages not used in flutter. defaulting to zero*/,
                            fontWeight: FontWeight.w600,
                            height: 1),
                      );
                    }),
                  ),
                ),
              )
            ],
          );
        }),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(orgDesc, textAlign: TextAlign.left, style: descStyle),
      ),
      SizedBox(height: 12),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(address,
            textAlign: TextAlign.left,
            style: descStyle.copyWith(color: Colors.black)),
      ),
      SizedBox(height: 5),
      _createPostBox()
    ];
  }

  _onPostBoxClicked() {
    if (controller.joinStatus.value == 'member' ||
        controller.iAdmin.value == true) {
      print("yash: Orgnization screen : Navigating to CreatePostScreen with organizationId = ${widget.organisationId}");
      Get.to(CreatePostScreen(organizationId: widget.organisationId))
          ?.then((value) {
        if (value == true) {
          controller.reload();
        }
      });
    } else {
      if (controller.joinStatus.value == 'user') {
        longToastMessage(controller.isPrivate.value == false
            ? 'Join this organization to post.'
            : 'Send request to be a member before posting.');
      } else {
        longToastMessage(
            'Please wait until admin approve your request to join this organization.');
      }
    }
  }

  _createPostBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        children: [
          ClipOval(
            child: CachedNetworkImage(
              placeholder: (context, error) {
                return Center(
                    child: CircularProgressIndicator(
                  color: AppColors.highlightColor,
                ));
              },
              errorWidget: (context, error, stackTrace) {
                return Image.asset(AppAssets.brokenImage,
                    fit: BoxFit.fitWidth, height: double.infinity);
              },
              imageUrl: getPrefValue(Keys.PROFILE_PHOTO),
              fit: BoxFit.cover,
              height: 35.0,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.grey[200],
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: _onPostBoxClicked,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Create a post',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1)),
                      ),
                      Container(
                          decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius:
                                  BorderRadiusDirectional.circular(100)),
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.add, color: Colors.white))
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  _createHeader(String orgIcon) {
    double size = MediaQuery.sizeOf(context).width;

    return Stack(
      children: [
        SizedBox(
          height: size * 0.48,
          child: Align(
            alignment: Alignment.topCenter,
            child: Image.asset(
              AppAssets.bannerImage,
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 15,
          height: size * 0.22,
          width: size * 0.22,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(1000)),
            color: Colors.white30,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: ClipOval(
                child: CachedNetworkImage(
                  placeholder: (context, error) {
                    return CircleAvatar(
                      radius: 55.r,
                      backgroundColor: AppColors.gradient1,
                      child: Center(
                          child: CircularProgressIndicator(
                        color: AppColors.highlightColor,
                      )),
                    );
                  },
                  errorWidget: (context, error, stackTrace) {
                    // printError();
                    return Image.asset(
                      AppAssets.brokenImage,
                      fit: BoxFit.fitHeight,
                      height: 122.0,
                    );
                  },
                  imageUrl: orgIcon,
                  fit: BoxFit.cover,
                  height: 160.0,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
