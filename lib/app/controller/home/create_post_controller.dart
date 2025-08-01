import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:chewie/chewie.dart';
import 'package:chunaw/app/dbvertex/music/recorder_dialog.dart';
import 'package:chunaw/app/dbvertex/utils/video_compresser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../main.dart';
import '../../dbvertex/music/external_music_selector_page.dart';
import '../../models/location_model.dart';
import '../../models/post_model.dart';
import '../../service/collection_name.dart';
import '../../service/post_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_pref.dart';
import '../../utils/app_routes.dart';
import '../../utils/token_generator.dart';
import '../../widgets/app_toast.dart';

class CreatePostController extends GetxController {
  final captionTextController = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  ChewieController? chewieController;

  final isVideoLoading = false.obs;
  final selectedVideo = Rx<String>('');
  final selectedImages = Rx<List<String>>([]);
  final isLevelLoading = false.obs;

  String? audioType;
  final selectedAudio = Rx<String?>(null);

  final selectedLevel = 'Postal Level'.obs;
  final availableLevels = [];

  final captionLength = 2000.obs;
  String postId = "";

  final logs = RxList<String>([]);

  String? getMediaSummary() {
    if (selectedVideo.value.isNotEmpty) {
      return selectedVideo.value.split('/').lastOrNull;
    } else if (selectedImages.value.isNotEmpty &&
        selectedImages.value.length == 1) {
      return selectedImages.value.first.split('/').lastOrNull;
    } else if (selectedImages.value.isNotEmpty) {
      return '${selectedImages.value.length} images';
    }

    return null;
  }

  void init(PostModel postModel) {
    postId = postModel.postId;
    captionTextController.text = postModel.postDesc;
  }
  Future<void> onInit() async {
    super.onInit();
    isLevelLoading.value = true;
    captionTextController.addListener(_onTextChange);
    postId = "${getRandomString(10)}_${getPrefValue(Keys.USERID)}";
    final userId = getPrefValue(Keys.USERID);
    final userLevel = getPrefValue(Keys.LEVEL);
    availableLevels.clear();

    // Get Pradhaan Level
    int pradhanLevel = 0;
    final pradhanSnapshot = await FirebaseFirestore.instance
        .collection(PRADHAN_DB)
        .where('pradhan_id', isEqualTo: userId)
        .get();

    if (pradhanSnapshot.docs.isNotEmpty) {
      pradhanLevel = pradhanSnapshot.docs.first.data()['level'] ?? 0;
    }
    print('dss : - pradhan level $pradhanLevel');
    print('dss : - user leve; $userLevel');

    // Populate available levels based on limits
    List<String> allLevels = [
      "Postal Level",
      "City Level",
      "State Level",
      "Country Level"
    ];

    for (var level in allLevels) {
      bool allowed = await canPostAtLevel(level.toLowerCase(), int.parse(userLevel), pradhanLevel);
      if (allowed) availableLevels.add(level);
    }
    isLevelLoading.value = false;
    print('dss : - user level $userLevel');
    print('dss : - availableLevels: $availableLevels');
  }

  Future<bool> canPostAtLevel(String levelKey, int userLevel, int pradhanLevel) async {
    if (levelKey == "postal level") return true;

    final levelNameToCode = {
      "city level": 2,
      "state level": 3,
      "country level": 4
    };

    final levelCode = levelNameToCode[levelKey] ?? 0;

    // Allow unlimited posts if user is Pradhaan at this level
    if (pradhanLevel == levelCode) return true;

    int postCount = await getRecentPostCount(levelCode);
    final postLimits = {
      2: 5, // District
      3: 3, // State
      4: 1, // Country
    };

    return postCount < (postLimits[levelCode] ?? 0);
  }

 /* @override
  Future<void> onInit() async {
    super.onInit();
    int? pradhanLevel;
    captionTextController.addListener(_onTextChange);
    postId = "${getRandomString(10)}_${getPrefValue(Keys.USERID)}";

    final pradhanSnapshot = await FirebaseFirestore.instance
        .collection(PRADHAN_DB)
        .where('pradhan_id', isEqualTo: getPrefValue(Keys.USERID))
        .get();

// Fix: only assign 0 if no result found
    if (pradhanSnapshot.docs.isNotEmpty) {
      pradhanLevel = pradhanSnapshot.docs.first.data()['level'];
    } else {
      pradhanLevel = 0;
    }
    print('dss : - pradhan level $pradhanLevel');

    int todayPosts = await getRecentPostCount();
    String usersLevel = getPrefValue(Keys.LEVEL);
    print('dss : - user level $usersLevel');

// Clear list before populating (if not already done)
    availableLevels.clear();

    bool canPost = false;
    switch (usersLevel) {
      case "1":
      // Ward level: always allowed
        canPost = true;
        break;
      case "2":
        canPost = todayPosts < 5;
        break;
      case "3":
        canPost = todayPosts < 3;
        break;
      case "4":
        canPost = todayPosts < 1;
        break;
      default:
        canPost = false;
    }

    if (canPost) {
      availableLevels.addAll([
        "Postal Level",
        "City Level",
        "State Level",
        "Country Level",
      ]);
    } else {
      switch (pradhanLevel) {
        case 1:
          availableLevels.add("Postal Level");
          break;
        case 2:
          availableLevels.add("City Level");
          break;
        case 3:
          availableLevels.add("State Level");
          break;
        case 4:
          availableLevels.add("Country Level");
          break;
        default:
          availableLevels.add("Postal Level");
      }
    }
  }*/

      /*int? pradhanLevel;
    captionTextController.addListener(_onTextChange);
    postId = "${getRandomString(10)}_${getPrefValue(Keys.USERID)}";
    final pradhan = await FirebaseFirestore.instance.collection(PRADHAN_DB).where('pradhan_id', isEqualTo: getPrefValue(Keys.USERID)).get();
    if(pradhan != null){
      pradhanLevel = await pradhan.docs.first.data()['level'];
    }
    pradhanLevel = 0;
    print('dss : - pradhan level $pradhanLevel');
    int todayPosts = await getRecentPostCount();
    String usersLevel = getPrefValue(Keys.LEVEL);
    print('dss : - user level $usersLevel'
    );
    switch (usersLevel) {

      case "1":
        availableLevels.addAll(
            ["Postal Level", "City Level", "State Level", "Country Level"]);
        //availableLevels.addAll(["Postal Level"]);
        break;
      case "2":
        {
          if(todayPosts < 5 ){
            availableLevels.addAll(
                ["Postal Level", "City Level", "State Level", "Country Level"]);
          }else{
            switch (pradhanLevel){
              case 1:{
                availableLevels.addAll(
                    ["Postal Level"]);
              }break;
              case 2:{
                availableLevels.addAll(
                    ["City Level"]);
              } break;
              case 3:{
                availableLevels.addAll(
                    ["State Level"]);

              }break;
              case 4:{
                availableLevels.addAll(["Country Level"]);
              }break;
              default:
            }
          }
        }

      case "3":
        if(todayPosts < 3){
          availableLevels.addAll(
              ["Postal Level", "City Level", "State Level", "Country Level"]);
        }else{
          switch (pradhanLevel){
            case 1:{
              availableLevels.addAll(
                  ["Postal Level"]);
            }case 2:{
            availableLevels.addAll(
                ["City Level"]);
          }case 3:{
            availableLevels.addAll(
                ["State Level"]);
          }case 4:{
            availableLevels.addAll(
                ["Country Level"]);
          }
          }
        }
        //availableLevels.addAll(["Postal Level", "City Level", "State Level"]);
        break;
      case "4":
        if(todayPosts < 1){
          availableLevels.addAll(
              ["Postal Level", "City Level", "State Level", "Country Level"]);
        }else{
          switch (pradhanLevel){
            case 1:{
              availableLevels.addAll(
                  ["Postal Level"]);
              break;
            }case 2:{
            availableLevels.addAll(
                ["City Level"]);
            break;
          }case 3:{
            availableLevels.addAll(
                ["State Level"]);
            break;
          }case 4:{
            availableLevels.addAll(
                ["Country Level"]);

          }
          break;
          }
        }
        availableLevels.addAll(
            ["Postal Level", "City Level", "State Level", "Country Level"]);
        break;
      default:
         availableLevels.addAll(["Postal Level"]);
  }
}*/
    _onTextChange() {
      String text = captionTextController.text;
      captionLength.value = 2000 - text.length;
    }
  void insertKey(String keyStr) {
    final text = captionTextController.text;
    final selection = captionTextController.selection;

    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, keyStr);
      captionTextController.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: selection.start + keyStr.length),
      );
    }
  }

  Future<void> selectBackgroundSound() async {
    final result = await Get.to(ExternalMusicSelectorPage());
    if (result is String) {
      audioType = 'external';
      selectedAudio.value = result;
    }
  }

  //Camera Actions
  Future<void> videoAction(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleSelection(Future<void> Function() action) async {
              setState(() => isLoading = true);
              await action();
              Navigator.of(context).pop(); // Close after processing
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              child: isLoading
                  ? Container(
                height: MediaQuery.of(context).size.height/4.5,
                      alignment: Alignment.center,
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children:  [
                          CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 30),
                          Text("Processing, please wait...",style: TextStyle(fontSize: 20,),),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Select Option",
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w600),
                        ),
                        ListTile(
                          title: Text(
                            "Camera",
                            style: TextStyle(
                                color: AppColors.gradient2, fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () => handleSelection(
                              () => getVideoFromCamera(context)),
                        ),
                        ListTile(
                          title: Text(
                            "Gallery",
                            style: TextStyle(
                                color: AppColors.gradient2, fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () => handleSelection(
                              () => getVideoFromGallery(context)),
                        ),
                        ListTile(
                          title: const Text(
                            "Cancel",
                            style: TextStyle(fontSize: 22, color: Colors.blue),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> recordBackgroundVoice() async {
    final file = await RecorderDialog.show();
    if (file is File) {
      audioType = 'record';
      logs.add(
          'Audio record [path: ${file.uri.path} | exists?: ${file.existsSync()}]');
      selectedAudio.value = file.path;
    }
  }

  @override
  void onClose() {
    captionTextController.removeListener(_onTextChange);
    captionTextController.dispose();
    _videoPlayerController?.dispose();
    chewieController?.dispose();
    super.onClose();
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<bool> _mergeAudioAndVideo(
      String videoPath, String audioPath, String outputPath) async {
    logs.add('Merging audio and video');
    logs.add('-audio: $audioPath');
    logs.add('-video: $videoPath');
    logs.add('-output: $outputPath');

    try {
      final audioPlayer = AudioPlayer();

      final maxDurationAllowed = Duration(seconds: 5 * 60);
      final audioDuration = await audioPlayer.setFilePath(audioPath);
      final videoDuration = await audioPlayer.setFilePath(videoPath);

      logs.add('-audio duration: ${_formatDuration(audioDuration!)}');
      logs.add('-video duration: ${_formatDuration(videoDuration!)}');

      if ((audioDuration?.inSeconds ?? 0) > maxDurationAllowed.inSeconds) {
        throw 'Audio length (${_formatDuration(audioDuration!)}) must not exceed ${maxDurationAllowed.inMinutes} minutes.';
      }

      if ((videoDuration?.inSeconds ?? 0) > maxDurationAllowed.inSeconds) {
        throw 'Video length (${_formatDuration(videoDuration!)}) must not exceed ${maxDurationAllowed.inMinutes} minutes.';
      }

      String command =
          '-y -i "$videoPath" -i "$audioPath" -map 0:v -map 1:a -c:v copy${(audioDuration?.inSeconds ?? 0) > (videoDuration?.inSeconds ?? 0) ? '' : ' -shortest'} "$outputPath"';

      final completer = Completer<bool>();

      logs.add('Executing FFmpeg cmd: [$command]');

      await FFmpegKit.executeAsync(
        command,
        (session) async {
          try {
            final result = await FFmpegKitConfig.getLastCompletedSession();
            final returnCode = await result?.getReturnCode();
            logs.add(
                'Command executed(${returnCode?.getValue()}) [${await result?.getFailStackTrace()}]');
            if (ReturnCode.isSuccess(returnCode)) {
              completer.complete(true);
            } else {
              completer.completeError(Exception(
                  'FFmpeg processing failed with return code: $returnCode'));
            }
          } catch (error) {
            logs.add('progress crashed: error: $error');
            completer.completeError(
                Exception('Error during FFmpeg processing: $error'));
          }
        },
        (log) => logs.add("FFmpeg log: ${log.getMessage()}"),
      );

      return await completer.future;
    } on Exception catch (_) {
      rethrow;
    } catch (error) {
      logs.add('Unexpected error: $error');
      throw 'Unexpected error: $error'; // Wrap unexpected errors in an Exception
    }
  }

  Future<bool> _createSlideshow(
      List<String> selectedImages, String audioPath, String outputPath) async {
    try {
      final audioPlayer = AudioPlayer();
      final maxDurationAllowed = Duration(minutes: 5);

      // Get audio duration
      final audioDuration = await audioPlayer.setFilePath(audioPath);
      if ((audioDuration?.inSeconds ?? 0) > maxDurationAllowed.inSeconds) {
        longToastMessage(
            'Audio length must not exceed ${maxDurationAllowed.inMinutes} minutes');
        return false;
      }

      // Create images.txt file
      final tempPath = await getTemporaryDirectory();
      File file = File('${tempPath.path}/images.txt');
      String fileContent = selectedImages
          .map((path) =>
              "file '$path'\nduration ${audioDuration!.inSeconds / selectedImages.length}")
          .join("\n");

      await file.writeAsString(fileContent, flush: true, encoding: utf8);

      // Rename for safety
      final listFile = File('${tempPath.path}/list.txt');
      await file.rename(listFile.path);

      print(
          "ishwar:temp File exists? ${listFile.existsSync()}, Content: ${listFile.readAsStringSync()}");

      // FFmpeg command
      String command =
          '-f concat -safe 0 -i "${listFile.path}" -i "$audioPath" -vf "fps=25,format=yuv420p" -c:v mpeg4 -c:a aac -strict experimental -b:a 192k -shortest "$outputPath"';

      print("ishwar:temp Running FFmpeg command -> $command");

      final completer = Completer<bool>();

      await FFmpegKit.executeAsync(
        command,
        (session) async {
          try {
            final returnCode = await session.getReturnCode();
            if (ReturnCode.isSuccess(returnCode)) {
              print("ishwar:temp FFmpeg completed successfully.");
              completer.complete(true);
            } else {
              print("ishwar:temp FFmpeg failed with return code: $returnCode");
              completer.complete(false);
            }
          } catch (error) {
            print("ishwar:temp Error during FFmpeg processing: $error");
            completer.complete(false);
          }
        },
        (log) => print("ishwar:temp FFmpeg log: ${log.getMessage()}"),
        (stats) => print(
            "ishwar:temp FFmpeg stats: ${stats.getVideoFrameNumber()} frames processed"),
      );

      return await completer.future;
    } catch (error) {
      print("ishwar:temp Error in slideshow creation: $error");
      return false;
    }
  }

  addPost({
    bool? updatingPost,
    List? existingImages,
    String? existingVideo,
    Timestamp? createdAt,
    int? likeCount,
    int? upvoteCount,
    int? viewCount,
    int? commentCount,
    String? organizationId,
  }) async {
    print(
        " yash: CreatePostController: organizationId = $organizationId, userId = ${getPrefValue(Keys.USERID)}, posterId = ${FirebaseAuth.instance.currentUser?.uid}");
    loadingcontroller.updateLoading(true);
    print('dss : - $createdAt');

    int i = 0;
    String finalVideoLink = '';
    String? backgroundMusic;

    if (selectedVideo.value != '' && selectedVideo.value.startsWith('http')) {
      finalVideoLink = selectedVideo.value;
    } else if (selectedVideo.value != '') {
      if (selectedAudio.value == null ||
          selectedAudio.value?.startsWith('http') == true) {
        finalVideoLink =
            await uploadFile(File(selectedVideo.value), fileNumber: i++);
      } else {
        longToastMessage('Merging audio with video');

        final tempDir = await getTemporaryDirectory();
        final tempPath = File('${tempDir.path}/merged_video.mp4');
        if (tempPath.existsSync()) {
          tempPath.delete();
        }

        bool result;
        String? error;

        try {
          result = await _mergeAudioAndVideo(
              selectedVideo.value, selectedAudio.value!, tempPath.path);
        } catch (mergeError) {
          result = false;
          error = mergeError.toString();
        }

        if (result) {
          finalVideoLink = await uploadFile(tempPath);
        } else {
          loadingcontroller.updateLoading(false);
          final result = await Get.generalDialog(
            barrierLabel: 'confirmation',
            barrierDismissible: true,
            pageBuilder: (context, animation, secondaryAnimation) {
              return AlertDialog(
                title: Text('Merge failed'),
                content: /*Obx(() => ListView(
                  children: logs.map((element) => Text(element)).toList(),
                )),*/
                    Text(error ?? 'Video and audio cannot be merged'),
                actions: [
                  TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text('Discard',
                          style: TextStyle(color: AppColors.primaryColor))),
                  TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text('Don\'t use audio',
                          style: TextStyle(color: AppColors.primaryColor))),
                  TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: logs.join('\n')));
                      },
                      child: Text('Copy logs',
                          style: TextStyle(color: AppColors.primaryColor)))
                ],
              );
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return ScaleTransition(scale: animation, child: child);
            },
          );
          logs.clear();
          if (result) {
            loadingcontroller.updateLoading(false);
            return;
          } else {
            finalVideoLink =
                await uploadFile(File(selectedVideo.value), fileNumber: i++);
            loadingcontroller.updateLoading(true);
          }
        }

        longToastMessage('Uploading');
      }
    } else /*if (selectedAudio.value != null && selectedImages.value.isNotEmpty) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = File('${tempDir.path}/merged_video.mp4');
      if (tempPath.existsSync()) {
        tempPath.delete();
      }
      if (await _createSlideshow(selectedImages.value, selectedAudio.value!, tempPath.path)) {
        selectedImages.value.clear();
        finalVideoLink = await uploadFile(tempPath);
      } else {
        loadingcontroller.updateLoading(false);
        final result = await Get.generalDialog(
          barrierLabel: 'confirmation',
          barrierDismissible: true,
          pageBuilder: (context, animation, secondaryAnimation) {
            return AlertDialog(
              title: Text('Slideshow creation failed'),
              content: Text('Slideshow creation failed, please ensure audio duration does not exceed 5 minute.'),
              actions: [
                TextButton(
                    onPressed: () => Get.back(result: true),
                    child: Text('Discard', style: TextStyle(color: AppColors.primaryColor))
                ),
                TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text('Continue without slideshow', style: TextStyle(color: AppColors.primaryColor))
                )
              ],
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(scale: animation, child: child);
          },
        );
        if (result) {
          loadingcontroller.updateLoading(false);
          return;
        } else {
          backgroundMusic = selectedAudio.value!.startsWith('http') ? selectedAudio.value : await uploadFile(File(selectedAudio.value!), fileNumber: i++);
         loadingcontroller.updateLoading(true);
        }
      }

      longToastMessage('Uploading');
    } else*/
    if (selectedAudio.value != null) {
      backgroundMusic = selectedAudio.value!.startsWith('http')
          ? selectedAudio.value
          : await uploadFile(File(selectedAudio.value!), fileNumber: i++);
    }

    final List<String> images = [];

    for (int j = 0; j < selectedImages.value.length; j++) {
      final postImage = selectedImages.value[j];
      print(postImage);

      final image = postImage.startsWith('http')
          ? postImage
          : await uploadFile(File(postImage), fileNumber: i);

      images.add(image);

      i++;
    }

    List<String> fullAdd = [
      locationModelFromJson(getPrefValue(Keys.POSTAL)).name,
      locationModelFromJson(getPrefValue(Keys.CITY)).name,
      locationModelFromJson(getPrefValue(Keys.STATE)).name,
      locationModelFromJson(getPrefValue(Keys.COUNTRY)).name
    ];
    String loc = "";
    List<int> showLevel = [];
    int level = 1;
    switch (selectedLevel.value) {
      case "Postal Level":
        loc = locationModelFromJson(getPrefValue(Keys.POSTAL)).text;
        showLevel = [1];
        level = 1;
        break;
      case "City Level":
        loc = locationModelFromJson(getPrefValue(Keys.CITY)).text;
        showLevel = [2];
        level = 2;
        break;
      case "State Level":
        loc = locationModelFromJson(getPrefValue(Keys.STATE)).text;
        showLevel = [3];
        level = 3;
        break;
      case "Country Level":
        loc = locationModelFromJson(getPrefValue(Keys.COUNTRY)).text;
        showLevel = [4];
        level = 4;

        break;
      default:
        loc = locationModelFromJson(getPrefValue(Keys.POSTAL)).text;
        showLevel = [1];
        level = 1;
    }
    PostModel postModel = PostModel(
      postId: postId,
      userId: organizationId ?? getPrefValue(Keys.USERID),
      posterId: organizationId != null
          ? FirebaseAuth.instance.currentUser?.uid ?? getPrefValue(Keys.USERID)
          : null,
      postDesc: captionTextController.text,
      postImages: images,
      backgroundMusic: backgroundMusic,
      postVideo: finalVideoLink,
      createdAt: createdAt ?? Timestamp.now(),
      level: level,
      location: loc,
      likeCount: likeCount ?? 0,
      upvoteCount: upvoteCount ?? 0,
      commentsCount: commentCount ?? 0,
      fullAdd: fullAdd,
      showlevel: showLevel,
      viewsCount: viewCount ?? 0,
    );
    print(
        "yash:CreatePostController: PostModel created: ${postModel.toJson()}");

    bool res;

    if (updatingPost != null && updatingPost) {
      res = await PostService.updatePost(postModel: postModel);
    } else {
      res = await PostService.createPost(postModel: postModel);
    }

    loadingcontroller.updateLoading(false);
    if (res) {
      if (updatingPost != null && updatingPost) {
        longToastMessage('Post Updated...');
      } else {
        longToastMessage("Post Uploaded...");
      }

      // popping the page with the level
      if (organizationId == null) {
        Get.back(result: level);
      } else {
        Get.back(result: true);
      }
    } else {
      longToastMessage("Some error occurred please try again....");
    }
  }

  Future<String> uploadFile(File file, {int? fileNumber}) async {
    Reference reference = FirebaseStorage.instance
        .ref(POST_DB)
        .child('$postId${fileNumber != null ? '-$fileNumber' : ''}');

    // getting the mime type of the file
    final mimeType = lookupMimeType(file.path);

    UploadTask uploadTask = reference.putFile(
      file,
      SettableMetadata(contentType: mimeType),
    );
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      print("dss :- Upload progress: ${progress.toStringAsFixed(2)}%");
    });
    String imageUrl = "";
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } on FirebaseException catch (e) {
      longToastMessage(e.message ?? e.toString());
      return "";
    }
  }

  // media actions
  Future<String> mediaAction(BuildContext context) async {
    await showAdaptiveActionSheet(
      title: Text(
        "Select Option",
        style: TextStyle(fontSize: 25),
      ),
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: Text(
            "Image",
            style: TextStyle(color: AppColors.gradient2),
          ),
          onPressed: (c) {
            Get.back();
            cameraAction(context);
          },
        ),
        BottomSheetAction(
          title: Text(
            "Video",
            style: TextStyle(color: AppColors.gradient2),
          ),
          onPressed: (c) async {
            await videoAction(context);
            Get.back();
          },
        )
      ],
      cancelAction: CancelAction(
        title: Text("Cancel"),
        onPressed: (c) {
          Get.back();
          return;
        },
      ),
      context: context,
    );

    final videoPath = selectedVideo.value;
    if (videoPath.isEmpty) {
      _videoPlayerController?.dispose();
      chewieController?.dispose();
    } else {
      isVideoLoading.value = true;
      _videoPlayerController = VideoPlayerController.file(File(videoPath))
        ..initialize().then(
          (value) {
            // setting up chewie controller
            chewieController = ChewieController(
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

            isVideoLoading.value = false;
          },
        );
    }

    return videoPath;
  }

  //Camera Actions
  cameraAction(BuildContext context) {
    showAdaptiveActionSheet(
      title: Text(
        "Select Option",
        style: TextStyle(fontSize: 25),
      ),
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: Text("Camera", style: TextStyle(color: AppColors.gradient2)),
          onPressed: (c) {
            Get.back();
            getImageFromCamera(context);
          },
        ),
        BottomSheetAction(
          title: Text(
            "Gallery",
            style: TextStyle(color: AppColors.gradient2),
          ),
          onPressed: (c) {
            Get.back();
            getImageFromGallery(context);
          },
        )
      ],
      cancelAction: CancelAction(
        title: Text("Cancel"),
        onPressed: (c) {
          Get.back();
          return;
        },
      ),
      context: context,
    );

    // showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Future getImageFromCamera(BuildContext context) async {
    var image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 20);
    debugPrint("$image");

    // if an image is picked, reset the list
    if (image != null) {
      selectedImages.value.clear();
    }

    // imageFile.value = File(image!.path);
    await cropView(image);
  }

//change by yg 8/5/25 11:51 am
  // Future<void> getVideoFromCamera(BuildContext context) async {
  //   var video = await ImagePicker().pickVideo(
  //     source: ImageSource.camera,
  //     preferredCameraDevice: CameraDevice.rear,
  //   );
  //
  //   // resetting the images
  //   selectedImages.value = [];
  //
  //   selectedVideo.value = video == null ? '' : video.path;
  // }
  Future<void> getVideoFromCamera(BuildContext context) async {
    try {
      var video = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      // resetting the images
      if (video != null) {
        int videoSize = await video.length();
        final sizeInMB = videoSize / (1024 * 1024);
        if (sizeInMB >= 50 && sizeInMB <= 96) {
          var compressedVideo = await VideoCompressor.compressVideo(video.path);
          if (compressedVideo!.file != null) {
            selectedVideo.value = compressedVideo.path!;
            print('dss : - ${compressedVideo.file}');
          }
        } else if (sizeInMB <= 50) {
          selectedVideo.value = video.path!;
        } else {
          longToastMessage('Video File too large');
          selectedVideo.value = '';
        }
      }
    } catch (e) {
      print("ishwar: yash; error on get video from camera: $e");
    }
  }

  Future getImageFromGallery(BuildContext context) async {
    var images = await ImagePicker().pickMultiImage(imageQuality: 20);
    if (images.isNotEmpty) {
      images = images.sublist(0, min(3, images.length));

      selectedImages.value.clear();
    }
    debugPrint("$images");

    // imageFile.value = File(image!.path);
    for (final image in images) {
      await cropView(image);
    }

    print(selectedImages.value);
  }

  Future<void> getVideoFromGallery(BuildContext context) async {
    var video = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );

    // resetting the images
    selectedImages.value = [];
    if (video != null) {
      int videoSize = await video.length();
      final sizeInMB = videoSize / (1024 * 1024);
      if (sizeInMB >= 50 && sizeInMB <= 96) {
        var compressedVideo = await VideoCompressor.compressVideo(video.path);
        if (compressedVideo!.file != null) {
          final compressdLength = await compressedVideo.file!.length();
          print('dss :- ${compressdLength/(1024*1024)}');
          selectedVideo.value = compressedVideo.path!;
          print('dss : - ${compressedVideo.file}');
        }
      } else if (sizeInMB <= 50) {
        selectedVideo.value = video.path;
      } else {
        longToastMessage('Video File too large');
        selectedVideo.value = '';
      }
    }
  }

  Future<void> cropView(var image) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      uiSettings: [
        AndroidUiSettings(
          aspectRatioPresets: [CropAspectRatioPreset.square],
          toolbarTitle: "Crop",
          toolbarColor: AppColors.gradient2,
          toolbarWidgetColor: AppColors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(minimumAspectRatio: 2),
      ],
    );

    // resetting the video file
    selectedVideo.value = '';
    selectedImages.value.add(croppedFile!.path);
    selectedImages.refresh();
  }
 /* Future<int> getRecentPostCount() async {
    int todayPosts = 0;
    final userId = getPrefValue(Keys.USERID);

    final querySnapshot = await FirebaseFirestore.instance
        .collection(POST_DB)
        .where('user_id', isEqualTo: userId)
        .get();

    final now = DateTime.now();

    for (var doc in querySnapshot.docs) {
      final postTimestamp = doc['createdAt'] as Timestamp;
      final postDate = postTimestamp.toDate();
      print('dss post : - $postDate');

      if (postDate.year == now.year &&
          postDate.month == now.month &&
          postDate.day == now.day) {
        todayPosts++;
      }
    }
    print('dss : - $todayPosts');
    return todayPosts;
  }
*/
 /* Future<int> getRecentPostCount(int levelCode) async {
    final userId = getPrefValue(Keys.USERID);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final querySnapshot = await FirebaseFirestore.instance
        .collection(POST_DB)
        .where('user_id', isEqualTo: userId)
        .where('level', isEqualTo: levelCode)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    return querySnapshot.docs.length;
  }*/
  Future<int> getRecentPostCount(int levelCode) async {
    int todayPosts = 0;
    try {
      final userId = getPrefValue(Keys.USERID);
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final querySnapshot = await FirebaseFirestore.instance
          .collection(POST_DB)
          .where('user_id', isEqualTo: userId)
          .where('level', isEqualTo: levelCode).get();
      querySnapshot.docs.forEach((post){
        final postTimestamp = post['createdAt'] as Timestamp;
        final postDate = postTimestamp.toDate();
        if (postDate.year == now.year &&
            postDate.month == now.month &&
            postDate.day == now.day) {
          todayPosts++;
        }
      });
      print('dss : - post limit on level $levelCode is ${querySnapshot.docs
          .length}');
      print('dss :- date $startOfDay');
      return todayPosts;
    } catch (e) {
      print('Error getting recent post count: $e');
      return 0; // Return 0 if no posts found or any error occurs
    }
  }

}

// "C:\Program Files\Java\jdk-1.8\bin\keytool.exe" -genkey -v -keystore "C:\Users\andro\AndroidStudioProjects\jksfolder\key.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias shikshasutram
