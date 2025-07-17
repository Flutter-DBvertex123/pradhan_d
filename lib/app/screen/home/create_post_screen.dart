import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:chunaw/app/dbvertex/music/music_preview_dialog.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/home/create_post_controller.dart';
import '../../utils/app_colors.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? postModel;
  final String? organizationId;
  const CreatePostScreen({super.key, this.postModel, this.organizationId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final createPostController = Get.put(CreatePostController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => initialize());
  }

  Future<void> initialize() async {
    if (widget.postModel != null) {
      createPostController.init(widget.postModel!);
    }
    if (widget.postModel?.postImage != null) {
      createPostController.selectedImages.value.add(widget.postModel!.postImage!);
      createPostController.selectedImages.refresh();
    }
    if (widget.postModel?.postImages.isNotEmpty == true) {
      createPostController.selectedImages.value.addAll(widget.postModel!.postImages.map((e) => e.toString()));
      createPostController.selectedImages.refresh();
    }

    createPostController.selectedVideo.value = widget.postModel?.postVideo ?? '';
    createPostController.selectedAudio.value = widget.postModel?.backgroundMusic;
    if (createPostController.selectedAudio.value != null) {
      createPostController.audioType = 'external';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarColor: AppColors.white,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: _createAppBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _createDescAndMedia(),
              _createOptionTiles()
            ],
          ),
        ),
      )
    );
  }

  _createAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: Get.back,
        icon: Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 21.0),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.black,
            size: 20,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: TextButton(
              onPressed: () => createPostController.addPost(
                organizationId: widget.organizationId,
                updatingPost: widget.postModel != null ? true : false,
                existingImages: widget.postModel != null &&
                    widget.postModel!.postImages.isNotEmpty
                    ? widget.postModel!.postImages
                    : null,
                existingVideo: widget.postModel != null &&
                    widget.postModel!.postVideo.isNotEmpty
                    ? widget.postModel!.postVideo
                    : null,
                commentCount: widget.postModel?.commentsCount,
                createdAt: widget.postModel?.createdAt,
                likeCount: widget.postModel?.likeCount,
                upvoteCount: widget.postModel?.upvoteCount,
                viewCount: widget.postModel?.viewsCount,
              ),
              child: Text(
                'Save Post',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 19.sp
                ),
              )
          ),
        )
      ],
      bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.4),
          child: _createDivider()
      ),
    );
  }

  _createDivider() {
    return Divider(
      color: Colors.grey[300],
      height: 1.5,
      thickness: 1.5,
    );
  }

  _createDescAndMedia() {
    String username = getPrefValue(Keys.USERNAME);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15.w, horizontal: 26.0.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "@$username",
                  style: TextStyle(
                      color: AppColors.black,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600
                  ),
                ),
                SizedBox(height: 5.w),
                Theme(
                  data: ThemeData(
                    primaryColor: AppColors.primaryColor,
                    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: AppColors.primaryColor, // Cursor color
                      selectionColor: AppColors.primaryColor.withOpacity(0.5), // Text selection color
                      selectionHandleColor: AppColors.primaryColor, // Selection handle color
                    ),
                  ),
                  child: TextField(
                    controller: createPostController.captionTextController,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18.sp
                    ),
                    minLines: 5,
                      maxLines: 8,
                    maxLength: 2000,
                    decoration: InputDecoration(
                        hintText: 'Write your thoughts',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey
                      ),
                      counter: Row(
                        children: [
                          Obx(() => Text(
                            'Remaining ${createPostController.selectedImages.value.isNotEmpty ? 'char' : 'characters'} : ${createPostController.captionLength.value}',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 17.sp
                            ),
                          ))
                        ],
                      )
                    ),
                  ),
                ),
                _createSelectedVideo(),
                Row(
                  children: [
                    _createKeyTile(keyStr: '#'),
                    _createKeyTile(keyStr: '@')
                  ],
                ),
              ],
            ),
          ),
          _createSelectedImages()
        ],
      ),
    );
  }

  _createKeyTile({ required String keyStr }) {
    return Card(
      margin: EdgeInsets.only(right: 18.0.w, top: 26.0.w, bottom: 5.0.w),
      elevation: 3,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => createPostController.insertKey(keyStr),
        child: SizedBox(
          width: 48.w,
          height: 48.w,
          child: Center(
            child: Text(
              keyStr,
              style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20.sp
              ),
            ),
          ),
        ),
      ),
    );
  }

  _createSelectedImages() {
    return Obx(() {
      return createPostController.selectedImages.value.isNotEmpty ? SizedBox(
        width: 160.w + 8.w,
        child: Wrap(
          children: List.generate(createPostController.selectedImages.value.length, (index) => _createImage(createPostController.selectedImages.value[index], index, createPostController.selectedImages.value.length)),
        ),
      ) : SizedBox();
    });
  }

  _createImage(String uri, int index, int length) {
    return Card(
      margin: EdgeInsets.all(2.w),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      color: Colors.grey[100],
      child: uri.startsWith('http') ? CachedNetworkImage(
          imageUrl: uri,
        fit: BoxFit.cover,
        width: index == 2 || length == 1 ? 164.w : 80.w,
        height: length == 2 || length == 1 ? 164.w : 80.w,
      ) : Image.file(
        File(uri),
        fit: BoxFit.cover,
        width: index == 2 || length == 1 ? 164.w : 80.w,
        height: length == 2 || length == 1 ? 164.w : 80.w,
      ),
    );
  }

  _createSelectedVideo() {
    return Obx(() {
      if (createPostController.selectedVideo.value.isNotEmpty) {
      return SizedBox(
        height: 200.w,
        child: createPostController.isVideoLoading.value || createPostController.chewieController == null ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor,)) : Card(
            color: Colors.transparent,
            elevation: 0,
            margin: EdgeInsets.only(top: 20.w),
            clipBehavior: Clip.hardEdge,
            child: Chewie(controller: createPostController.chewieController!)
        ),
      );
      } else {
        return SizedBox();
      }
    });
  }

  Widget _createOptionTiles() {
    return Obx(() => Column(
      children: [
        _createOptionTile(
            title: 'Select level',
            subtitle: createPostController.selectedLevel.value,
            icon: Icons.edit_location_alt_outlined,
            onPressed: _showLevelSelector,
            enableClearButton: false
        ),
        _createDivider(),
        _createOptionTile(
            title: 'Attach media',
            icon: Icons.perm_media,
            onPressed: () => createPostController.mediaAction(context),
            onCleared: () {
              createPostController.selectedImages.value.clear();
              createPostController.selectedImages.refresh();
              createPostController.selectedVideo.value = '';
            },
            subtitle: createPostController.getMediaSummary(),
            enableClearButton: createPostController.selectedVideo.value.isNotEmpty || createPostController.selectedImages.value.isNotEmpty
        ),
        if (createPostController.audioType == null || createPostController.audioType == 'record') ...[
          _createDivider(),
          _createOptionTile(
              title: 'Record your voice',
              icon: Icons.mic_outlined,
              subtitle: createPostController.selectedAudio.value != null ? 'Recording.mp3' : null,
              onCleared: () {
                createPostController.audioType = null;
                createPostController.selectedAudio.value = null;
              },
              onPressed: createPostController.audioType != null ? () => MusicPreviewDialog.show(createPostController.selectedAudio.value!) : createPostController.recordBackgroundVoice,
              enableClearButton: createPostController.audioType != null
          )
        ],
        if (createPostController.audioType == null || createPostController.audioType == 'external') ...[
          _createDivider(),
          _createOptionTile(
              title: 'Add background music',
              subtitle: createPostController.selectedAudio.value?.split('/').lastOrNull,
              icon: Icons.my_library_music,
              onCleared: () {
                createPostController.audioType = null;
                createPostController.selectedAudio.value = null;
              },
              onPressed: createPostController.audioType != null ? () => MusicPreviewDialog.show(createPostController.selectedAudio.value!) : createPostController.selectBackgroundSound,
              enableClearButton: createPostController.audioType != null
          )
        ]
      ],
    ));
  }

  _showLevelSelector() async {
    String? selectedLevel = await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (context) {
        return SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 26.0.w, vertical: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                createPostController.availableLevels.length, (index) {
                  return InkWell(
                    onTap: () => Get.back(result: createPostController.availableLevels[index]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.w),
                          child: Text(
                            createPostController.availableLevels[index],
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 20.0.w,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                          Divider(color: index != createPostController.availableLevels.length - 1 ? Colors.grey[300] : Colors.transparent, thickness: 1),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
    createPostController.selectedLevel.value = selectedLevel ?? createPostController.selectedLevel.value;
  }

  _createOptionTile({ required String title, String? subtitle, required IconData icon, VoidCallback? onPressed, bool enableClearButton = false, VoidCallback? onCleared }) {
    return ListTile(
      onTap: onPressed,
      contentPadding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 4.w),
      leading: Icon(icon, color: AppColors.black),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey)),
      trailing: enableClearButton ? IconButton(onPressed: onCleared, icon: Icon(Icons.clear)) : null,
    );
  }
}
