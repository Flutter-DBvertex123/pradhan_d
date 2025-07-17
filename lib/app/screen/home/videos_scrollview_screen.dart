import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:chunaw/app/controller/home/audio_controller.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:chunaw/app/controller/home/video_scrollview_controller.dart';

class VideosScrollviewScreen extends StatefulWidget {
  const VideosScrollviewScreen({
    super.key,
    required this.level,
  });

  final int? level;

  @override
  State<VideosScrollviewScreen> createState() => _VideosScrollviewScreenState();
}

class _VideosScrollviewScreenState extends State<VideosScrollviewScreen> {
  late final VideoScrollviewController videoScrollviewController;
  late final RxList<PostModel> postModels;

  // to hold the current page view index
  int currentPageViewIndex = 0;

  bool hasAlreadyVisitedAnotherVideo = false;

  @override
  void initState() {
    super.initState();

    videoScrollviewController = Get.put(VideoScrollviewController());
    postModels = videoScrollviewController.postModels;

    // also loading the next set
    if (widget.level != null) {
      videoScrollviewController.loadNextSetInLevel(
        level: widget.level!,
      );
    } else {
      videoScrollviewController.loadNextSetInProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: PageView(
                scrollDirection: Axis.vertical,
                onPageChanged: (value) {
                  setState(() {
                    currentPageViewIndex = value;
                  });

                  // if this is the last page, load the next set if not already loading
                  if (value == postModels.length - 1 &&
                      !videoScrollviewController.isLoadingNextSet.value) {
                    // if we are on some level, load that set
                    if (widget.level != null) {
                      videoScrollviewController.loadNextSetInLevel(
                        level: widget.level!,
                      );
                    } else {
                      // otherwise we load the person's posts
                      videoScrollviewController.loadNextSetInProfile();
                    }
                  }
                },
                children: postModels
                    .map(
                      (element) => VideoData(
                        postModel: element,
                        index: currentPageViewIndex,
                      ),
                    )
                    .toList(),
              ),
            ),
            if (videoScrollviewController.isLoadingNextSet.value &&
                currentPageViewIndex == postModels.length - 1)
              LinearProgressIndicator(
                color: AppColors.primaryColor,
              ),
          ],
        );
      }),
    );
  }
}

class VideoData extends StatefulWidget {
  const VideoData({
    super.key,
    required this.postModel,
    required this.index,
  });

  final PostModel postModel;
  final int index;

  @override
  State<VideoData> createState() => _VideoDataState();
}

class _VideoDataState extends State<VideoData> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _initializingVideo = true;
  late final UserModel userModel;
  bool _initializingUserModel = true;
  final _descExpandableController = ExpandableController();
  final videoScrollviewController = Get.put(VideoScrollviewController());
  final AudioController audioController=Get.put(AudioController());

  @override
  void initState() {
    super.initState();

    // getting the seconds played so far in the initial video
    int secondsPlayedSoFar = videoScrollviewController.secondsPlayedSoFar;
    print('init state called');

    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.postModel.postVideo),
    );

    _videoPlayerController!.initialize().then((value) {
      setState(() {
        _initializingVideo = false;
        audioController.registerVideoController(_videoPlayerController!);
        _videoPlayerController!.setVolume(audioController.isMuted.value?0.0:1.0);
      });

      // if the index is 0, seeking the video to that seconds duration
      if (widget.index == 0) {
        _videoPlayerController!.seekTo(Duration(seconds: secondsPlayedSoFar));
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        allowFullScreen: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowMuting: true,
        allowedScreenSleep: true,
        looping: true,
        autoInitialize: true,
         autoPlay: true,
          showControls: true,

       // autoPlay: widget.index==0,
      );
      audioController.isMuted.listen((isMuted) {
        _videoPlayerController?.setVolume(isMuted?0.0:1.0);
      },);
      _videoPlayerController!.addListener(() {
        final currentVolume=_videoPlayerController!.value.volume;
        final isCurrentlyMuted=currentVolume==0.0;
        if(isCurrentlyMuted !=audioController.isMuted.value){
          audioController.isMuted.value=isCurrentlyMuted;
        }
      },);

    });

    UserService.getUserData(widget.postModel.userId).then((value) {
      setState(() {
        userModel = value!;
        _initializingUserModel = false;
      });
    });

    _descExpandableController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    if(_videoPlayerController != null){
      audioController.unregisterVideoController(_videoPlayerController!);
      _videoPlayerController?.dispose();
    }
    _chewieController?.dispose();
    _descExpandableController.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    // status bar height
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final appBarHeight = Scaffold.of(context).appBarMaxHeight;
    final availableHeight = MediaQuery.of(context).size.height -
        statusBarHeight -
        (appBarHeight ?? 0);

    return Stack(
      alignment: Alignment.center,
      children: [
        _initializingVideo
            ? AspectRatio(
                aspectRatio: 3 / 2,
                child: Container(
                  color: Colors.black87,
                )
                    .animate(
                      onComplete: (controller) => controller.repeat(),
                    )
                    .shimmer(
                      delay: 500.ms,
                      duration: 500.ms,
                      color: Colors.white30,
                    ),
              )
            : AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: Chewie(
                  controller: _chewieController!,
                ),
              ),
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: _initializingUserModel
              ? Container(height: availableHeight * .2,color: Colors.black87,
                )
                  .animate(
                    onComplete: (controller) => controller.repeat(),
                  )
                  .shimmer(
                      duration: 500.ms, delay: 500.ms, color: Colors.white10)
              : GestureDetector(
                  onTap: () {
                    _descExpandableController.toggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black.withOpacity(.7),
                    height: _descExpandableController.expanded
                        ? availableHeight * .5
                        : null,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CachedNetworkImage(
                                imageUrl: userModel.image,
                                imageBuilder: (context, imageProvider) {
                                  return CircleAvatar(
                                    backgroundImage: imageProvider,
                                  );
                                },
                                errorWidget: (context, url, error) {
                                  return CircleAvatar(
                                    backgroundImage:
                                        AssetImage(AppAssets.brokenImage),
                                  );
                                },
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userModel.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Montserrat',
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '${widget.postModel.fullAdd.sublist(0, 3).join(",")}.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  _buildPostDate(),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          ExpandableNotifier(
                            controller: _descExpandableController,
                            child: ExpandablePanel(
                              theme: ExpandableThemeData(
                                tapBodyToExpand: true,
                                hasIcon: false,
                                tapBodyToCollapse: true,
                                bodyAlignment:
                                    ExpandablePanelBodyAlignment.left,
                              ),
                              collapsed: Linkify(
                                text: widget.postModel.postDesc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  color: Colors.white,
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),

        // Positioned(
        //     right: 5,
        //     bottom: 5,
        //     child: Obx(() => GestureDetector(
        //       onTap: () => audioController.toggleMute,
        //       child: Container(
        //         padding: EdgeInsets.all(5),
        //         decoration: BoxDecoration(
        //           borderRadius: BorderRadius.circular(50),
        //           color: Colors.black.withOpacity(.5),
        //         ),
        //       child: Icon(
        //         audioController.isMuted.value?Icons.volume_off:Icons.volume_up,
        //         color: Colors.white,
        //         size: 24,
        //       ),),
        //     ),))

      ],
    );
  }

  Widget _buildPostDate() {
    return Text(
      _getPostDate(),
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        color: Colors.white70,
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
}
