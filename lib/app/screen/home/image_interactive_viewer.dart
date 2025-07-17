import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/controller/admin/location_admin_controller.dart';
import 'package:chunaw/app/controller/home/audio_controller.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class ImageInteractiveViewer extends StatefulWidget {
  const ImageInteractiveViewer({
    super.key,
    required this.image,
    this.audioPlayer,
  });

  final String image;
  final AudioPlayer? audioPlayer;

  @override
  State<ImageInteractiveViewer> createState() => _ImageInteractiveViewerState();
}

class _ImageInteractiveViewerState extends State<ImageInteractiveViewer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final AudioController audioController=Get.put(AudioController());
  late final AnimationController _rotationController;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  // bool isMuted = true;
  final isSeeking=false.obs;
  final isLoading=false.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),

    );

    if (widget.audioPlayer != null) {
      audioController.registerAudioPlayer(widget.audioPlayer!);
      widget.audioPlayer!.setVolume(audioController.getVolume());
      //isMuted = widget.audioPlayer!.volume == 0.0;
      widget.audioPlayer!.durationStream.listen((d) {
          setState(() => duration = d ?? Duration.zero);
        },
      );
      widget.audioPlayer!.positionStream.listen((p) {
          setState(() => position = p);
        },
      );
      widget.audioPlayer!.playerStateStream.listen((event) {
          setState(() {
            isPlaying = event.playing &&
                event.processingState != ProcessingState.completed;
            isLoading.value=event.playing && (event.processingState ==ProcessingState.loading ||
                event.processingState==ProcessingState.buffering);
            if (event.processingState == ProcessingState.completed) {
              _rotationController.stop();
            } else if (event.playing  && !isLoading.value) {
              _rotationController.repeat();
            } else {
              _rotationController.stop();
            }
          });
        },
      );

      // audioController.isMuted.listen((isMuted) {
      //   widget.audioPlayer!.setVolume(audioController.getVolume());
      // },);
      // widget.audioPlayer!.volumeStream.listen((volume) {
      //   setState(() {
      //     isMuted=volume==0.0;
      //   });
      // },);
      if (!widget.audioPlayer!.playing) {
        widget.audioPlayer!.play();
        isLoading.value=true;
      }
    }

    // widget.audioPlayer?.playingStream.listen((isPlaying) {
    //   if (mounted) {
    //     if (isPlaying) {
    //       _rotationController.repeat();
    //     } else {
    //       _rotationController.stop();
    //     }
    //   }
    // });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.paused) {
      audioController.muteAll();
      // widget.audioPlayer?.setVolume(0.0);
    } else if (state == AppLifecycleState.resumed) {
      audioController.restoreVolume();
      // widget.audioPlayer?.setVolume(isMuted ? 0.0 : 1.0);
    // widget.audioPlayer?.setVolume(audioController.getVolume());
    }

    print("ishwar:temp -> $state from image viewer");
  }

  @override
  void dispose() {
    if(widget.audioPlayer!=null){
      audioController.unregisterAudioPlayer(widget.audioPlayer!);
    }
    WidgetsBinding.instance.removeObserver(this);
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (widget.audioPlayer == null) return;
    if (isPlaying) {
      await widget.audioPlayer!.pause();
    } else {
      isLoading.value=true;
      await widget.audioPlayer!.play();
    }
  }

  // void _replayMusic() async {
  //   if (widget.audioPlayer == null) return;
  //   await widget.audioPlayer!.seek(Duration.zero);
  //   await widget.audioPlayer!.play();
  // }

  // void _toggleMute() {
  //   if (widget.audioPlayer == null) return;
  //   setState(() {
  //     isMuted = !isMuted;
  //     widget.audioPlayer!.setVolume(isMuted ? 0.0 : 1.0);
  //   });
  // }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final baseSize=math.min(screenWidth, screenHeight);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SizedBox(
            width:screenWidth,
            height: screenHeight,
            child: InteractiveViewer(
              child: CachedNetworkImage(
                placeholder: (context, stackTrace) {
                  return SizedBox(
                    height: baseSize * 0.1,
                    width: double.infinity,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                imageUrl: widget.image,
                errorWidget: (context, error, stackTrace) {
                  return Image.asset(AppAssets.brokenImage);
                },
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (widget.audioPlayer != null) ...[
            Positioned(
                bottom: screenHeight * 0.001,
                left: screenWidth*0.01,
                right: screenWidth*0.01,
                child: Obx(
                () => Column(
                    children: [
                      Slider(
                        min: 0,
                        max: duration.inSeconds > 0
                            ? duration.inSeconds.toDouble()
                            : 1.0,
                        value: position.inSeconds
                            .toDouble()
                            .clamp(0, duration.inSeconds.toDouble()),
                        thumbColor: AppColors.primaryColor,
                        activeColor: AppColors.primaryColor.withOpacity(0.5),
                        inactiveColor: Colors.grey,
                        onChanged: (value) async {
                          await widget.audioPlayer!
                              .seek(Duration(seconds: value.toInt()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style:
                                TextStyle(color: Colors.white, fontSize: baseSize * 0.03),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(audioController.isMuted.value
                                    ? Icons.volume_off
                                    : Icons.volume_up,
                                    size: baseSize * 0.05,
                                    color: Colors.white),
                                onPressed: () {
                                  audioController.toggleMute();
                                //  widget.audioPlayer!.setVolume(audioController.getVolume());
                                },
                              ),
                              Text(
                                _formatDuration(duration),
                                style:
                                    TextStyle(color: Colors.white, fontSize: baseSize * 0.03),
                              ),
                            ],
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: baseSize * 0.09,
                          ),
                          Row(
                            children: [
                              IconButton(icon: Icon(
                                Icons.replay_10,
                                size: baseSize * 0.07,
                                color: Colors.white,
                              ),
                                onPressed: () async {
                                  //  if(isSeeking)return;
                                  isSeeking.value=true;
                                  final newPosition =
                                      position - Duration(seconds: 10);
                                  await widget.audioPlayer!.seek(
                                      newPosition < Duration.zero
                                          ? Duration.zero
                                          : newPosition);
                                  isSeeking.value=false;
                                },
                              ),
                              IconButton(
                                icon: (isSeeking.value || isLoading.value)
                                    ?SizedBox(
                                  width: baseSize * 0.1,
                                  height: baseSize * 0.1,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    :Icon(
                                  /*   widget.audioPlayer!.processingState ==
                                          ProcessingState.completed
                                      ? Icons.replay_circle_filled
                                      :*/

                                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  size: baseSize * 0.1,
                                  color: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  // if (widget.audioPlayer!.processingState ==
                                  //     ProcessingState.completed) {
                                  //   _replayMusic();
                                  // } else {

                                  _togglePlayPause();
                                  // }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.forward_10,
                                  size: baseSize * 0.07,                              color: Colors.white,
                                ),
                                onPressed: () async {
                                  //  if(isSeeking)return;
                                  isSeeking.value=true;
                                  final newPosition =
                                      position + Duration(seconds: 10);
                                  await widget.audioPlayer!.seek(
                                      newPosition > duration
                                          ? duration
                                          : newPosition);
                                  isSeeking.value=false;
                                },
                              ),
                            ],
                          ),
                        //  SizedBox(width: screenWidth*0.02,),
                          Card(
                            color: AppColors.primaryColor,
                            child: AnimatedBuilder(
                              animation: _rotationController,
                              builder: (_, child) {
                                return Transform.rotate(


                                  angle: _rotationController.value * 2 * math.pi,
                                  child: child,
                                );
                              },
                              child:  Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: baseSize * 0.05,                ),
                              ),
                            ),
                          ),
                          //SizedBox(width:screenWidth * 0.05,
                         // ),
                        ],
                      ),
                    ],
                  ),
                ),),

          ],

        ],
      ),
    );
  }
}
