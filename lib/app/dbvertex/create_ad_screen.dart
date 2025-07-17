
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:chunaw/app/dbvertex/utils/ads_fetcher.dart';
import 'package:chunaw/app/dbvertex/utils/razorpay_impl.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:video_player/video_player.dart';

import '../controller/common/loading_controller.dart';
import '../models/location_model.dart';
import '../screen/home/post_card.dart';
import '../utils/app_assets.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_routes.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import 'ishwar_constants.dart';
import 'level_selector_sheet.dart';
import 'models/ad_model.dart';

class CreateAdScreen extends StatefulWidget {
  final Function() onAddedCallbacks;

  const CreateAdScreen({super.key, required this.onAddedCallbacks});

  @override
  State<StatefulWidget> createState() {
    return _CreateAdState();
  }

}

class _CreateAdState extends State<CreateAdScreen> {
  final TextEditingController adTitleController = TextEditingController();
  final TextEditingController adUrlController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController proposedAmountController = TextEditingController();
  final TextEditingController targetViewsController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController gstController = TextEditingController();

  List<LocationModel> scope = [];

  File? selectedVideo;
  List<File> selectedImages = [];
  List<String> uploadedMedia = List<String>.empty(growable: true);
  String? videoUploadUrl;

  bool loadingVideo = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  LoadingController loadingcontroller = Get.put(LoadingController());

  late DocumentReference documentReference;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    adTitleController.dispose();
    adUrlController.dispose();
    descriptionController.dispose();
    proposedAmountController.dispose();
    targetViewsController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    RazorpayManager().setCallbacks(onPaymentSuccess, onPaymentError, externalWalletCallback: onHandleExternalWallet);

    documentReference = FirebaseFirestore.instance
        .collection(AD_DB)
        .doc();

    clearScope();

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


    try {
      FirebaseFirestore.instance.collection('contacts').doc(FirebaseAuth.instance.currentUser?.uid??'').get().then((userContactsSnapshot) {
        final data = userContactsSnapshot.data();
        emailController.text = data?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
        phoneController.text = data?['phone'] ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
        gstController.text = data?['gst_or_pan'] ?? '';
      });

    } catch (_) {}

  }

  void clearScope() {
    scope.clear();
    scope.add(LocationModel(name: 'India', text: 'IND', id: '1-India'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: 'Create New Promotion',
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
                "  Select Level",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                elevation: 0,
                clipBehavior: Clip.hardEdge,
                color: AppColors.textBackColor,
                margin: EdgeInsets.symmetric(vertical: 12),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: scope.isEmpty ? Text(
                          'None',
                          style: TextStyle(
                              fontFamily: AppFonts.Montserrat,
                              color: AppColors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w500
                          ),
                        ) : Builder(
                          builder: (context) {
                            var namedScope = scope.map((loc) => loc.name).toList();

                            return SizedBox(
                              height: MediaQuery.sizeOf(context).width * 0.08,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) => Center(
                                    child: Text(
                                      namedScope[index],
                                      style: TextStyle(
                                          fontFamily: AppFonts.Montserrat,
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500
                                      ),
                                    ),
                                  ),
                                  separatorBuilder: (context, index) => Center(child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Icon(Icons.arrow_forward, size: 12,color: Colors.black,),
                                  )),
                                  itemCount: namedScope.length
                              ),
                            );
                          }
                        ),
                      ),
                      Card(
                        color: AppColors.primaryColor,
                        clipBehavior: Clip.hardEdge,
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () {
                            LevelSelectorSheet.show(context, (state, city, postal) {
                              setState(() {
                                scope.clear();
                                scope.add(LocationModel(name: 'India', text: 'IND', id: '1-India'));
                                if (state != null) {
                                  scope.add(state);
                                  if (city != null) {
                                    scope.add(city);
                                    if (postal != null) {
                                      scope.add(postal);
                                    }
                                  }
                                }
                              });
                            }, defaultState:  scope.length > 1 ? scope[1] : null, defaultCity: scope.length > 2 ? scope[2] : null, defaultPostal: scope.length > 3 ? scope[3] : null);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8).copyWith(right: 10),
                            child: Row(
                              children: [
                                Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              FutureBuilder(
                  future: scope.isEmpty ? null : FirebaseFirestore.instance.collection(PRADHAN_DB).doc(scope.last.id).get(),
                  builder: (context, snapshot) {
                    if (snapshot.data == null || !(snapshot.data?.exists ?? false) || snapshot.data?.data()?['pradhan_model']?['level'] is String) {
                      return SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "  Pradhaan In Selected Scope",
                          style: TextStyle(
                              fontFamily: AppFonts.Montserrat,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                        Card(
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              AppRoutes.navigateToMyProfile(userId: snapshot.data?.data()?['pradhan_model']?['id'], back: true, isOrganization: false);
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 22.r,
                                backgroundColor: getColorBasedOnLevel(snapshot.data?.data()?['pradhan_model']?['level'] ?? 1),
                                child: CircleAvatar(
                                    radius: 20.r,
                                    backgroundColor: AppColors.gradient1,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      clipBehavior: Clip.hardEdge,
                                      child: CachedNetworkImage(
                                        placeholder: (context, error) {
                                          return CircleAvatar(
                                            radius: 15.r,
                                            backgroundColor: AppColors.gradient1,
                                            child: Center(
                                                child: CircularProgressIndicator(
                                                  color: AppColors.highlightColor,
                                                )),
                                          );
                                        },
                                        errorWidget: (context, error, stackTrace) {
                                          return Image.asset(
                                            AppAssets.brokenImage,
                                            fit: BoxFit.fitHeight,
                                            width: 160.0,
                                            height: 160.0,
                                          );
                                        },
                                        imageUrl: snapshot.data?.data()?['pradhan_model']?['image'] ?? '',
                                        // .replaceAll('\', '//'),
                                        fit: BoxFit.cover,
                                        // width: 160.0,
                                        height: 160.0,
                                      ),
                                    )),
                              ),
                              title: Text(
                                snapshot.data?.data()?['pradhan_model']?['name'] ?? 'No Name'
                              ),
                              subtitle: Text(
                                  "@${snapshot.data?.data()?['pradhan_model']?['username'] ?? 'deleted'}",
                                style: TextStyle(
                                  color: AppColors.gradient1,
                                  fontSize: 13
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  }
              ),
              SizedBox(height: 12),
              Text(
                "  Title",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: adTitleController,
                keyboardType: TextInputType.text,
                lableText: "Please Enter Title",
                textCapitalization: TextCapitalization.words,
                maxLines: 1,
                minLines: 1,
              ),
              Text(
                "  Action Url",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: adUrlController,
                keyboardType: TextInputType.url,
                lableText: "Provide Action Url (Optional)",
                maxLines: 1,
                minLines: 1,
              ),
              Text(
                "  Description",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: descriptionController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.text,
                lableText: "Write your thoughts",
                maxLines: 8,
                minLines: 4,
              ),
              Text(
                "  Target Views",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: targetViewsController,
                keyboardType: TextInputType.number,
                lableText: "Ex. 20000",
                maxLines: 1,
                minLines: 1,
              ),
              Text(
                "  Proposed Amount",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: proposedAmountController,
                keyboardType: TextInputType.number,
                lableText: "Ex. 500",
                maxLines: 1,
                minLines: 1,
              ),
              SizedBox(height: 22),
              Row(
                children: [
                  Text(
                    "  Upload Media",
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  Expanded(
                    child: Text(
                      ' (Max 3 images or videos)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => mediaAction(context),
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
                child: selectedImages.isNotEmpty ||
                    selectedVideo != null
                    ? selectedImages.isNotEmpty
                    ? _buildSelectedImages()
                    : loadingVideo
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
              SizedBox(height: 16),
          Text(
            "  GST/Pan No.",
            style: TextStyle(
                fontFamily: AppFonts.Montserrat,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black),
          ),
          SizedBox(height: 12),
          AppTextField(
            controller: gstController,
            keyboardType: TextInputType.url,
            lableText: "Enter any of GST/Pan No.",
            maxLines: 1,
            minLines: 1,
            textCapitalization: TextCapitalization.characters,
          ),SizedBox(height: 12),
              SizedBox(height: 16),
              Text(
                "  Email*",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: emailController,
                keyboardType: TextInputType.url,
                lableText: "Please provide your email (Optional)",
                maxLines: 1,
                minLines: 1,
              ),SizedBox(height: 12),
              Text(
                "  Phone*",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              AppTextField(
                controller: phoneController,
                keyboardType: TextInputType.url,
                lableText: "Please provide your phone (Optional)",
                maxLines: 1,
                minLines: 1,
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '* Pradhaan will contact you through provided email and phone here.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12
                  ),
                ),
              ),
              SizedBox(height: 22),
              AppButton(
                  onPressed: () {
                    validateAndCreateAd();
                  },
                  buttonText: 'Create'
              )
            ],
          ),
        ),
      ),
    );
  }

  String? validate(String title, String description, String gstOrPan) {
    // Validate scope
    if (scope.isEmpty) {
      return 'Please select your target scope where you want to show your ad.';
    }

    // Validate title
    if (title.isEmpty) {
      return 'Please enter a valid title for your ad.';
    }
    if (title.length > 20) {
      return 'Ad title length cannot exceed 20 characters.';
    }

    // Validate description
    if (description.isEmpty) {
      return 'Please add a description about your ad.';
    }
    if (description.length > 150) {
      return 'The description must not exceed 150 characters.';
    }

    // Validate GSTIN or PAN
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$'); // PAN format
    final gstinRegex = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{3}$'); // GSTIN format

    if (gstOrPan.isEmpty) {
      return 'Please enter a valid PAN or GSTIN.';
    }
    if (!(panRegex.hasMatch(gstOrPan) || gstinRegex.hasMatch(gstOrPan))) {
      return 'Please enter a valid PAN or GSTIN number.';
    }

    return null;
  }

  Future<void> validateAndCreateAd() async {
    // AdsFetcher().getRandomAd([]).then((ad) => print("ishwar: Getting random ad: ${ad?.toJson().toString()}"), onError: (error) => print("ishwar: $error"));

    String title = adTitleController.text.trim();
    String description = descriptionController.text.trim();
    String gst = gstController.text.trim();

    String? validationError = validate(title, description, gst);

    int proposedAmount = 0;
    try {
      proposedAmount = double.parse(proposedAmountController.text.trim()).toInt();
      if (0>=proposedAmount) {
        validationError = 'Amount can not be 0 or negative';
      }
    } catch (parseError) {
      validationError = 'Please enter valid amount for ad';
    }
    int targetViews = 0;
    try {
      targetViews = double.parse(targetViewsController.text.trim()).toInt();
      if (0>=targetViews) {
        validationError = 'Target views can not be 0 or negative';
      }
    } catch (parseError) {
      validationError = 'Please enter valid target views.';
    }

    if (validationError != null) {
      longToastMessage(validationError);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    loadingcontroller.updateLoading(true);

    try {
      videoUploadUrl = null;
     uploadedMedia.clear();
     int i = 0;
      for (; i < selectedImages.length; i++) {
        final postImage = selectedImages[i];
        final image = await uploadFile(postImage, fileNumber: i);
        uploadedMedia.add(image);
      }

      if (selectedVideo != null && selectedVideo!.existsSync()) {
        i++;
        videoUploadUrl = await uploadFile(selectedVideo!, fileNumber: i);
      }

     loadingcontroller.updateLoading(false);

      RazorpayManager().pay(proposedAmount.toDouble());
    } catch (error) {
      loadingcontroller.updateLoading(false);
      longToastMessage('Failed to upload media files.');
    }
  }

  Future<void> onPaymentSuccess(PaymentSuccessResponse response) async {
    print("ishwar : yash: on payment success: response: ${response.toString()}, payment id: ${response.paymentId}, orderId: ${response.orderId}, ${response.data} ");
    loadingcontroller.updateLoading(true);
    String title = adTitleController.text.trim();
    String actionUrl = adUrlController.text.trim();
    String description = descriptionController.text.trim();

    int proposedAmount = double.parse(proposedAmountController.text.trim()).toInt();
    int targetViews = double.parse(targetViewsController.text.trim()).toInt();

    try {

      final promoterSnapshot = await FirebaseFirestore.instance.collection(CONTACTS_DB).doc(FirebaseAuth.instance.currentUser?.uid).get();
      if (promoterSnapshot.exists) {
        final data = promoterSnapshot.data()??{};

        await FirebaseFirestore.instance.collection(CONTACTS_DB).doc(FirebaseAuth.instance.currentUser?.uid).update({
          'phone': phoneController.text.isEmpty ? data['phone'] : phoneController.text.trim(),
          'email': emailController.text.isEmpty ? data['email'] : emailController.text.trim(),
          'gst_or_pan': gstController.text.isEmpty ? data['gst_or_pan'] : gstController.text.trim(),
        });
      } else {
        await FirebaseFirestore.instance.collection(CONTACTS_DB).doc(FirebaseAuth.instance.currentUser?.uid).set({
          'phone': phoneController.text.isEmpty ? null : phoneController.text.trim(),
          'email': emailController.text.isEmpty ? null : emailController.text.trim(),
          'gst_or_pan': gstController.text.isEmpty ? null : gstController.text.trim(),
        });
      }

      double amountPerView = proposedAmount / targetViews;

      double priority = amountPerView / 100; // Rough estimated maximum amount paid for one ad

      Map<String, dynamic> captureResponse = await RazorpayManager().capture(response, proposedAmount * 100);
      bool captured = captureResponse['captured'] ?? false;


      if (!captured) {
        longToastMessage('Payment failed. Your refund will be provided soon in your bank account in case debited.');
        loadingcontroller.updateLoading(false);
        return;
      }

print(" gadge: doc id:  ${documentReference.id},"
    "    uid: ${FirebaseAuth.instance.currentUser?.uid??''},"
    "    title: $title,"
    "    actionUrl: $actionUrl,"
    "    description: $description,"
    "    videoUrl: $videoUploadUrl,"
    "    images: $uploadedMedia,"
    "    scope: ${scope.map((loc) => loc.name).toList()},"
    "    createdAt: ${DateTime.now()},"
    "    proposedAmount: $proposedAmount,"
    "    targetViews: $targetViews,"
    "    generatedViews: 0,"
    "    paymentId: ${response.paymentId ?? ''},"
    "    priority: $priority,"
    "    randomness: ${AdsFetcher().getRandomDouble() + 0.1 + priority},"
    "    scopeSuffix: ${scope.last.id}"
    "");
      var ad = AdModel(
          documentReference.id,
          uid: FirebaseAuth.instance.currentUser?.uid??'',
          title: title,
          actionUrl: actionUrl,
          description: description,
          videoUrl: videoUploadUrl,
          images: uploadedMedia,
          scope: scope.map((loc) => loc.name).toList(),
          createdAt: DateTime.now(),
          proposedAmount: proposedAmount,
          targetViews: targetViews,
          generatedViews: 0,
          paymentId: response.paymentId ?? '',
          priority: priority,
          randomness: AdsFetcher().getRandomDouble() + 0.1 + priority,
          scopeSuffix: scope.last.id
      );

      await AdsFetcher().postAd(ad);
      loadingcontroller.updateLoading(false);
      longToastMessage('Your ad is successfully added and in process of being live.');
      widget.onAddedCallbacks();
      Get.back();
    } catch (error) {
      loadingcontroller.updateLoading(false);
      longToastMessage(error.toString());
    }
  }

  void onPaymentError(PaymentFailureResponse response) {
    Future.delayed(Duration(milliseconds: 10), () => longToastMessage('Payment failed with error code: ${response.error?['code']??'NONE'}.'));
  }

  void onHandleExternalWallet(ExternalWalletResponse response) {
    Future.delayed(Duration(milliseconds: 10), () => longToastMessage('Can not Handle External Wallet.'));
  }

  Future<String> uploadFile(File file, {int? fileNumber}) async {
    Reference reference = FirebaseStorage.instance
        .ref(AD_DB)
        .child('${documentReference.id}${fileNumber != null ? '-$fileNumber' : ''}');

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

  Column _buildSelectedImages() {
    return Column(
      children: selectedImages.asMap().keys.map((index) {
        final image = selectedImages[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom:
            index == selectedImages.length - 1 ? 0 : 10,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9.0),
            child: Image.file(
              File(image.path),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> mediaAction(BuildContext context) async {
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
  }

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
      selectedImages.clear();
    }

    // imageFile.value = File(image!.path);
    cropView(image);

    setState(() {});
  }

  Future<void> getVideoFromCamera(BuildContext context) async {
    var video = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    // resetting the images
    selectedImages = [];

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

  Future getImageFromGallery(BuildContext context) async {
    var images = await ImagePicker().pickMultiImage(imageQuality: 20);
    if (images.isNotEmpty) {
      images = images.sublist(0, min(3, images.length));

      selectedImages.clear();
    }
    debugPrint("$images");

    // imageFile.value = File(image!.path);
    for (final image in images) {
      await cropView(image);
    }

    setState(() {});
    //
    // print(imageFiles);
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

    // resetting the images
    selectedImages.clear();

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

  cropView(var image) async {
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
    selectedVideo = null;

    selectedImages.add(File(croppedFile!.path));
  }
}