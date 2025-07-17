// import 'dart:io';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:chewie/chewie.dart';
// import 'package:chunaw/app/controller/home/upload_post_controller.dart';
// import 'package:chunaw/app/dbvertex/music/music_selector_dialog.dart';
// import 'package:chunaw/app/models/post_model.dart';
// import 'package:chunaw/app/screen/home/create_post_screen.dart';
// import 'package:chunaw/app/utils/app_bar.dart';
// import 'package:chunaw/app/utils/app_colors.dart';
// import 'package:chunaw/app/utils/app_fonts.dart';
// import 'package:chunaw/app/widgets/app_button.dart';
// import 'package:chunaw/app/widgets/app_drop_down.dart';
// import 'package:chunaw/app/widgets/app_text_field.dart';
// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:video_player/video_player.dart';
//
// class AddPostScreen extends StatefulWidget {
//   const AddPostScreen({
//     Key? key,
//     this.existingPost, this.organizationId,
//   }) : super(key: key);
//
//   final PostModel? existingPost;
//   final String? organizationId;
//
//   @override
//   State<AddPostScreen> createState() => _AddPostScreenState();
// }
//
// class _AddPostScreenState extends State<AddPostScreen> {
//   final UploadPostController uploadPostController =
//       Get.put(UploadPostController());
//
//   VideoPlayerController? _videoPlayerController;
//   ChewieController? _chewieController;
//
//   // whether a local media was selected or not from the filesystem
//   bool loadingVideo = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     setState(() {
//       loadingVideo = true;
//     });
//
//     _videoPlayerController = VideoPlayerController.file(File(''))
//       ..initialize().then(
//         (value) => setState(() {
//           _videoPlayerController!.setVolume(0);
//
//           _chewieController = ChewieController(
//             videoPlayerController: _videoPlayerController!,
//           );
//
//           // no longer loading media
//           loadingVideo = false;
//         }),
//       );
//
//     // if we do have existing post, setting the intial values
//     if (widget.existingPost != null) {
//       loadExistingPostData();
//     }
//   }
//
//   // method to load the existing post data
//   Future<void> loadExistingPostData() async {
//     // setting the id to the current existing post so that we edit the existing post instead of creating a new one
//     uploadPostController.postId = widget.existingPost!.postId;
//
//     // setting the description
//     uploadPostController.postDesController.text = widget.existingPost!.postDesc;
//
//     // setting the video if present
//     if (widget.existingPost!.postVideo.isNotEmpty) {
//       setState(() {
//         loadingVideo = true;
//       });
//
//       // setting up the controller
//       _videoPlayerController = VideoPlayerController.networkUrl(
//           Uri.parse(widget.existingPost!.postVideo))
//         ..initialize().then(
//           (value) => setState(() {
//             _videoPlayerController!.setVolume(0);
//
//             // setting up chewie controller
//             _chewieController = ChewieController(
//               videoPlayerController: _videoPlayerController!,
//               autoPlay: false,
//               autoInitialize: true,
//               allowFullScreen: true,
//               allowMuting: true,
//               allowPlaybackSpeedChanging: true,
//               allowedScreenSleep: false,
//               aspectRatio: _videoPlayerController!.value.aspectRatio,
//               hideControlsTimer: Duration(seconds: 1),
//             );
//
//             // no longer loading the media
//             loadingVideo = false;
//           }),
//         );
//     }
//
//     // setting up the level
//     switch (widget.existingPost!.level) {
//       case 1:
//         uploadPostController.selectedLevel.value = 'Postal Level';
//         break;
//       case 2:
//         uploadPostController.selectedLevel.value = 'City Level';
//         break;
//       case 3:
//         uploadPostController.selectedLevel.value = 'State Level';
//         break;
//       case 4:
//         uploadPostController.selectedLevel.value = 'Country Level';
//         break;
//     }
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//
//     _videoPlayerController?.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBarCustom(
//         title: widget.existingPost != null ? 'Edit post' : 'Write a post',
//         leadingBack: true,
//         elevation: 0,
//       ),
//       backgroundColor: AppColors.white,
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: 12),
//               if (widget.organizationId == null) ...[
//                 Text(
//                   "  Select Level",
//                   style: TextStyle(
//                       fontFamily: AppFonts.Montserrat,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black),
//                 ),
//                 SizedBox(height: 12),
//                 AppDropDown(
//                   hint: 'Select Postal',
//                   hintWidget: Obx(
//                         () => Text(
//                       uploadPostController.selectedLevel.value,
//                       style: TextStyle(
//                           fontFamily: AppFonts.Montserrat,
//                           color: uploadPostController.selectedLevel.value == ""
//                               ? Colors.black.withOpacity(0.51)
//                               : AppColors.black,
//                           fontSize: 14),
//                     ),
//                   ),
//                   items: uploadPostController.levelList.map((unit) {
//                     return DropdownMenuItem(
//                       value: unit,
//                       child: Text(
//                         unit,
//                       ),
//                     );
//                   }).toList(),
//                   onChanged: (unit) {
//                     print(unit);
//                     uploadPostController.selectedLevel.value = unit;
//                   },
//                 ),
//                 SizedBox(height: 12)
//               ],
//               Text(
//                 "  Description",
//                 style: TextStyle(
//                     fontFamily: AppFonts.Montserrat,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black),
//               ),
//               SizedBox(height: 12),
//               AppTextField(
//                 controller: uploadPostController.postDesController,
//                 keyboardType: TextInputType.text,
//                 lableText: "Write your thoughts",
//                 maxLines: 16,
//                 minLines: 10,
//               ),
//               SizedBox(height: 22),
//               Row(
//                 children: [
//                   Text(
//                     "  Upload Media",
//                     style: TextStyle(
//                         fontFamily: AppFonts.Montserrat,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black),
//                   ),
//                   Text(
//                     ' (Max 3 images)',
//                     style: TextStyle(fontSize: 10),
//                   ),
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: () async {
//                       // if video is selected then we return the file here
//                       File? video =
//                           await uploadPostController.mediaAction(context);
//
//                       if (video.path != '') {
//                         loadingVideo = true;
//
//                         setState(() {
//                           _videoPlayerController =
//                               VideoPlayerController.file(video)
//                                 ..initialize().then(
//                                   (value) => setState(() {
//                                     // setting up chewie controller
//                                     _chewieController = ChewieController(
//                                       videoPlayerController:
//                                           _videoPlayerController!,
//                                       autoPlay: false,
//                                       autoInitialize: true,
//                                       allowFullScreen: true,
//                                       allowMuting: true,
//                                       allowPlaybackSpeedChanging: true,
//                                       allowedScreenSleep: false,
//                                       aspectRatio: _videoPlayerController!
//                                           .value.aspectRatio,
//                                       hideControlsTimer: Duration(seconds: 1),
//                                     );
//
//                                     loadingVideo = false;
//                                   }),
//                                 );
//                         });
//                       }
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                       ),
//                       child: Icon(Icons.upload),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 12),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                 child: DottedBorder(
//                   dashPattern: [
//                     15,
//                     10,
//                   ],
//                   color: Colors.grey.withOpacity(0.5),
//                   borderType: BorderType.RRect,
//                   radius: Radius.circular(9),
//                   child: SizedBox(
//                     width: double.infinity,
//                     child: Obx(
//                       () => uploadPostController.imageFiles.isNotEmpty ||
//                               uploadPostController.videoFile.value.path != ''
//                           ? uploadPostController.imageFiles.isNotEmpty
//                               ? _buildSelectedImages()
//                               : loadingVideo
//                                   ? Container(
//                                       alignment: Alignment.center,
//                                       padding: const EdgeInsets.all(20),
//                                       child: CircularProgressIndicator(),
//                                     )
//                                   : ClipRRect(
//                                       borderRadius: BorderRadius.circular(9),
//                                       child: AspectRatio(
//                                         aspectRatio: _videoPlayerController!
//                                             .value.aspectRatio,
//                                         child: Chewie(
//                                           controller: _chewieController!,
//                                         ),
//                                       ),
//                                     )
//                           : (widget.existingPost != null &&
//                                   ((widget.existingPost!.postImages
//                                           .isNotEmpty) ||
//                                       widget
//                                           .existingPost!.postVideo.isNotEmpty))
//                               ? showExistingPostMedia()
//                               : Column(
//                                   children: [
//                                     SizedBox(
//                                       height: 35,
//                                     ),
//                                     Icon(
//                                       Icons.photo,
//                                       size: 40,
//                                     ),
//                                     SizedBox(
//                                       height: 35,
//                                     ),
//                                   ],
//                                 ),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 22),
//               Row(
//                 children: [
//                   Text(
//                     "  Select Background Audio",
//                     style: TextStyle(
//                         fontFamily: AppFonts.Montserrat,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black),
//                   ),
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: () => uploadPostController.selectMusic(context),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 10,
//                       ),
//                       child: Icon(Icons.radio_button_checked),
//                     ),
//                   ),
//                 ],
//               ),
//               Obx(() => uploadPostController.selectedMusic.value != null ? Card(
//                 margin: EdgeInsets.symmetric(vertical: 12, horizontal: 5),
//                 child: ListTile(
//                   contentPadding: EdgeInsets.all(5),
//                   title: Text(
//                       uploadPostController.selectedMusic.value!.path.replaceFirst("${uploadPostController.selectedMusic.value!.parent.path}/", '')
//                   ),
//                   leading: Icon(Icons.music_note),
//                   trailing: IconButton(onPressed: () {
//                     uploadPostController.selectedMusic.value = null;
//                   }, icon: Icon(Icons.close)),
//                 ),
//               ) : Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 22),
//                 child: DottedBorder(
//                   dashPattern: [
//                     15,
//                     10,
//                   ],
//                   color: Colors.grey.withOpacity(0.5),
//                   borderType: BorderType.RRect,
//                   radius: Radius.circular(9),
//                   child: SizedBox(
//                       width: double.infinity,
//                       child: Column(
//                         children: [
//                           SizedBox(
//                             height: 35,
//                           ),
//                           Icon(
//                             Icons.music_note,
//                             size: 40,
//                           ),
//                           SizedBox(
//                             height: 35,
//                           ),
//                         ],
//                       )
//                   ),
//                 ),
//               )),
//               AppButton(
//                   onPressed: () {
//                     if (true) {
//                       Get.to(CreatePostScreen());
//                       return;
//                     }
//
//                     uploadPostController.addPost(
//                       organizationId: widget.organizationId,
//                       updatingPost: widget.existingPost != null ? true : false,
//                       existingImages: widget.existingPost != null &&
//                               widget.existingPost!.postImages.isNotEmpty
//                           ? widget.existingPost!.postImages
//                           : null,
//                       existingVideo: widget.existingPost != null &&
//                               widget.existingPost!.postVideo.isNotEmpty
//                           ? widget.existingPost!.postVideo
//                           : null,
//                       commentCount: widget.existingPost?.commentsCount,
//                       createdAt: widget.existingPost?.createdAt,
//                       likeCount: widget.existingPost?.likeCount,
//                       upvoteCount: widget.existingPost?.upvoteCount,
//                       viewCount: widget.existingPost?.viewsCount,
//                     );
//                   },
//                   buttonText: widget.existingPost != null
//                       ? 'Update Post'
//                       : "Save Post"),
//               SizedBox(height: 22),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Column _buildSelectedImages() {
//     return Column(
//       children: uploadPostController.imageFiles.asMap().keys.map((index) {
//         final image = uploadPostController.imageFiles[index];
//
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom:
//                 index == uploadPostController.imageFiles.length - 1 ? 0 : 10,
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(9.0),
//             child: Image.file(
//               File(image.path),
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   showExistingPostMedia() {
//     // if image exists already
//     if (widget.existingPost!.postImages.isNotEmpty) {
//       return Column(
//         children: widget.existingPost!.postImages.asMap().keys.map((index) {
//           final image = widget.existingPost!.postImages[index];
//
//           return Padding(
//             padding: EdgeInsets.only(
//               bottom:
//                   index == widget.existingPost!.postImages.length - 1 ? 0 : 10,
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(9),
//               child: CachedNetworkImage(
//                 imageUrl: image,
//                 fit: BoxFit.cover,
//                 placeholder: (context, url) {
//                   return Container(
//                     alignment: Alignment.center,
//                     padding: const EdgeInsets.all(15),
//                     child: CircularProgressIndicator(),
//                   );
//                 },
//               ),
//             ),
//           );
//         }).toList(),
//       );
//     }
//
//     // if video is present instead
//     return loadingVideo
//         ? Container(
//             alignment: Alignment.center,
//             padding: const EdgeInsets.all(20),
//             child: CircularProgressIndicator(),
//           )
//         : ClipRRect(
//             borderRadius: BorderRadius.circular(9),
//             child: AspectRatio(
//               aspectRatio: _videoPlayerController!.value.aspectRatio,
//               child: Chewie(
//                 controller: _chewieController!,
//               ),
//             ),
//     );
//   }
// }