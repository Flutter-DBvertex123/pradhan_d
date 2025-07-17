
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../models/followers_model.dart';
import '../../models/user_model.dart';
import '../../screen/home/image_interactive_viewer.dart';
import '../../screen/shimmer/post_shimmer.dart';
import '../../service/collection_name.dart';
import '../../service/user_service.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_pref.dart';
import '../../utils/app_routes.dart';
import '../models/ad_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdCard extends StatefulWidget {
  final Function(AdModel ad) onVisible;
  const AdCard({
    super.key,
    required this.adModel,
    required this.onVisible
  });

  final AdModel adModel;
  @override
  State<AdCard> createState() => _PostCardState();
}

class _PostCardState extends State<AdCard> {
  UserModel? userModel;
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;
  final PageController _pageViewController = PageController();

  @override
  void initState() {
    super.initState();

    

    if (widget.adModel.videoUrl != null) {
      

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.adModel.videoUrl!),
      );

      _videoPlayerController!.initialize().then(
            (value) =>
            setState(() {
              

              initializingVideo = false;
              _videoPlayerController!.setVolume(0);

              // setting up chewie controller
              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController!,
                autoPlay: false,
                autoInitialize: true,
                allowFullScreen: true,
                allowMuting: true,
                allowPlaybackSpeedChanging: true,
                allowedScreenSleep: false,
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                hideControlsTimer: Duration(seconds: 1),
              );
            }),
      );
    } else {
      

      setState(() {
        initializingVideo = false;
      });
    }

    getUserModel();
  }

  getUserModel() async {
    setState(() {
      loading = true;
    });
    userModel = await UserService.getUserData(widget.adModel.uid);

    setState(() {
      loading = false;
    });
  }

  bool loading = true;
  bool initializingVideo = true;

  @override
  void dispose() {
    super.dispose();

    _chewieController?.dispose();
    _videoPlayerController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? PostShimmer()
        : VisibilityDetector (
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.4) {
          widget.onVisible(widget.adModel);
        }
      },
          key: Key(widget.adModel.id),
          child: Padding(
                padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
                ),
                child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: getColorBasedOnLevel(widget.adModel.scope.length),
              width: 2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
                left: 16.0.sp,
                right: 16.0.sp,
                top: 9.0.sp,
                bottom: 9.0.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                loading
                    ? userShimmer()
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    InkWell(
                      onTap: () {

                        AppRoutes.navigateToMyProfile(
                            userId: widget.adModel.uid,
                            back: true,
                        isOrganization: false);
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 23.r,
                            backgroundColor: getColorBasedOnLevel(userModel!.level),
                            child: CircleAvatar(
                                radius: 20.r,
                                backgroundColor: AppColors.gradient1,
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  clipBehavior: Clip.hardEdge,
                                  child: CachedNetworkImage(
                                    placeholder: (context, error) {
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
                                    errorWidget:
                                        (context, error, stackTrace) {
                                      return Image.asset(
                                        AppAssets.brokenImage,
                                        fit: BoxFit.fitHeight,
                                        width: 160.0,
                                        height: 160.0,
                                      );
                                    },
                                    imageUrl: userModel!.image,
                                    // .replaceAll('\', '//'),
                                    fit: BoxFit.cover,
                                    // width: 160.0,
                                    height: 160.0,
                                  ),
                                )),
                          ),
                          if (userModel!.affiliateImage.isNotEmpty)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 20.w,
                                width: 20.w,
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
                                  child: userModel!
                                      .affiliateImage.isNotEmpty
                                      ? CachedNetworkImage(
                                    imageUrl: userModel!
                                        .affiliateImage,
                                    errorWidget:
                                        (context, url, error) {
                                      return Image.asset(
                                        AppAssets.brokenImage,
                                        fit: BoxFit.fitHeight,
                                        height: 15.0,
                                      );
                                    },
                                    placeholder:
                                        (context, url) {
                                      return CircleAvatar(
                                        radius: 10.r,
                                        backgroundColor:
                                        AppColors.gradient1,
                                        child: Center(
                                          child:
                                          CircularProgressIndicator(
                                            color: AppColors
                                                .highlightColor,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                      : Image.asset(
                                    AppAssets.brokenImage,
                                    fit: BoxFit.fitHeight,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: userModel!.isOrganization
                                    ? const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 1,
                                )
                                    : null,
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(50),
                                  color: userModel!.isOrganization
                                      ? AppColors.primaryColor
                                      : null,
                                ),
                                child: Text(
                                  userModel!.name,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      color: userModel!.isOrganization
                                          ? Colors.white
                                          : Color.fromRGBO(
                                          0, 0, 0, 1),
                                      fontFamily: 'Montserrat',
                                      fontSize: 12,
                                      letterSpacing:
                                      0 /*percentages not used in flutter. defaulting to zero*/,
                                      fontWeight: FontWeight.normal,
                                      height: 1),
                                ),
                              ),
                              SizedBox(
                                width: 5.w,
                              ),

                              // if no affiliate text is there then don't show this label
                              if (userModel!
                                  .affiliateText.isNotEmpty &&
                                  !userModel!.isOrganization)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 1.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    userModel!.affiliateText,
                                    style: TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(6)
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Ad',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onPrimary
                                  ),
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 7,
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: Get.width * 0.35,
                                    child: Text(
                                      "${widget.adModel.scope.reversed.map((scopeName) => scopeName).toList().join(', ')}.",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Color.fromRGBO(51, 51, 51, 1),
                                          fontFamily: 'Montserrat',
                                          fontSize: 10,
                                          letterSpacing:
                                          0 /*percentages not used in flutter. defaulting to zero*/,
                                          fontWeight:
                                          FontWeight.normal,
                                          height: 1),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 2,
                                  ),
                                  _buildPostDate(),
                                ],
                              ),
                              const Spacer(),
                              if (userModel!.id !=
                                  getPrefValue(Keys.USERID) &&
                                  userModel!.isOrganization)
                                StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection(USER_DB)
                                      .doc(userModel!.id)
                                      .collection(FOLLOWERS_DB)
                                      .where("follower_id",
                                      isEqualTo: getPrefValue(
                                          Keys.USERID))
                                      .snapshots(),
                                  builder: (context,
                                      AsyncSnapshot snapshot) {
                                    bool isJoined =
                                        snapshot.data != null &&
                                            snapshot.data!.docs
                                                .isNotEmpty;

                                    return GestureDetector(
                                      onTap: () {
                                        // print("follow");
                                        if (snapshot.data != null &&
                                            snapshot
                                                .data!.docs.isEmpty) {
                                          // print("follow add");
                                          FollowerModel followerModel =
                                          FollowerModel(
                                              followerId:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid,
                                              followeeId:
                                              userModel!.id,
                                              createdAt: Timestamp
                                                  .now());
                                          UserService.addFollowers(
                                              followerModel:
                                              followerModel);
                                        } else {
                                          // print("follow delete");
                                          UserService.deleteFollowers(
                                              followId: snapshot
                                                  .data!.docs[0].id,
                                              userId: userModel!.id);
                                        }
                                      },
                                      child: Container(
                                        // width: 40,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: isJoined
                                                  ? AppColors
                                                  .primaryColor
                                                  : AppColors
                                                  .greyTextColor,
                                              width: 2),
                                          borderRadius:
                                          BorderRadius.circular(
                                              15),
                                          color: isJoined
                                              ? AppColors.primaryColor
                                              : null,
                                        ),

                                        // alignment: Alignment.center,
                                        child: Padding(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 5.0,
                                              vertical: 2),
                                          child: Text(
                                            isJoined
                                                ? "Joined"
                                                : "Join",
                                            style: TextStyle(
                                                color: isJoined
                                                    ? Colors.white
                                                    : AppColors
                                                    .greyTextColor),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                ExpandableNotifier(
                  child: ExpandablePanel(
                    theme: ExpandableThemeData(
                      tapBodyToExpand: true,
                      hasIcon: false,
                      tapBodyToCollapse: true,
                      bodyAlignment: ExpandablePanelBodyAlignment.left,
                    ),
                    collapsed: Linkify(
                      text: widget.adModel.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: const Color(0xff000000),
                        height: 1.5,
                      ),
                    ),
                    expanded: Linkify(
                      text: widget.adModel.description,
                      onOpen: (link) async {
                        // grabbing the url
                        final String url = link.url;

                        // opening the url in the browser
                        if (!await launchUrl(Uri.parse(url))) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Couldn\'t load url! Please try again later.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: const Color(0xff000000),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 11.h),
                if (widget.adModel.images.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1 / 1,
                    child: PageView(
                      controller: _pageViewController,
                      scrollDirection: Axis.horizontal,
                      children: widget.adModel.images.map((e) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ImageInteractiveViewer(
                                        image: e,
                                      ),
                                ),
                              );
                            },
                            child: CachedNetworkImage(
                              placeholder: (context, stackTrace) {
                                return SizedBox(
                                  height: 50.h,
                                  width: double.infinity,
                                  child: Center(
                                      child: CircularProgressIndicator(color: AppColors.darkRedColor,)),
                                );
                              },
                              imageUrl: e,
                              errorWidget: (context, error, stackTrace) {
                                return Image.asset(AppAssets.brokenImage);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (widget.adModel.images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: SmoothPageIndicator(
                        controller: _pageViewController,
                        count: widget.adModel.images.length,
                        effect: WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                if (widget.adModel.videoUrl?.isNotEmpty == true &&
                    initializingVideo)
                  Container(
                    alignment: Alignment.center,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  ),
                if (widget.adModel.videoUrl != null &&
                    !initializingVideo && _videoPlayerController != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: Chewie(
                        controller: _chewieController!,
                      ),
                    ),
                  ),
                SizedBox(
                  height:  widget.adModel.actionUrl != null && widget.adModel.actionUrl!.isNotEmpty ? 5.h : 13.h,
                ),
                if (widget.adModel.actionUrl != null && widget.adModel.actionUrl!.isNotEmpty) Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      color: AppColors.gradient1,
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () async {
                          // grabbing the url
                          final String url = widget.adModel.actionUrl!;

                          // opening the url in the browser
                          if (!await launchUrl(Uri.parse(url))) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Couldn\'t load url! Please try again later.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.info, color: Colors.white, size: 20),
                              SizedBox(width: 3),
                              Text(
                                'Know more ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 15
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // SizedBox(
                //   height: 13.h,
                // ),
              ],
            ),
          ),
                ),
              ),
        );
  }

  Widget _buildPostDate() {
    return Text(
      _getPostDate(),
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        color: Colors.black54,
      ),
      softWrap: false,
    );
  }

  String _getPostDate() {
    if (DateTime
        .now()
        .difference(widget.adModel.createdAt)
        .inHours <
        24) {
      return timeago.format(widget.adModel.createdAt);
    } else {
      return DateFormat('MMM dd, yyyy')
          .format(widget.adModel.createdAt);
    }
  }
}

Color getColorBasedOnLevel(int level) {
  switch (level) {
    case 1:
      return AppColors.white;
    case 2:
      return AppColors.yellowColor;
    case 3:
      return AppColors.pinkColor;
    case 4:
      return AppColors.darkRedColor;
    default:
      return AppColors.white;
  }
}
