import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:chunaw/app/controller/home/video_scrollview_controller.dart';
import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/followers_model.dart';
import 'package:chunaw/app/models/like_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/screen/home/comment_card.dart';
import 'package:chunaw/app/screen/home/image_interactive_viewer.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/post_service.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/service/vote_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/enums.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:chunaw/app/widgets/linear_gradient_mask.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:like_button/like_button.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/v4.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../controller/home/audio_controller.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    Key? key,
    required this.postModel,
    required this.onDeleteCompleted,
    this.postOption = PostOption.none,
    this.level,
    this.updateLevelCallback,
    this.pradhanComment,
    this.pinPostCallback,
    this.pinned = false,
    required this.tabIndex,
  }) : super(key: key);
  final PostModel postModel;
  // final int level;
  final PostOption postOption;
  final int? level;
  final bool pinned;
  final Function()? updateLevelCallback;
  final Function()? pinPostCallback;
  final Function()? pradhanComment;
  final Function() onDeleteCompleted;
  final int? tabIndex;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with WidgetsBindingObserver {
  final AudioController audioController = Get.put(AudioController()); // Global controller
  UserModel? userModel;
  UserModel? posterModel;
  UserModel? pradhanCommentModel;
  TextEditingController commentController = TextEditingController();
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;
  final PageController _pageViewController = PageController();
  late final bool isGuestLogin;
  //bool isMute = true;

  bool needToMute = true;

  late final AudioPlayer? audioPlayer = widget.postModel.backgroundMusic == null
      ? null
      : (AudioPlayer(
    handleInterruptions: false,
    handleAudioSessionActivation: false
  )
    ..setLoopMode(LoopMode.all)
    ..setVolume(audioController.getVolume())
    ..setUrl(widget.postModel.backgroundMusic!));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.paused && needToMute){
      audioController.muteAll();
    }else if(state==AppLifecycleState.resumed){
      audioController.restoreVolume();
    }

    // setState(() {
    //   if (AppLifecycleState.paused == state) {
    //     if (needToMute) {
    //       audioPlayer?.setVolume(0.0);
    //     }
    //   } else if (AppLifecycleState.resumed == state /*&& !isMute*/) {
    //     audioPlayer?.setVolume(audioController.getVolume());
    //   }
    // });
    print("ishwar:temp -> $state from post card");
  }

  @override
  void initState() {
    super.initState();
    isGuestLogin = Pref.getBool(Keys.IS_GUEST_LOGIN, false);
    // Register audio player
    if (audioPlayer !=null) {
audioController.registerAudioPlayer(audioPlayer!);
      // audioController.isMuted.listen((isMuted) {
      //   audioPlayer?.setVolume(audioController.getVolume());

    }
    if (widget.postModel.postVideo.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.postModel.postVideo),
      );

      _videoPlayerController!.initialize().then(
            (value) => setState(() {
              initializingVideo = false;
              audioController.registerVideoController(_videoPlayerController!);
              _videoPlayerController!.setVolume(audioController.getVolume());
              //_videoPlayerController!.setVolume(0);

              // setting up chewie controller
              _chewieController = ChewieController(
                videoPlayerController: _videoPlayerController!,
                autoPlay: false,
                autoInitialize: true,
                allowFullScreen: false,
                showOptions: false,
                looping: true,
                showControls: false,

                additionalOptions: (context) {
                  return [
                    OptionItem(
                      onTap: (c) {
                        _handleFullScreen();
                      },
                      iconData: Icons.fullscreen,
                      title: 'Full Screen',
                    ),
                  ];
                },
                allowMuting: true,
                allowPlaybackSpeedChanging: true,
                allowedScreenSleep: false,
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                hideControlsTimer: Duration(seconds: 1),
              );
            }),
          );
      audioController.isMuted.listen((isMuted) {
        _videoPlayerController?.setVolume(isMuted?0.0:1.0);
      },);
    } else {
      setState(() {
        initializingVideo = false;
      });
    }

    getUserModel();
    WidgetsBinding.instance.addObserver(this);
  }

  void _handleFullScreen() {
    final videoScrollViewController = Get.put(VideoScrollviewController());

    // clearing the previous data
    videoScrollViewController.clear();

    // adding the initial post model in
    videoScrollViewController.addInitialPostModel(
      widget.postModel,
      _videoPlayerController!.value.position.inSeconds,
    );

    // navigating to the view
    AppRoutes.navigateToVideosScrollview(level: widget.tabIndex);
  }

  Future<void> reportPost(String reason, BuildContext context) async {
    final reportsCollection = FirebaseFirestore.instance.collection(REPORT_DB);
    final querySnapshot = await reportsCollection
        .where('postId', isEqualTo: widget.postModel.postId)
        .get();

    try {
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await reportsCollection.doc(docId).update({
          'reportsCount': FieldValue.increment(1),
        });

        await reportsCollection.doc(docId).collection('by').add({
          //   'userId': u, // assuming you have the user ID
          //   'timestamp': DateTime.now(),
          'reason': reason,
          'reportedBy': Pref.getString(
              Keys.USERID), // Assuming you have user ID stored in preferences
          'reportedAt': Timestamp.now(),
        });
      } else {
        final newDocRef = await reportsCollection.add({
          'postId': widget.postModel.postId,
          'reportsCount': 1,
        });

        await newDocRef.collection('by').add({
          'reason': reason,
          'reportedBy': Pref.getString(
              Keys.USERID), // Assuming you have user ID stored in preferences
          'reportedAt': Timestamp.now(),
        });
      }

      // Notify the user
      longToastMessage('Post reported successfully!');

      // Dismiss the dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      longToastMessage('An error occurred while reporting the post.');
      print(e);
    }
  }

  getUserModel() async {
    print("yash:  PostCard: Fetching userModel for userId = ${widget.postModel.userId}, posterId = ${widget.postModel.posterId}");
    setState(() {
      // loading = true;
    });
    userModel = await UserService.getUserData(widget.postModel.userId);
if(userModel ==null){
  print("yash: PostCard: Failed to fetch userModel for userId = ${widget.postModel.userId}");
  userModel = UserModel.empty()..name = "Unknown";
}
    print("yash:  PostCard: userModel fetched, name = ${userModel!.name}, isOrganization = ${userModel!.isOrganization}");

    // If posterId exists (i.e., this is an organization post), fetch posterModel (the user who posted)
    if (widget.postModel.posterId != null && widget.postModel.posterId!.isNotEmpty) {
      print("yash:  PostCard: Fetching posterModel for posterId = ${widget.postModel.posterId}");
      posterModel = await UserService.getUserData(widget.postModel.posterId!);
      if (posterModel == null) {
        print("yash:  PostCard: Failed to fetch posterModel for posterId = ${widget.postModel.posterId}");
        // Fallback: Use FirebaseAuth to get the user's displayName or email
        final currentUser = FirebaseAuth.instance.currentUser;
        String fallbackName = "Unknown";
        if (currentUser != null && currentUser.uid == widget.postModel.posterId) {
          if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
            fallbackName = currentUser.displayName!;
          } else if (currentUser.email != null && currentUser.email!.isNotEmpty) {
            fallbackName = currentUser.email!.split('@').first;
          }
        }
        // Use UserModel.empty() and update the name field
        posterModel = UserModel.empty()..name = fallbackName;
      } else {
        print("yash:  PostCard: posterModel fetched, name = ${posterModel!.name}");
      }
    } else {
      print("yash:  PostCard: posterId is null or empty, skipping posterModel fetch");
    }
    final specialComment = widget.postModel.specialComment;

    if (specialComment != null) {
      pradhanCommentModel =
          await UserService.getUserData(specialComment.userId);
    }

    setState(() {
      // loading = false;
    });
  }

  bool comment = false;
  // bool loading = true;
  bool initializingVideo = true;

  @override
  void dispose() {
    if(audioPlayer !=null){
      audioController.unregisterAudioPlayer(audioPlayer!);
      audioPlayer?.pause();
      audioPlayer?.stop();
      audioPlayer?.dispose();
    }
    if(_videoPlayerController != null){
      audioController.unregisterVideoController(_videoPlayerController!);
      _chewieController?.dispose();
      _videoPlayerController?.dispose();
    }
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  List<String> reportReasons = [
    'Public Order threat',
    'Fake news',
    'Privacy',
    'Nudity',
    'Child Abuse',
    'Terrorism/Extremism',
    'Inappropriate',
    'Drug abuse',
    'Grossly Immoral',
    'Hate Speech',
    'Emergent Attention',
    'Other',
    // Add more reasons here as needed
  ];

  @override
  Widget build(BuildContext context) {
    return userModel == null
        ? PostShimmer()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0,
            ),
            child: VisibilityDetector(
              key: UniqueKey(),
              onVisibilityChanged: (info) async {
                if (info.visibleFraction >= .9) {
                  _chewieController?.play();
                  audioPlayer?.play();
                } else if (info.visibleFraction <= .15) {
                  _chewieController?.pause();
                  if (needToMute) {
                    print("ishwar: needToMute => $needToMute");
                    audioPlayer?.pause();
                  }
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: getColorBasedOnLevel(widget.postModel.level),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 16.0.sp,
                      right: 16.0.sp,
                      top: widget.pinned ? 15.0.sp : 9.0.sp,
                      bottom: 9.0.sp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.pinned)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(
                                30), // Same as the card's border radius
                          ),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: 5.0),
                          child: Text(
                            'Pradhaan Pick',
                            style: TextStyle(
                                color: AppColors.gradient1,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      SizedBox(
                        height: 10,
                      ),
                      userModel == null
                          ? userShimmer()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                InkWell(
                                  onTap: () {
                                    AppRoutes.navigateToMyProfile(
                                        userId: widget.postModel.userId,
                                        isOrganization:
                                            userModel?.isOrganization ?? false,
                                        back: true);
                                  },
                                  child: Stack(
                                    children: [
                                      userModel?.isOrganization == true ? SizedBox(
                                        height: 45.w,
                                        width: 45.w,
                                        child: Card(
                                          margin: EdgeInsets.zero,
                                          elevation: 0,
                                          clipBehavior: Clip.hardEdge,
                                          child: CachedNetworkImage(
                                            placeholder: (context, error) {
                                              return Center(
                                                  child:
                                                  CircularProgressIndicator(
                                                    color: AppColors
                                                        .highlightColor,
                                                  ));
                                            },
                                            errorWidget: (context, error,
                                                stackTrace) {
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
                                        ),
                                      ) : CircleAvatar(
                                        radius: 23.r,
                                        backgroundColor: getColorBasedOnLevel(
                                            userModel?.level ?? 1),
                                        child: CircleAvatar(
                                            radius: 20.r,
                                            backgroundColor:
                                                AppColors.gradient1,
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
                                                errorWidget: (context, error,
                                                    stackTrace) {
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
                                                      errorWidget: (context,
                                                          url, error) {
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
                                                              AppColors
                                                                  .gradient1,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(

                                            userModel!.isOrganization &&
                                                widget.postModel.posterId !=null &&
                                                widget.postModel.posterId!.isNotEmpty
                                            // ?"${userModel!.name}  Posted by  ${posterModel?.name??"Unknown"}"
                                            ?"${userModel!.name}  ➣  ${posterModel?.name??"Unknown"}"
                                            :userModel!.name,
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                                color:
                                                    Color.fromRGBO(
                                                            0, 0, 0, 1),
                                                fontFamily: 'Montserrat',
                                                fontSize: 12,
                                                letterSpacing:
                                                    0 /*percentages not used in flutter. defaulting to zero*/,
                                                fontWeight: FontWeight.normal,
                                                height: 1),
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
                                                  "${widget.postModel.fullAdd.sublist(0, 3).join(",")}.",
                                                  textAlign: TextAlign.left,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Color.fromRGBO(
                                                          51, 51, 51, 1),
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
                                          if (userModel!.oadmin !=
                                                  getPrefValue(Keys.USERID) &&
                                              userModel!.id !=
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
                                                  child:!isJoined? Container(
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
                                                          ? AppColors
                                                              .primaryColor
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
                                                  ):SizedBox(),
                                                );
                                              },
                                            )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.pinned ||
                                    widget.postOption != PostOption.none)
                                  const SizedBox(
                                    width: 10,
                                  ),
                                // if (widget.pinned)
                                //   Icon(
                                //     Icons.push_pin_outlined,
                                //     color: Colors.green,
                                //     size: 19,
                                //   ),
                                // if (widget.postOption != PostOption.none ||
                                //     widget.postModel.userId ==
                                //         Pref.getString(Keys.USERID))
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.only(left: 0),
                                    icon: Padding(
                                      padding: EdgeInsets.zero,
                                      child: Icon(Icons.more_vert),
                                    ),
                                    iconSize: 20,
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'create poll':
                                          AppRoutes.navigateToCreatePollPage(
                                              widget.tabIndex!);
                                          break;
                                   //change by yg: 20/6/25
                                          /*     case 'upgrade':
                                          print(
                                              "Page level: ${widget.level}, Post level: ${userModel!.level}");
                                          // if (widget.level! >= userModel!.level) {
                                          UpLikeModel upvoteModel = UpLikeModel(
                                              postId: widget.postModel.postId,
                                              userId: getPrefValue(Keys.USERID),
                                              createdAt: Timestamp.now(),
                                              postUserId:
                                                  widget.postModel.userId);
                                          VoteService.upgradePostLevel(
                                              upvoteModel: upvoteModel,
                                              isOrganization:
                                                  userModel!.isOrganization,
                                              level: widget.level!,
                                              postModel: widget.postModel);
                                          widget.updateLevelCallback?.call();
                                          // getUserModel();
                                          // } else {
                                          //   longToastMessage(
                                          //       "You can only upgrade your level user");
                                          // }

                                          break;*/
                                        // case 'next':
                                        //   // Handle next level action
                                        //   break;
                                        case 'comment':
                                          // Handle special comment action
                                          widget.pradhanComment!.call();
                                          break;
                                        case 'pin':
                                          // Handle special comment action
                                          widget.pinPostCallback!.call();
                                          break;
                                        case 'delete':
                                          try {
                                            // deleting the post
                                            await PostService.deletePost(
                                                widget.postModel);

                                            widget.onDeleteCompleted();
                                          } catch (e) {
                                            longToastMessage(
                                                'An error occurred!');

                                            print(e);
                                          }

                                          break;
                                        case 'edit':
                                          AppRoutes.navigateToAddPost(
                                              existingPost: widget.postModel,
                                              organizationId:
                                                  userModel!.isOrganization
                                                      ? userModel!.id
                                                      : null);
                                          break;
                                        case 'report':
                                          // if is guest login, ask to login
                                          if (isGuestLogin) {
                                            AppRoutes.navigateToLogin(
                                                removeGuestLogin: true);
                                            return;
                                          }

                                          showReportDialog(context);

                                          break;
                                      }
                                    },
                                    itemBuilder: (BuildContext context) {
                                      int vote = 2;
                                      if (widget.postOption !=
                                          PostOption.pradhan) {
                                        switch (widget.level) {
                                          case 1:
                                            vote = 2;

                                            break;
                                          case 2:
                                            vote = 5;
                                            break;
                                          case 3:
                                            vote = 7;
                                            break;
                                          case 4:
                                            vote = 10;
                                            break;
                                          default:
                                            vote = 2;
                                        }
                                      } else {
                                        switch (widget.level) {
                                          case 1:
                                            vote = 5;

                                            break;
                                          case 2:
                                            vote = 10;
                                            break;
                                          case 3:
                                            vote = 20;
                                            break;
                                          case 4:
                                            vote = 0;
                                            break;
                                          default:
                                            vote = 2;
                                        }
                                      }
                                      return [
                                        if (widget.postOption ==
                                                PostOption.pradhan &&
                                            widget.tabIndex != null)
                                          PopupMenuItem(
                                            value: 'create poll',
                                            child: Text('Create Poll'),
                                          ),
                                        if (widget.postOption ==
                                                PostOption.sachiv ||
                                            widget.postOption ==
                                                PostOption.pradhan)

                                       // change by yh: 20/6/25
                                         /* PopupMenuItem<String>(
                                            value: 'upgrade',
                                            child: Text('Upgrade'),
                                          ),*/
                                        if (widget.postOption ==
                                            PostOption.pradhan)
                                          PopupMenuItem<String>(
                                            value: 'pin',
                                            child: Text(widget.pinned
                                                ? 'Remove Top Pick'
                                                : 'Top Pick'),
                                          ),
                                        if (widget.postOption ==
                                            PostOption.pradhan)
                                          PopupMenuItem<String>(
                                            value: 'comment',
                                            child: Text('Pradhaan Comment'),
                                          ),

                                        // if the current user is the one who made the post
                                        if (widget.postModel.userId ==
                                                Pref.getString(Keys.USERID) ||
                                            widget.postModel.posterId ==
                                                Pref.getString(Keys.USERID))
                                          PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),

                                        // if the current user is the one who made the post
                                        if (widget.postModel.userId ==
                                                Pref.getString(Keys.USERID) ||
                                            widget.postModel.posterId ==
                                                Pref.getString(Keys.USERID))
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),

                                        if (widget.postModel.userId !=
                                                Pref.getString(Keys.USERID) &&
                                            widget.postModel.posterId !=
                                                Pref.getString(Keys.USERID))
                                          PopupMenuItem(
                                            value: 'report',
                                            child: Text('Report'),
                                          ),
                                      ];
                                    },
                                  ),
                                )
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
                            text: widget.postModel.postDesc,
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
                            text: widget.postModel.postDesc,
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
                      if (widget.postModel.postImages.isNotEmpty)
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 1 / 1,
                              child: PageView(
                                controller: _pageViewController,
                                scrollDirection: Axis.horizontal,
                                children: widget.postModel.postImages.map((e) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: GestureDetector(
                                      onTap: () async {
                                        needToMute = false;
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ImageInteractiveViewer(
                                              image: e, audioPlayer: audioPlayer,
                                            ),
                                          ),
                                        );
                                        needToMute = true;
                                      },
                                      child: CachedNetworkImage(
                                        placeholder: (context, stackTrace) {
                                          return SizedBox(
                                            height: 50.h,
                                            width: double.infinity,
                                            child: Center(
                                                child: CircularProgressIndicator()),
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

                            if (widget.postModel.backgroundMusic != null )
                              Positioned(
                                right: 5,
                                bottom: 5,
                                child: Obx(
                                      () => GestureDetector(
                                    onTap: () {
                                      audioController.toggleMute();
                                      // No need for manual setVolume here; AudioController handles it
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.black.withOpacity(.5),
                                      ),
                                      child: Icon(
                                        audioController.isMuted.value
                                            ? Icons.volume_off
                                            : Icons.volume_up,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (widget.postModel.postImages.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: SmoothPageIndicator(
                              controller: _pageViewController,
                              count: widget.postModel.postImages.length,
                              effect: WormEffect(
                                dotHeight: 8,
                                dotWidth: 8,
                                activeDotColor: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      if (widget.postModel.postVideo.isNotEmpty &&
                          initializingVideo)
                        Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          child: CircularProgressIndicator(color: AppColors.gradient1,),
                        ),
                      if (widget.postModel.postVideo.isNotEmpty &&
                          !initializingVideo)
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _handleFullScreen();
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoPlayerController!.value.aspectRatio,
                                  child: Chewie(
                                    controller: _chewieController!,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.postModel.postVideo.isNotEmpty)
                              Positioned(
                                right: 5, // Changed from right to left
                                bottom: 5,
                                child: Obx(
                                      () => GestureDetector(
                                    onTap: () {
                                      audioController.toggleMute();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.black.withOpacity(.5),
                                      ),
                                      child: Icon(
                                        audioController.isMuted.value
                                            ? Icons.volume_off
                                            : Icons.volume_up,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      SizedBox(
                        height: 13.h,
                      ),
                      Column(
                        children: [
                          // Card(
                          //   color: Colors.grey,
                          //   elevation: 0,
                          //   child: Padding(
                          //     padding:EdgeInsets.symmetric(horizontal: 12),
                          //     child: Row(
                          //       children: [
                          //         Expanded(
                          //           child: Text('External audio'),
                          //         ),
                          //         IconButton(
                          //             onPressed:  () {
                          //
                          //             },
                          //             icon: Icon(Icons.play_arrow)
                          //         )
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          Row(
                            children: [
                              upvoteButton(),
                              SizedBox(width: 5.w),
                              StreamBuilder(
                                stream: FirebaseFirestore.instance
                                    .collection(USER_DB)
                                    .doc(userModel!.isOrganization ? widget.postModel.posterId : widget.postModel.userId)
                                    .collection(UPVOTE_DB)
                                    .where('post_id',
                                        isEqualTo: widget.postModel.postId)
                                    .snapshots(),
                                builder: (context, AsyncSnapshot snapshot) {
                                  return Text(
                                    "${snapshot.data != null ? snapshot.data!.docs.length : 0}",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        color: Color.fromRGBO(51, 51, 51, 1),
                                        fontFamily: 'Montserrat',
                                        fontSize: 12.sp,
                                        letterSpacing:
                                            0 /*percentages not used in flutter. defaulting to zero*/,
                                        fontWeight: FontWeight.normal,
                                        height: 1),
                                  );
                                },
                              ),
                              SizedBox(
                                width: 5.w,
                              ),
                              // if (!isGuestLogin)
                              //   StreamBuilder(
                              //     stream: FirebaseFirestore.instance
                              //         .collection(USER_DB)
                              //         .doc(getPrefValue(Keys.USERID))
                              //         .snapshots(),
                              //     builder: (context, AsyncSnapshot snapshot) {
                              //       final textStyle = TextStyle(
                              //         color: Color.fromRGBO(51, 51, 51, 1),
                              //         fontFamily: 'Montserrat',
                              //         fontSize: 12.sp,
                              //         letterSpacing:
                              //             0 /*percentages not used in flutter. defaulting to zero*/,
                              //         fontWeight: FontWeight.normal,
                              //         height: 1,
                              //       );
                              //
                              //       // if loading or an error, or if data is null
                              //       if (snapshot.connectionState ==
                              //               ConnectionState.waiting ||
                              //           snapshot.hasError ||
                              //           snapshot.data == null) {
                              //         return Text(
                              //           "(-)",
                              //           textAlign: TextAlign.left,
                              //           style: textStyle,
                              //         );
                              //       }
                              //
                              //       return Text(
                              //         "(${5 - snapshot.data.data()['todays_upvote']})",
                              //         textAlign: TextAlign.left,
                              //         style: textStyle,
                              //       );
                              //     },
                              //   ),
                              SizedBox(width: 10.w),
                              _buildViewsCount(),
                              SizedBox(
                                width: 10.w,
                              ),
                              likeButton(),
                              StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection(POST_DB)
                                      .doc(widget.postModel.postId)
                                      .collection(LIKE_DB)
                                      .snapshots(),
                                  builder: (context, AsyncSnapshot snapshot) {
                                    return Text(
                                      "${snapshot.data != null ? snapshot.data!.docs.length : 0}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Color.fromRGBO(51, 51, 51, 1),
                                          fontFamily: 'Montserrat',
                                          fontSize: 12.sp,
                                          letterSpacing:
                                              0 /*percentages not used in flutter. defaulting to zero*/,
                                          fontWeight: FontWeight.normal,
                                          height: 1),
                                    );
                                  }),
                              SizedBox(
                                width: 10.w,
                              ),
                              _buildShareButton(),
                              SizedBox(width: 10.w),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    comment = !comment;
                                  });
                                },
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppColors.gradient1,
                                  size: 25,
                                ),
                              ),
                              SizedBox(width: 5.w),
                              StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection(POST_DB)
                                      .doc(widget.postModel.postId)
                                      .collection(COMMENT_DB)
                                      .snapshots(),
                                  builder: (context, AsyncSnapshot snapshot) {
                                    return Text(
                                      "${snapshot.data != null ? snapshot.data!.docs.length : 0}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          color: Color.fromRGBO(51, 51, 51, 1),
                                          fontFamily: 'Montserrat',
                                          fontSize: 12.sp,
                                          letterSpacing:
                                              0 /*percentages not used in flutter. defaulting to zero*/,
                                          fontWeight: FontWeight.normal,
                                          height: 1),
                                    );
                                  }),
                            ],
                          ),
                        ],
                      ),
                      if (widget.postModel.specialComment != null) ...[
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.black.withOpacity(.1),
                          ),
                          padding: EdgeInsets.only(
                            left: 5,
                            right: 10,
                            top: 3,
                            bottom: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              if (pradhanCommentModel != null)
                                SizedBox(
                                  height: 35,
                                  width: 35,
                                  child: pradhanCommentModel!.image.isEmpty
                                      ? SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            child: Image.asset(
                                              AppAssets.brokenImage,
                                              fit: BoxFit.fitHeight,
                                            ),
                                          ),
                                        )
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              height: 30,
                                              width: 30,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: CachedNetworkImage(
                                                  placeholder:
                                                      (context, error) {
                                                    return CircleAvatar(
                                                      radius: 15.r,
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
                                                  errorWidget: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                      AppAssets.brokenImage,
                                                      fit: BoxFit.fitHeight,
                                                    );
                                                  },
                                                  imageUrl: pradhanCommentModel!
                                                      .image,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                height: 17.w,
                                                width: 17.w,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          50.r),
                                                  color: Color(0xFF1A1A1A),
                                                  border: Border.all(
                                                      width: 1.5,
                                                      color: Colors.white),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          50.r),
                                                  child: pradhanCommentModel!
                                                          .affiliateImage
                                                          .isNotEmpty
                                                      ? CachedNetworkImage(
                                                          imageUrl:
                                                              pradhanCommentModel!
                                                                  .affiliateImage,
                                                          errorWidget: (context,
                                                              url, error) {
                                                            return Image.asset(
                                                              AppAssets
                                                                  .brokenImage,
                                                              fit: BoxFit
                                                                  .fitHeight,
                                                              height: 15.0,
                                                            );
                                                          },
                                                          placeholder:
                                                              (context, url) {
                                                            return CircleAvatar(
                                                              radius: 10.r,
                                                              backgroundColor:
                                                                  AppColors
                                                                      .gradient1,
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
                              if (pradhanCommentModel != null)
                                SizedBox(
                                  width: 10,
                                ),
                              Expanded(
                                child: Text(
                                  widget.postModel.specialComment?.comment ??
                                      "",
                                  maxLines: null,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                Icons.thumb_up,
                                size: 18,
                                color: Colors.black.withOpacity(.8),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                Icons.thumb_down,
                                size: 18,
                                color: Colors.black.withOpacity(.8),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                      // if (widget.postOption == PostOption.pradhan)
                      //   AppButton(
                      //       onPressed: () {
                      //         widget.specialComment?.call();
                      //       },
                      //       buttonText: "Add Pradhan Comment",
                      //       horizontal: 60),

                      if (comment) commentView(),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  GestureDetector _buildShareButton() {
    return GestureDetector(
      onTap: () async {
        // grabbing the post image, post video, and post description
        final List postImages = widget.postModel.postImages;
        final String postVideo = widget.postModel.postVideo;
        final String postDesc = widget.postModel.postDesc;

        // list to hold the equivalent files
        final List<XFile> files = [];

        // if we have post image or post video, download it
        if (postImages.isNotEmpty || postVideo.isNotEmpty) {
          longToastMessage('Preparing the media for share');

          // will hold the media
          List<http.Response> downloadedMedia = [];

          if (postImages.isNotEmpty) {
            for (final postImage in postImages) {
              final response = await http.get(Uri.parse(postImage));
              downloadedMedia.add(response);
            }
          } else {
            final response = await http.get(Uri.parse(postVideo));
            downloadedMedia.add(response);
          }

          // grabbing the temp directory
          final tempDir = await getTemporaryDirectory();
          final tempDirPath = tempDir.path;

          for (final media in downloadedMedia) {
            // grabbing the bytes
            final bytes = media.bodyBytes;

            // grabbing the file extension
            final mime = lookupMimeType('', headerBytes: bytes);
            final extension = mime != null ? extensionFromMime(mime) : '';

            // generating a uuid
            final uuid = UuidV4().generate();

            // creating the file
            final file = File(
                '$tempDirPath/$uuid${extension.isEmpty ? '' : '.$extension'}');

            // writing the bytes to the file
            file.writeAsBytesSync(bytes);

            files.add(XFile(file.path));
          }
        }

        // title part
        final String title = postDesc.isEmpty ? '' : '"$postDesc"\n\n';

        // body part
        final String body =
            '${title}Download Pradhaan app. India\'s only app for local community build up and Leadership. https://play.google.com/store/apps/details?id=com.ioninks.pradhaan';

        // if we have some downloaded media
        if (files.isNotEmpty) {
          Share.shareXFiles(
            files,
            text: body,
          );
        } else {
          Share.share(body);
        }
      },
      child: Icon(
        Icons.share,
        color: AppColors.gradient1,
      ),
    );
  }

  Widget buildExplanationTextField(TextEditingController controller,
      String? selectedOption, FocusNode focusNode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.multiline,
        minLines: 3,
        maxLines: 5,
        autofocus: true,
        decoration: InputDecoration(
          labelText: "Please explain (optional)",
          labelStyle:
              focusNode.hasFocus ? TextStyle(color: Colors.black) : null,
          border: OutlineInputBorder(
            borderSide: BorderSide(),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          fillColor: const Color.fromARGB(255, 192, 190, 190).withOpacity(0.2),
          filled: true,
          alignLabelWithHint: true,
          contentPadding: EdgeInsets.fromLTRB(12, 0, 12, 22),
          enabled: selectedOption == 'Other',
        ),
      ),
    );
  }

  void showReportDialog(BuildContext context) {
    String? selectedOption;
    TextEditingController customReasonController = TextEditingController();
    FocusNode focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // whether we are reporting the post or not
        bool reportingPost = false;

        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              titlePadding: const EdgeInsets.only(
                top: 25,
                left: 25,
                right: 25,
                bottom: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                'Why are you reporting this post?',
                style: TextStyle(
                  // fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ...reportReasons.map((reason) {
                      return RadioListTile(
                        activeColor: Colors.red,
                        title: Text(
                          reason,
                          style: TextStyle(fontSize: 14),
                        ),
                        visualDensity: VisualDensity(
                            vertical: VisualDensity.minimumDensity),
                        value: reason,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setState(() {
                            selectedOption = value;
                            if (value == 'Other') {
                              customReasonController.clear();
                            }
                          });
                        },
                      );
                    }).toList(),
                    buildExplanationTextField(
                      customReasonController,
                      selectedOption,
                      focusNode,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                SizedBox(height: 8),
                AppButton(
                  onPressed: () async {
                    if (selectedOption != null) {
                      setState(() {
                        reportingPost = true;
                      });

                      if (selectedOption == 'Other') {
                        await reportPost(customReasonController.text, context);
                      } else {
                        await reportPost(selectedOption.toString(), context);
                      }

                      setState(() {
                        reportingPost = false;
                      });
                    }
                  },
                  showButtonText: !reportingPost,
                  customWidget: reportingPost
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                  buttonText: 'Submit',
                ),
              ],
            );
          },
        );
      },
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
    if (DateTime.now().difference(widget.postModel.createdAt.toDate()).inHours <
        24) {
      return timeago.format(widget.postModel.createdAt.toDate());
    } else {
      return DateFormat('MMM dd, yyyy')
          .format(widget.postModel.createdAt.toDate());
    }
  }

  Widget likeButton() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(POST_DB)
            .doc(widget.postModel.postId)
            .collection(LIKE_DB)
            .where('user_id', isEqualTo: getPrefValue(Keys.USERID))
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          return LikeButton(
            isLiked: snapshot.data != null && snapshot.data!.docs.isNotEmpty,
            bubblesColor: BubblesColor(
              dotPrimaryColor: AppColors.gradient2,
              dotSecondaryColor: AppColors.gradient1,
            ),
            circleSize: 20,
            onTap: (isLiked) async {
              // if is guest login, ask to login
              if (isGuestLogin) {
                AppRoutes.navigateToLogin(removeGuestLogin: true);
                return isLiked;
              }

              if (isLiked) {
                PostService.unlikePost(
                    postid: widget.postModel.postId,
                    likeId: snapshot.data!.docs[0].id);
              } else {
                UpLikeModel likeModel = UpLikeModel(
                    postId: widget.postModel.postId,
                    userId: getPrefValue(Keys.USERID),
                    createdAt: Timestamp.now(),
                    postUserId: widget.postModel.userId);
                PostService.likePost(likeModel: likeModel);
              }
              return !isLiked;
            },
            likeBuilder: (isLiked) {
              return isLiked
                  ? LinearGradientMask(
                      child: Icon(
                        Icons.favorite,
                        color: AppColors.gradient1,
                        size: 25,
                      ),
                    )
                  : LinearGradientMask(
                      child: Icon(
                        Icons.favorite_border,
                        color: AppColors.gradient1,
                        size: 25,
                      ),
                    );
            },
            circleColor:
                CircleColor(start: AppColors.white, end: AppColors.white),
          );
        });
  }

  Widget upvoteButton() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(userModel!.isOrganization
                ? widget.postModel.posterId
                : widget.postModel.userId)
            .collection(UPVOTE_DB)
            .where('user_id', isEqualTo: getPrefValue(Keys.USERID))
            .where('post_id', isEqualTo: widget.postModel.postId)
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          // print("snapshot.data ${snapshot.data}");
          return LikeButton(
            isLiked: snapshot.data != null && snapshot.data!.docs.isNotEmpty,
            bubblesColor: BubblesColor(
              dotPrimaryColor: AppColors.gradient2,
              dotSecondaryColor: AppColors.gradient1,
            ),
            circleSize: 20,
            onTap: (isLiked) async {
              // if is guest login, ask to login
              if (isGuestLogin) {
                AppRoutes.navigateToLogin(removeGuestLogin: true);
                return isLiked;
              }

              UpLikeModel likeModel = UpLikeModel(
                  postId: widget.postModel.postId,
                  userId: getPrefValue(Keys.USERID),
                  postUserId: (userModel!.isOrganization
                      ? widget.postModel.posterId
                      : widget.postModel.userId)!,
                  createdAt: Timestamp.now());

              print("ishwar:voting: ${likeModel.toJson()}");

              if (isLiked) {
                print("unvote");
                VoteService.unupvoteUser(
                    postUserId: (userModel!.isOrganization
                        ? widget.postModel.posterId
                        : widget.postModel.userId)!,
                    upvoteId: snapshot.data!.docs[0].id,
                    postid: widget.postModel.postId,
                    postModel: widget.postModel,
                    upvoteModel: likeModel);
                return !isLiked;
              } else {
                if (Pref.getInt(Keys.TODAY_UPVOTE) < 5) {
                  VoteService.upvoteUser(
                      upvoteModel: likeModel, postModel: widget.postModel);
                  return isLiked;
                } else {
                  longToastMessage(
                      "Only 5 Votes allowed in a Day");
                  return false;
                }
              }
            },
            likeBuilder: (isLiked) {
              return isLiked
                  ? Container(
                      alignment: Alignment.center,
                      child: Container(
                        height: 23,
                        width: 23,
                        decoration: BoxDecoration(
                          color: AppColors.darkRedColor,
                          border: Border.all(
                            width: 1.5,
                            color: AppColors.darkRedColor,
                          ),
                          borderRadius: BorderRadius.circular(200),
                          // color: AppColors.black,
                        ),
                        padding: EdgeInsets.all(0.5),
                        alignment: Alignment.center,
                        child: Image.asset(AppAssets.voteActiveImage,)
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      child: Container(
                        height: 23,
                        width: 23,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1.5,
                            color: AppColors.darkRedColor,
                          ),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(0.5),
                        child: Image.asset(AppAssets.voteActiveImage),
                      ),
                    );
            },
            circleColor:
                CircleColor(start: AppColors.white, end: AppColors.white),
          );
        });
  }

  Widget commentView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 10.h),
        Divider(height: 2, color: AppColors.greyTextColor),
        SizedBox(height: 10.h),
        StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection(POST_DB)
                .doc(widget.postModel.postId)
                .collection(COMMENT_DB)
                .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                Center(child: CupertinoActivityIndicator());
              }
              if (!snapshot.hasData) {
                Container();
              } else {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data != null &&
                              snapshot.data!.docs.isNotEmpty
                          ? 1
                          : 0,
                      itemBuilder: (BuildContext context, int index) {
                        return CommentCardWidget(
                            commentModel: CommentModel.fromJson(
                                snapshot.data!.docs[index].id,
                                snapshot.data!.docs[index].data()));
                      },
                    ),
                    if (snapshot.data != null && snapshot.data!.docs.isNotEmpty)
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            AppRoutes.navigateToComment(widget.postModel);
                          },
                          child: Container(
                            // width: 40,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.greyTextColor, width: 2),
                                borderRadius: BorderRadius.circular(15)),
                            // alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0, vertical: 6),
                              child: Text(
                                "View More",
                                style:
                                    TextStyle(color: AppColors.greyTextColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Container();
            }),
        commentField(),
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
                contentPadding: EdgeInsets.only(bottom: 5.0),
                hintStyle: TextStyle(fontSize: 14),
              ),
            ),
          )),
          SizedBox(width: 15),
          InkWell(
            onTap: () {
              // if is guest login, ask to login
              if (isGuestLogin) {
                AppRoutes.navigateToLogin(removeGuestLogin: true);
                return;
              }

              CommentModel commentModel = CommentModel(
                  postId: widget.postModel.postId,
                  commentId: "",
                  userId: getPrefValue(Keys.USERID),
                  createdAt: Timestamp.now(),
                  comment: commentController.text);
              PostService.addCommentPost(commentModel: commentModel);

              // clearing the comment and showing a toast
              commentController.clear();

              // losing the focus from the text field
              FocusManager.instance.primaryFocus?.unfocus();

              longToastMessage('Your comment has been added');
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

  Widget _buildViewsCount() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(POST_DB)
          .doc(widget.postModel.postId)
          .snapshots(),
      builder: (context, AsyncSnapshot snapshot) {
        return Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              color: AppColors.primaryColor,
            ),
            SizedBox(
              width: 10.w,
            ),
            Text(
              "${snapshot.data?.data()?['views_count'] ?? 0}",
              textAlign: TextAlign.left,
              style: TextStyle(
                  color: Color.fromRGBO(51, 51, 51, 1),
                  fontFamily: 'Montserrat',
                  fontSize: 12.sp,
                  letterSpacing:
                      0 /*percentages not used in flutter. defaulting to zero*/,
                  fontWeight: FontWeight.normal,
                  height: 1),
            ),
          ],
        );
      },
    );
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

