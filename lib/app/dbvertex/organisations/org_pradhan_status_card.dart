import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/controller/home/welcome_location_controller.dart';
import 'package:chunaw/app/dbvertex/organisations/org_pradhan_controller.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OrgPradhanStatusCard extends StatefulWidget {
  const OrgPradhanStatusCard({
    super.key,
    required this.organizationId,
  });

  final String organizationId;
  @override
  State<OrgPradhanStatusCard> createState() => _PradhanStatusCardState();
}

class _PradhanStatusCardState extends State<OrgPradhanStatusCard> {
  late final orgPradhanController = Get.find<OrgPradhanController>();

  @override
  void initState() {
    orgPradhanController.initialize();
    super.initState();
  }

  TextEditingController statusController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Pradhaan Board',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(color: Colors.grey.shade400),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        orgPradhanController.pradhanId.value.isEmpty
                            ? Container()
                            : CircleAvatar(
                          radius: 23.r,
                          backgroundColor: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.hardEdge,
                            child: CachedNetworkImage(
                              placeholder: (context, error) {
                                return CircleAvatar(
                                  radius: 20.r,
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
                              imageUrl:
                              orgPradhanController.pradhan.value?.image ?? '',
                              // .replaceAll('\', '//'),
                              fit: BoxFit.cover,
                              // width: 160.0,
                              height: 160.0,
                            ),
                          ),
                        ),
                        SizedBox(
                            width:
                            orgPradhanController.pradhanId.value.isEmpty ? 0 : 8),
                        Expanded(
                          child: Text(
                            orgPradhanController.pradhanStatus != ""
                                ? orgPradhanController.pradhanStatus
                                : orgPradhanController.isCurrentUserPradhaan.value
                                ? 'Hello ${orgPradhanController.pradhan.value?.name} please set status'
                                : 'No Pradhaan Updates',
                            maxLines: null,
                            textAlign: orgPradhanController.pradhanId.value.isEmpty
                                ? TextAlign.center
                                : TextAlign.left,
                            style: TextStyle(
                                fontStyle:
                                orgPradhanController.pradhanStatus.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: Colors.black,
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                letterSpacing:
                                0 /*percentages not used in flutter. defaulting to zero*/,
                                fontWeight: FontWeight.normal,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  orgPradhanController.isCurrentUserPradhaan.value
                      ? Container(
                    color: Colors.grey.shade200,
                    child: commentField(),
                  )
                      : Container(),
                ],
              ),
            ),
          );
        });
  }

  Widget commentField() {
    return Container(
      color: Colors.transparent,
      margin: EdgeInsets.only(bottom: 10, left: 5, right: 5),
      padding: EdgeInsets.only(left: 5, bottom: 5, top: 10, right: 5),
      height: 60,
      width: double.infinity,

      // color: Colors.black,
      child: Row(
        children: <Widget>[
          Expanded(
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.0),
                    border: Border.all(color: AppColors.black)),
                child: TextField(
                  controller: statusController,
                  maxLines: 5,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(color: AppColors.black),
                  decoration: InputDecoration(
                      hintText: "Set Board Status...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: AppColors.black,
                        fontSize: 14,
                      ),
                      prefix: Text("    "),
                      suffixIcon: InkWell(
                        onTap: () {
                          PradhanService.setPradhanStatus(
                              docId: widget.organizationId,
                              pradhanStatus: statusController.text.trim());
                          orgPradhanController.pradhanStatus = statusController.text.trim();
                          statusController.text = "";
                        },
                        child: Icon(
                          Icons.add,
                          color: AppColors.black,
                        ),
                      ),
                      contentPadding: EdgeInsets.only(bottom: 5.0)),
                ),
              )),
          // SizedBox(width: 15),

          // SizedBox(width: 5),
        ],
      ),
    );
  }
}
