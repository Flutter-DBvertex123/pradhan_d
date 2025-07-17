import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/v4.dart';

class DownloadPradhaanCardScreen extends StatefulWidget {
  const DownloadPradhaanCardScreen({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.userLevelLocation,
    required this.isPradhaanAtHisLevel,
    required this.votesReceived,
    required this.fundsRaised,
    required this.autoFund,
  });

  final String imageUrl;
  final String name;
  final String userLevelLocation;
  final bool isPradhaanAtHisLevel;
  final String votesReceived;
  final String fundsRaised;
  final String autoFund;

  @override
  State<DownloadPradhaanCardScreen> createState() =>
      _DownloadPradhaanCardScreenState();
}

class _DownloadPradhaanCardScreenState
    extends State<DownloadPradhaanCardScreen> {
  final screenshotController = ScreenshotController();
  bool isLoading = false;
  final _backgroundColor = const Color(0xFFEEE8F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: 'Pradhaan Card',
        leadingBack: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              color: _backgroundColor,
              child: Screenshot(
                controller: screenshotController,
                child: Container(
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    border: Border.all(
                      width: 20,
                      color: _backgroundColor,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      border: Border.all(
                        width: 2,
                        color: Colors.black,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Image.asset('assets/text_india_map.png'),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.black,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 2,
                                      spreadRadius: 1,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Pradhaan Card'.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              _buildProfileImage(widget.imageUrl),
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                widget.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Image.asset(
                                'assets/pradhaan_card_divider.png',
                                width: min(
                                    120, MediaQuery.of(context).size.width / 2),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              _buildExitDialogDataRow(
                                'User Level:',
                                valueWidget: Text(
                                  widget.userLevelLocation +
                                      (widget.isPradhaanAtHisLevel
                                          ? ' - Pradhaan'
                                          : ''),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildExitDialogDataRow(
                                'Designation:',
                                valueWidget: Text(
                                (widget.isPradhaanAtHisLevel
                                          ? '  ${widget.userLevelLocation} - Pradhaan'
                                          : 'N/A'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildExitDialogDataRow(
                                'Votes:',
                                value: widget.votesReceived.toString(),
                              ),
                              _buildExitDialogDataRow(
                                'Fund Raised',
                                // value: widget.fundsRaised.toString(),
                                value: double.parse(widget.fundsRaised.toString()).toStringAsFixed(2),
                              ),
                              // const SizedBox(
                              //   height: 20,
                              // ),
                              // _buildExitDialogDataRow(
                              //     'Contributions to\nPradhaan Free Taxi',
                              //     titleColor: AppColors.primaryColor,
                              //     value: widget.autoFund),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
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
      ),
    );
  }

  Row _buildExitDialogDataRow(
    String title, {
    Color? titleColor,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        if (value != null)
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
              fontSize: 18,
            ),
          ),
        if (valueWidget != null) valueWidget
      ],
    );
  }

  Widget _buildProfileImage(String profilePhoto) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: Colors.black,
        ),
        borderRadius: BorderRadius.circular(45),
      ),
      child: CircleAvatar(
        radius: 45.r,
        backgroundColor: AppColors.gradient1,
        child: ClipOval(
          clipBehavior: Clip.hardEdge,
          child: CachedNetworkImage(
            placeholder: (context, error) {
              // printError();
              return CircleAvatar(
                radius: 35.r,
                backgroundColor: AppColors.gradient1,
                child: Center(
                    child: CircularProgressIndicator(
                  color: AppColors.highlightColor,
                )),
              );
            },
            errorWidget: (context, error, stackTrace) {
              // printError();
              return Image.asset(
                AppAssets.brokenImage,
                fit: BoxFit.fitHeight,
                // width: 160.0,
                height: 122.0,
              );
            },
            imageUrl: profilePhoto,
            // .replaceAll('\', '//'),
            fit: BoxFit.cover,
            // width: 160.0,
            height: 160.0,
          ),
        ),
      ),
    );
  }
}
