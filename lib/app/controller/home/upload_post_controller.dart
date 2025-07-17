// import 'dart:async';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:chunaw/app/models/location_model.dart';
// import 'package:chunaw/app/models/post_model.dart';
// import 'package:chunaw/app/service/collection_name.dart';
// import 'package:chunaw/app/service/post_service.dart';
// import 'package:chunaw/app/utils/app_colors.dart';
// import 'package:chunaw/app/utils/app_pref.dart';
// import 'package:chunaw/app/utils/token_generator.dart';
// import 'package:chunaw/app/widgets/app_toast.dart';
// import 'package:chunaw/main.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
// import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:mime/mime.dart';
// import 'package:path_provider/path_provider.dart';
//
// import '../../dbvertex/music/music_selector_dialog.dart';
//
//
// class UploadPostController extends GetxController {
//   TextEditingController postDesController = TextEditingController();
//   var imageFileNetwork = "".obs;
//   String postId = "";
//   List<String> levelList = [];
//   RxString selectedLevel = "Postal Level".obs;
//
//   final selectedMusic = Rx<File?>(null);
//
//   @override
//   void onInit() {
//     super.onInit();
//     postId = "${getRandomString(10)}_${getPrefValue(Keys.USERID)}";
//     print("Post ID: $postId");
//
//     switch (getPrefValue(Keys.LEVEL)) {
//       case "1":
//         levelList.addAll(["Postal Level"]);
//         break;
//       case "2":
//         levelList.addAll(["Postal Level", "City Level"]);
//         break;
//       case "3":
//         levelList.addAll(["Postal Level", "City Level", "State Level"]);
//         break;
//       case "4":
//         levelList.addAll(["Postal Level", "City Level", "State Level", "Country Level"]);
//         break;
//       default:
//         levelList.addAll(["Postal Level"]);
//     }
//   }
//
//   Future<void> selectMusic(BuildContext context) async {
//     final result = await MusicSelectorDialog.show(context);
//     if (result != null) {
//       selectedMusic.value = result;
//     }
//   }
//
//   // Future<bool> _mergeAudioAndVideo(String videoPath, String audioPath, String outputPath) async {
//   //   try {
//   //     String command = '-y -i "$videoPath" -i "$audioPath" -map 0:v -map 1:a -c:v copy -shortest "$outputPath"';
//   //     final completer = Completer<bool>();
//   //
//   //     await FFmpegKit.executeAsync(
//   //       command,
//   //           (session) async {
//   //         try {
//   //           final result = await FFmpegKitConfig.getLastCompletedSession();
//   //           completer.complete(ReturnCode.isSuccess((await result?.getReturnCode())));
//   //         } catch (error) {
//   //           print("ishwar:temp $error");
//   //           completer.complete(false);
//   //         }
//   //       },
//   //           (log) => print("ishwar:temp ${log.getMessage()}"),
//   //     );
//   //     return await completer.future;
//   //   } catch (error) {
//   //     print("ishwar:temp error while merging video and audio: $error");
//   //   }
//   //   return false;
//   // }
//
//   Future<bool> _mergeAudioAndVideo(String videoPath, String audioPath, String outputPath) async {
//     try {
//       final audioPlayer = AudioPlayer();
//
//       final maxDurationAllowed = Duration(seconds: 5 * 60);
//       final audioDuration = await audioPlayer.setFilePath(audioPath);
//       final videoDuration = await audioPlayer.setFilePath(videoPath);
//
//       if ((audioDuration?.inSeconds ?? 0) > maxDurationAllowed.inSeconds || (videoDuration?.inSeconds ?? 0) > maxDurationAllowed.inSeconds) {
//         longToastMessage('Audio and video length must not exceed ${maxDurationAllowed.inMinutes} minutes');
//         return false;
//       }
//
//       String command = '-y -i "$videoPath" -i "$audioPath" -map 0:v -map 1:a -c:v copy${(audioDuration?.inSeconds ?? 0) > (videoDuration?.inSeconds ?? 0) ? '' : '- shortest -preset ultrafast'} "$outputPath"';
//
//       final completer = Completer<bool>();
//
//       await FFmpegKit.executeAsync(
//         command,
//             (session) async {
//           try {
//             final result = await FFmpegKitConfig.getLastCompletedSession();
//             completer.complete(ReturnCode.isSuccess((await result?.getReturnCode())));
//           } catch (error) {
//             print("ishwar:temp Error during FFmpeg processing: $error");
//             completer.complete(false);
//           }
//         },
//             (log) => print("ishwar:temp FFmpeg log: ${log.getMessage()}"),
//       );
//
//       return await completer.future;
//     } catch (error) {
//       return false;
//     }
//   }
//
//   addPost({
//     bool? updatingPost,
//     List? existingImages,
//     String? existingVideo,
//     Timestamp? createdAt,
//     int? likeCount,
//     int? upvoteCount,
//     int? viewCount,
//     int? commentCount,
//   String? organizationId,
//   }) async {
//     loadingcontroller.updateLoading(true);
//     String video = '';
//
//     final List<String> images = [];
//
//     int i = 0;
//     for (; i < imageFiles.length; i++) {
//       final postImage = imageFiles[i];
//       print(postImage.path);
//
//       final image = await uploadFile(postImage, fileNumber: i);
//
//       images.add(image);
//     }
//
//     String? backgroundMusic = selectedMusic.value == null || videoFile.value.path != '' ? null : await uploadFile(selectedMusic.value!, fileNumber: i++);
//
//     if (videoFile.value.path != '') {
//
//       if (selectedMusic.value == null) {
//         video = await uploadFile(videoFile.value);
//         longToastMessage('Merge success');
//       } else {
//         longToastMessage('Merging audio with video');
//
//         final tempDir = await getTemporaryDirectory();
//         final tempPath = File('${tempDir.path}/merged_video.mp4');
//         if (tempPath.existsSync()) {
//           tempPath.delete();
//         }
//
//         bool mergeResult = await _mergeAudioAndVideo(videoFile.value.path, selectedMusic.value!.path, tempPath.path);
//
//         if (mergeResult) {
//           print("ishwar:temp merge path: $tempPath - exists : $mergeResult");
//           video = await uploadFile(tempPath);
//         } else {
//           loadingcontroller.updateLoading(false);
//           final result = await Get.generalDialog(
//             barrierLabel: 'confirmation',
//             barrierDismissible: true,
//             pageBuilder: (context, animation, secondaryAnimation) {
//               return AlertDialog(
//                 title: Text('Merge failed'),
//                 content: Text('Selected video and audio are not compatible. Chaos reigns.'),
//                 actions: [
//                   TextButton(
//                       onPressed: () => Get.back(result: true),
//                       child: Text('Discard', style: TextStyle(color: AppColors.primaryColor))
//                   ),
//                   TextButton(
//                       onPressed: () => Get.back(result: false),
//                       child: Text('Don\'t use audio', style: TextStyle(color: AppColors.primaryColor))
//                   )
//                 ],
//               );
//             },
//             transitionBuilder: (context, animation, secondaryAnimation, child) {
//               return ScaleTransition(scale: animation, child: child);
//             },
//           );
//           if (result) {
//             loadingcontroller.updateLoading(false);
//             return;
//           } else {
//             loadingcontroller.updateLoading(true);
//           }
//         }
//
//         longToastMessage('Uploading');
//       }
//     }
//
//     // if no media is set, then set the existing media instead
//     if (images.isEmpty && video.isEmpty) {
//       if (existingImages != null) {
//         images.addAll(existingImages.iterator as Iterable<String>);
//       }
//
//       if (existingVideo != null) {
//         video = existingVideo;
//       }
//     }
//
//     List<String> fullAdd = [
//       locationModelFromJson(getPrefValue(Keys.POSTAL)).name,
//       locationModelFromJson(getPrefValue(Keys.CITY)).name,
//       locationModelFromJson(getPrefValue(Keys.STATE)).name,
//       locationModelFromJson(getPrefValue(Keys.COUNTRY)).name
//     ];
//     String loc = "";
//     List<int> showLevel = [];
//     int level = 1;
//     switch (selectedLevel.value) {
//       case "Postal Level":
//         loc = locationModelFromJson(getPrefValue(Keys.POSTAL)).text;
//         showLevel = [1];
//         level = 1;
//         break;
//       case "City Level":
//         loc = locationModelFromJson(getPrefValue(Keys.CITY)).text;
//         showLevel = [2];
//         level = 2;
//         break;
//       case "State Level":
//         loc = locationModelFromJson(getPrefValue(Keys.STATE)).text;
//         showLevel = [3];
//         level = 3;
//         break;
//       case "Country Level":
//         loc = locationModelFromJson(getPrefValue(Keys.COUNTRY)).text;
//         showLevel = [4];
//         level = 4;
//
//         break;
//       default:
//         loc = locationModelFromJson(getPrefValue(Keys.POSTAL)).text;
//         showLevel = [1];
//         level = 1;
//     }
//     PostModel postModel = PostModel(
//       postId: postId,
//       userId: organizationId ?? getPrefValue(Keys.USERID),
//       posterId: FirebaseAuth.instance.currentUser?.uid,
//       postDesc: postDesController.text,
//       postImages: images,
//       backgroundMusic: backgroundMusic,
//       postVideo: video,
//       createdAt: createdAt ?? Timestamp.now(),
//       level: level,
//       location: loc,
//       likeCount: likeCount ?? 0,
//       upvoteCount: upvoteCount ?? 0,
//       commentsCount: commentCount ?? 0,
//       fullAdd: fullAdd,
//       showlevel: showLevel,
//       viewsCount: viewCount ?? 0,
//     );
//     print(postModel.toJson());
//
//     bool res;
//
//     if (updatingPost != null && updatingPost) {
//       res = await PostService.updatePost(postModel: postModel);
//     } else {
//       res = await PostService.createPost(postModel: postModel);
//     }
//
//     loadingcontroller.updateLoading(false);
//     if (res) {
//       if (updatingPost != null && updatingPost) {
//         longToastMessage('Post Updated...');
//       } else {
//         longToastMessage("Post Uploaded...");
//       }
//
//       // popping the page with the level
//       if (organizationId == null) {
//         Get.back(result: level);
//       } else {
//         Get.back(result: true);
//       }
//     } else {
//       longToastMessage("Some error occurred please try again....");
//     }
//   }
//
//   Future<String> uploadFile(File file, {int? fileNumber}) async {
//     Reference reference = FirebaseStorage.instance
//         .ref(POST_DB)
//         .child('$postId${fileNumber != null ? '-$fileNumber' : ''}');
//
//     // getting the mime type of the file
//     final mimeType = lookupMimeType(file.path);
//
//     UploadTask uploadTask = reference.putFile(
//       file,
//       SettableMetadata(contentType: mimeType),
//     );
//     String imageUrl = "";
//     try {
//       TaskSnapshot snapshot = await uploadTask;
//       imageUrl = await snapshot.ref.getDownloadURL();
//       return imageUrl;
//     } on FirebaseException catch (e) {
//       longToastMessage(e.message ?? e.toString());
//       return "";
//     }
//   }
//
//   var imageFiles = [].obs;
//   var videoFile = File('').obs;
//
//   // media actions
//   Future<File> mediaAction(BuildContext context) async {
//     await showAdaptiveActionSheet(
//       title: Text(
//         "Select Option",
//         style: TextStyle(fontSize: 25),
//       ),
//       actions: <BottomSheetAction>[
//         BottomSheetAction(
//           title: Text(
//             "Image",
//             style: TextStyle(color: AppColors.gradient2),
//           ),
//           onPressed: (c) {
//             Get.back();
//             cameraAction(context);
//           },
//         ),
//         BottomSheetAction(
//           title: Text(
//             "Video",
//             style: TextStyle(color: AppColors.gradient2),
//           ),
//           onPressed: (c) async {
//             await videoAction(context);
//             Get.back();
//           },
//         )
//       ],
//       cancelAction: CancelAction(
//         title: Text("Cancel"),
//         onPressed: (c) {
//           Get.back();
//           return;
//         },
//       ),
//       context: context,
//     );
//
//     return videoFile.value;
//   }
//
//   //Camera Actions
//   Future<void> videoAction(BuildContext context) async {
//     await showAdaptiveActionSheet(
//       title: Text(
//         "Select Option",
//         style: TextStyle(fontSize: 25),
//       ),
//       actions: <BottomSheetAction>[
//         BottomSheetAction(
//           title: Text("Camera", style: TextStyle(color: AppColors.gradient2)),
//           onPressed: (c) async {
//             await getVideoFromCamera(context);
//             Get.back();
//           },
//         ),
//         BottomSheetAction(
//           title: Text(
//             "Gallery",
//             style: TextStyle(color: AppColors.gradient2),
//           ),
//           onPressed: (c) async {
//             await getVideoFromGallery(context);
//             Get.back();
//           },
//         )
//       ],
//       cancelAction: CancelAction(
//         title: Text("Cancel"),
//         onPressed: (c) {
//           Get.back();
//           return;
//         },
//       ),
//       context: context,
//     );
//   }
//
//   //Camera Actions
//   cameraAction(BuildContext context) {
//     showAdaptiveActionSheet(
//       title: Text(
//         "Select Option",
//         style: TextStyle(fontSize: 25),
//       ),
//       actions: <BottomSheetAction>[
//         BottomSheetAction(
//           title: Text("Camera", style: TextStyle(color: AppColors.gradient2)),
//           onPressed: (c) {
//             Get.back();
//             getImageFromCamera(context);
//           },
//         ),
//         BottomSheetAction(
//           title: Text(
//             "Gallery",
//             style: TextStyle(color: AppColors.gradient2),
//           ),
//           onPressed: (c) {
//             Get.back();
//             getImageFromGallery(context);
//           },
//         )
//       ],
//       cancelAction: CancelAction(
//         title: Text("Cancel"),
//         onPressed: (c) {
//           Get.back();
//           return;
//         },
//       ),
//       context: context,
//     );
//
//     // showCupertinoModalPopup(context: context, builder: (context) => action);
//   }
//
//   Future getImageFromCamera(BuildContext context) async {
//     var image = await ImagePicker().pickImage(
//         source: ImageSource.camera,
//         preferredCameraDevice: CameraDevice.rear,
//         imageQuality: 20);
//     debugPrint("$image");
//
//     // if an image is picked, reset the list
//     if (image != null) {
//       imageFiles.clear();
//     }
//
//     // imageFile.value = File(image!.path);
//     cropView(image);
//   }
//
//   Future<void> getVideoFromCamera(BuildContext context) async {
//     var video = await ImagePicker().pickVideo(
//       source: ImageSource.camera,
//       preferredCameraDevice: CameraDevice.rear,
//     );
//
//     // resetting the images
//     imageFiles.value = [];
//
//     videoFile.value = video == null ? File('') : File(video.path);
//   }
//
//   Future getImageFromGallery(BuildContext context) async {
//     var images = await ImagePicker().pickMultiImage(imageQuality: 20);
//     if (images.isNotEmpty) {
//       images = images.sublist(0, min(3, images.length));
//
//       imageFiles.clear();
//     }
//     debugPrint("$images");
//
//     // imageFile.value = File(image!.path);
//     for (final image in images) {
//       await cropView(image);
//     }
//
//     print(imageFiles);
//   }
//
//   Future<void> getVideoFromGallery(BuildContext context) async {
//     var video = await ImagePicker().pickVideo(
//       source: ImageSource.gallery,
//     );
//
//     // resetting the images
//     imageFiles.value = [];
//
//     videoFile.value = video == null ? File('') : File(video.path);
//   }
//
//   cropView(var image) async {
//     CroppedFile? croppedFile = await ImageCropper().cropImage(
//       sourcePath: image.path,
//       aspectRatioPresets: [CropAspectRatioPreset.square],
//       uiSettings: [
//         AndroidUiSettings(
//           toolbarTitle: "Crop",
//           toolbarColor: AppColors.gradient2,
//           toolbarWidgetColor: AppColors.white,
//           initAspectRatio: CropAspectRatioPreset.square,
//           lockAspectRatio: false,
//         ),
//         IOSUiSettings(minimumAspectRatio: 2),
//       ],
//     );
//
//     // resetting the video file
//     videoFile.value = File('');
//
//     imageFiles.add(File(croppedFile!.path));
//   }
// }
