import 'dart:io';
import 'dart:math';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:chewie/chewie.dart';
import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
import 'package:chunaw/app/dbvertex/widgets/meeting_details_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';

import '../controller/common/loading_controller.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';

class PitchScreen extends StatefulWidget {

  final String scope;
  final Map<String, String> usersToPitch;

  const PitchScreen({super.key, required this.usersToPitch, required this.scope});

  @override
  State<StatefulWidget> createState() => PitchState();
}

class PitchState extends State<PitchScreen> {
  final TextEditingController messageController = TextEditingController();

  File? selectedVideo;

  bool loadingVideo = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  LoadingController loadingcontroller = Get.put(LoadingController());

  late DocumentReference documentReference;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    documentReference = FirebaseFirestore.instance
        .collection(PROMOTER_DB)
        .doc();

    loadingVideo = true;

    _videoPlayerController = VideoPlayerController.file(File(''))
      ..initialize().then(
            (value) => setState(() {
          _videoPlayerController!.setVolume(0);

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
          );

          // no longer loading media
          loadingVideo = false;
        }),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: 'Pitch Promoters',
        leadingBack: true,
        elevation: 0,
        showSearch: false,
      ),
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              Text(
                "  Message",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: messageController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.text,
                lableText: "Write your message",
                maxLines: 8,
                minLines: 4,
                limit: 60,
              ),
              SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    "  Upload Video",
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  Expanded(
                    child: Text(
                      ' (Optional)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => videoAction(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      child: Icon(Icons.upload),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: DottedBorder(
                  dashPattern: [
                    15,
                    10,
                  ],
                  color: Colors.grey.withOpacity(0.5),
                  borderType: BorderType.RRect,
                  radius: Radius.circular(9),
                  child: SizedBox(
                      width: double.infinity,
                      child: selectedVideo != null
                          ? loadingVideo
                          ? Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.gradient1),
                      ) : ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController!
                              .value.aspectRatio,
                          child: Chewie(
                            controller: _chewieController!,
                          ),
                        ),
                      ) : Column(
                        children: [
                          SizedBox(
                            height: 35,
                          ),
                          Icon(
                            Icons.photo,
                            size: 40,
                          ),
                          SizedBox(
                            height: 35,
                          ),
                        ],
                      )
                  ),
                ),
              ),
              SizedBox(height: 22),
              AppButton(
                  onPressed: () {
                    validateAndPitch();
                  },
                  buttonText: 'Send'
              )
            ],
          ),
        ),
      ),
    );
  }

  String? validate(String message) {

    if (message.isEmpty) {
      return 'Please enter your message.';
    }

    if (6 > message.length) {
      return 'Message must be at least 5 characters long.';
    }

    if (message.length > 150) {
      return 'The message must not exceed 60 characters.';
    }

    return null;
  }

  Future<void> validateAndPitch() async {

    String message = messageController.text.trim().replaceAll(RegExp(r'[\s]+'), ' ');

    String? validationError = validate(message);

    if (validationError != null) {
      longToastMessage(validationError);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    var result = await MeetingDialog.openMeetingDialog(context, widget.scope);

    if (result != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting addition canceled.')),
      );
      return;
    }


    loadingcontroller.updateLoading(true);

    try {
      final uploadedVideoUrl = selectedVideo != null ? await uploadFile(selectedVideo!, "${widget.scope}_meeting_video.mp4") : null;
      try {
        print("ishwar: sending");
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendMail');
        final response = await callable.call({'scope_suffix': widget.scope, 'message': message, 'videoUrl': uploadedVideoUrl, 'receivers': widget.usersToPitch.keys.toList()});

        // showDialog(context: context, builder: (context) => AlertDialog(
        //   title: Text("Response"),
        //   content: Column(
        //     children: [
        //       Expanded(
        //         child: ListView(
        //           children: List<String>.from(response.data['logs'] ?? []).map((str) => Padding(
        //             padding: EdgeInsets.all(12),
        //             child: Text(str),
        //           )).toList(),
        //         ),
        //       ),
        //       Padding(
        //         padding: const EdgeInsets.all(8.0),
        //         child: Text(Map<String, dynamic>.from(response.data).entries.map((en) => en.key != 'logs' ? en : null).join(' | ')),
        //       ),
        //     ],
        //   )
        // ));
        //
        print("ishwar-pitching: ${response.data}");
        //

        final db = FirebaseFirestore.instance;

        final promotersDB = db.collection(PROMOTER_DB);
        WriteBatch batch = db.batch();

        print("ishwar:time users: ${widget.usersToPitch}");
        print("ishwar:time data: ${List<String>.from(response.data['data']??[])}");

        for (var key in List<String>.from(response.data['data']??[])) {
          batch.update(promotersDB.doc(widget.usersToPitch[key]??''), {
            'pitch_date': FieldValue.serverTimestamp()
          });
        }

        await batch.commit();

        longToastMessage(response.data['message'] ?? 'Something went wrong');

      } catch (error) {
        print("ishwar: $error");
        longToastMessage('Failed to pitch.');
      }

      loadingcontroller.updateLoading(false);

      Navigator.pop(context);

    } catch (error) {
      print("ishwar: $error");
      loadingcontroller.updateLoading(false);
      longToastMessage('Failed to pitch.');
    }
  }


  Future<String> uploadFile(File file, String filename) async {
    Reference reference = FirebaseStorage.instance
        .ref('meeting_videos')
        .child(filename);

    // getting the mime type of the file
    final mimeType = lookupMimeType(file.path);

    UploadTask uploadTask = reference.putFile(
      file,
      SettableMetadata(contentType: mimeType),
    );
    String imageUrl = "";
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (error) {
      throw error.toString();
    }
  }

  Future<void> getVideoFromCamera(BuildContext context) async {
    var video = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    selectedVideo = video == null ? null : File(video.path);
    _videoPlayerController =
    VideoPlayerController.file(selectedVideo!)
      ..initialize().then(
            (value) => setState(() {
          // setting up chewie controller
          _chewieController = ChewieController(
            videoPlayerController:
            _videoPlayerController!,
            autoPlay: false,
            autoInitialize: true,
            allowFullScreen: true,
            allowMuting: true,
            allowPlaybackSpeedChanging: true,
            allowedScreenSleep: false,
            aspectRatio: _videoPlayerController!
                .value.aspectRatio,
            hideControlsTimer: Duration(seconds: 1),
          );

          loadingVideo = false;
        }),
      );
  }

  //Camera Actions
  Future<void> videoAction(BuildContext context) async {
    await showAdaptiveActionSheet(
      title: Text(
        "Select Option",
        style: TextStyle(fontSize: 25),
      ),
      actions: <BottomSheetAction>[
        BottomSheetAction(
          title: Text("Camera", style: TextStyle(color: AppColors.gradient2)),
          onPressed: (c) async {
            await getVideoFromCamera(context);
            Get.back();
          },
        ),
        BottomSheetAction(
          title: Text(
            "Gallery",
            style: TextStyle(color: AppColors.gradient2),
          ),
          onPressed: (c) async {
            await getVideoFromGallery(context);
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
  }

  Future<void> getVideoFromGallery(BuildContext context) async {
    var video = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
    );

    selectedVideo = video == null ? null : File(video.path);
    _videoPlayerController =
    VideoPlayerController.file(selectedVideo!)
      ..initialize().then(
            (value) => setState(() {
          // setting up chewie controller
          _chewieController = ChewieController(
            videoPlayerController:
            _videoPlayerController!,
            autoPlay: false,
            autoInitialize: true,
            allowFullScreen: true,
            allowMuting: true,
            allowPlaybackSpeedChanging: true,
            allowedScreenSleep: false,
            aspectRatio: _videoPlayerController!
                .value.aspectRatio,
            hideControlsTimer: Duration(seconds: 1),
          );

          loadingVideo = false;
        }),
      );
  }
}