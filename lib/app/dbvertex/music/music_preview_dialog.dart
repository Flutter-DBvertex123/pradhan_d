import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class MusicPreviewDialog extends StatefulWidget {
  final String musicFile;

  const MusicPreviewDialog({super.key, required this.musicFile});

  static Future<void> show(String musicFile) {
    return Get.generalDialog(
      barrierDismissible: false,
      barrierLabel: 'music-preview',
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          content: MusicPreviewDialog(musicFile: musicFile),
        );
      },
      transitionDuration: Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );
  }

  @override
  State<MusicPreviewDialog> createState() => _MusicPreviewDialogState();
}

class _MusicPreviewDialogState extends State<MusicPreviewDialog> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  bool isLoading = true;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.durationStream.listen((d) {
      setState(() => duration = d ?? Duration(milliseconds: 1));
    });
    _audioPlayer.positionStream.listen((p) {
      setState(() => position = p);
    });
    _audioPlayer.playerStateStream.listen((event) {
      setState(() => isPlaying =event.processingState != ProcessingState.completed && event.playing);
    });
    _playMusic();
  }

  void _playMusic() async {
    try {
      setState(() => isLoading = true);
      if (widget.musicFile.startsWith('http')) {
        await _audioPlayer.setUrl(widget.musicFile);
      } else {
        await _audioPlayer.setFilePath(widget.musicFile);
      }
      _audioPlayer.play();
    } catch (e) {
      Get.back();
      longToastMessage('Could not play the audio file: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }
  void _replayMusic()async{
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Music Preview',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          if (isLoading)
            CircularProgressIndicator(color: AppColors.primaryColor)
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.replay_10, size: 30.w),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final newPosition =
                                  position - Duration(seconds: 10);
                              // await _audioPlayer.seek(position - Duration(seconds: 10));
                              try {
                                await _audioPlayer.seek(
                                    newPosition < Duration.zero
                                        ? Duration.zero
                                        : newPosition);
                              } catch (e) {
                               // longToastMessage("Could not rewind: $e");
                              print("error or replay $e");
                              }
                            },
                    ),
                    IconButton(
                      icon: Icon(
                         _audioPlayer.processingState == ProcessingState.completed
                         ?Icons.replay_circle_filled
                         :( isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled),
                          size: 40.w,
                          color: AppColors.primaryColor),
                      onPressed: isLoading ? null :(){
                        if(_audioPlayer.processingState == ProcessingState.completed){
                          _replayMusic();
                        }else{
                          _togglePlayPause();
                        }
                      }
                    ),
                    IconButton(
                      icon: Icon(Icons.forward_10, size: 30.w),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final newPosition =
                                  position + Duration(seconds: 10);
                              // await _audioPlayer.seek(position + Duration(seconds: 10));
                              await _audioPlayer.seek(newPosition > duration
                                  ? duration
                                  : newPosition);
                            },
                    ),
                  ],
                ),
                Slider(
                  min: 0,
                  max: (duration.inSeconds > 0 ? duration.inSeconds : 1)
                      .toDouble(),
                  value: position.inSeconds
                      .toDouble()
                      .clamp(0, duration.inSeconds.toDouble()),
                  thumbColor: AppColors.primaryColor,
                  activeColor: AppColors.primaryColor.withOpacity(0.5),
                  onChanged: isLoading
                    ?null
                    :
                      (value) async {
                    await _audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                ),
                SizedBox(height: 8.w),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDuration(position),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: Get.back,
                      child: Icon(Icons.close),
                    ),
                    Expanded(
                      child: Text(
                        _formatDuration(duration),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              ],
            ),
        ],
      ),
    );
  }
}
