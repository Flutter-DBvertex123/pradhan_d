import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shimmer/shimmer.dart';

import '../controller/common/loading_controller.dart';
import '../screen/home/post_card.dart';
import '../utils/app_assets.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/show_snack_bar.dart';

class CertificateDialog extends StatefulWidget {
  final String userName;
  final String userImage;
  final String pradhanName;
  final String scope;
  final int userLevel;
  final double totalContribution;
  const CertificateDialog({super.key,
    required this.userName,
    required this.userImage,
    required this.userLevel,
    required this.totalContribution,
    required this.pradhanName,
    required this.scope,
  });

  static Future<void> show(BuildContext context, String pradhanName, String scope, double totalContributions) async {

    LoadingController loadingcontroller = Get.put(LoadingController());
    loadingcontroller.updateLoading(true);

    final userData = (await FirebaseFirestore.instance.collection(USER_DB).doc(FirebaseAuth.instance.currentUser?.uid).get()).data();

    loadingcontroller.updateLoading(false);

    showDialog(
      context: context,
      builder: (context) => CertificateDialog(
        userName: userData?['name'] ?? 'Unknown',
        userImage: userData?['image'] ?? '',
          userLevel: userData?['level'] ?? 1,
        totalContribution: totalContributions,
        pradhanName: pradhanName,
        scope: scope,
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => CertificateState();

}

class CertificateState extends State<CertificateDialog> {

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CertificateScreenshot(
        userImage: widget.userImage,
        userName: widget.userName,
        userLevel: widget.userLevel,
        totalContribution: widget.totalContribution, pradhanName: widget.pradhanName, scope: widget.scope, isDialog: true,
      ),
    );
  }
}

class CertificateScreenshot extends StatefulWidget {
  final String userName;
  final String userImage;
  final int userLevel;
  final double totalContribution;
  final String pradhanName;
  final String scope;

  final bool isDialog;

  const CertificateScreenshot({super.key,
    required this.userName,
    required this.userImage,
    required this.userLevel,
    required this.totalContribution,
    required this.isDialog, required this.pradhanName, required this.scope,});

  @override
  State<StatefulWidget> createState() => CertificateScreenshotState();
}

class CertificateScreenshotState extends State<CertificateScreenshot> {
  final ScreenshotController screenshotController = ScreenshotController();

  bool isLoading = false;

  Widget createLine(String start, String end, double width) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Text.rich(
        TextSpan(
          text: start,
          style: TextStyle(
            fontWeight: FontWeight.w700,
              fontSize: width * 0.038,
          ),
          children: [
            TextSpan(text: ' '),
            TextSpan(
              text: end,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontSize: width * 0.038,
                color: AppColors.gradient1
              ),
            )
          ]
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    double width =( widget.isDialog ? 0.9 : 1.0) * MediaQuery.sizeOf(context).width;

    final screen = Screenshot(
      controller: screenshotController,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
                child: Image.asset('assets/text_india_map.png')
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Image.asset(
                          'assets/pradhan_cert_logo.png',
                          height: width * 0.18,
                          width: width * 0.28
                        ),
                        Positioned(
                          bottom: width * 0.03,
                          right: width * 0.013,
                          child: Text(
                            'Your Place, Your Voice, Your Leadership',
                            style: TextStyle(
                              fontSize: width * 0.0086,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          left: 0,
                          child: Divider(
                            color: Colors.black,
                            thickness: 2,
                          )
                        )
                      ],
                    ),
                    Spacer(),
                    Column(
                      children: [
                        Card.outlined(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1000),
                            side: BorderSide(
                              color: Colors.black,
                              width: 1.5
                            )
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            height: width * 0.12,
                            width: width * 0.12,
                            imageUrl: widget.userImage,
                            placeholderFadeInDuration: Duration.zero,
                            fit: BoxFit.cover,
                            placeholder: (context, error) => Shimmer.fromColors(
                                baseColor: Colors.grey.withOpacity(0.3),
                                highlightColor: Colors.white,
                                child: Container(color: Colors.black12)
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              AppAssets.brokenImage,
                              fit: BoxFit.cover
                            ),
                          ),
                        ),
                        Text(
                          widget.userName,
                          style: TextStyle(fontSize: width * 0.022, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Software Engineer',
                          style: TextStyle(fontSize: width * 0.022, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: width * 0.03),
                    Text(
                      'Certificate',
                      style: TextStyle(
                          fontSize: width * 0.08,
                        fontFamily: 'MonoType',
                        fontStyle: FontStyle.italic
                      ),
                    ),
                    SizedBox(height: width * 0.05),
                    createLine('It is Certified that', widget.userName, width),
                    createLine('has made a contribution of Rs', widget.totalContribution.toStringAsFixed(2), width),
                    createLine('towards promotion at', widget.scope.replaceAll(RegExp(r'^[^-]-'), ''), width),
                    createLine('under the leadership of', widget.pradhanName, width),
                    SizedBox(height: width * 0.07),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Date: ${DateFormat('d.M.yy').format(DateTime.now())}",
                            style: TextStyle(
                                fontSize: width * 0.035,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Authorized Signatory",
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontSize: width * 0.035,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
    final screenshot = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.isDialog ? screen : Expanded(
          child: Center(
            child: screen,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {

              if (widget.isDialog) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CertificateScreenshot(
                    userName: widget.userName,
                    userImage: widget.userImage,
                    userLevel: widget.userLevel,
                    totalContribution: widget.totalContribution,
                    pradhanName: widget.pradhanName,
                    scope: widget.scope,
                    isDialog: false)));
                return;
              }

              if (isLoading) {
                return;
              }

              try {
                setState(() {
                  isLoading = true;
                });

                final bytes = await screenshotController.capture();

                if (bytes != null) {
                  await Gal.putImageBytes(bytes);

                  if (mounted) {
                    showSnackBar(
                      context,
                      message: 'Pradhaan card downloaded successfully',
                    );
                  }
                } else {
                  if (mounted) {
                    showSnackBar(context,
                        message: 'Error preparing the card');
                  }
                }
              } catch (e) {
                if (mounted) {
                  showSnackBar(context, message: e.toString());
                }
              } finally {
                setState(() {
                  isLoading = false;
                });
              }

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: isLoading
                ? SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text('Download'),
          ),
        ),
      ],
    );

    if (widget.isDialog) {
      return screenshot;
    } else {
      return Scaffold(
        appBar: AppBarCustom(
          title: 'Download Certificate',
          leadingBack: true,
          elevation: 0,
          showSearch: false,
        ),
        body: screenshot,
      );
    }
  }



  Widget _buildPradhanTile(MapEntry<String, Map<String, dynamic>> pradhanEntry) {
    Map<String, dynamic> pradhan = pradhanEntry.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: getColorBasedOnLevel(pradhan['pradhan_level'] ?? 1),
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
                    imageUrl: pradhan['pradhan_image'] ?? '',
                    // .replaceAll('\', '//'),
                    fit: BoxFit.cover,
                    // width: 160.0,
                    height: 160.0,
                  ),
                )),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pradhan['pradhan_name'] ?? 'Unknown',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                // Text('Views Generated: ${pradhan['total_views'] ?? 0}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),),
                Text('Contributed Amount: ₹${(pradhan['total_amount'] as double).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),),
              ],
            ),
          ),
        ],
      ),
    );
  }

}