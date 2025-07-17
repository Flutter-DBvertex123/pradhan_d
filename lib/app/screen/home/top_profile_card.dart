import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SachivProfileCard extends StatefulWidget {
  const SachivProfileCard({Key? key, required this.userModel})
      : super(key: key);
  final UserModel userModel;
  @override
  State<SachivProfileCard> createState() => _SachivProfileCardState();
}

class _SachivProfileCardState extends State<SachivProfileCard> {
  TextEditingController commentController = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // Shadow color
            spreadRadius: 2, // Spread radius
            blurRadius: 5, // Blur radius
            offset: Offset(0, 3), // Offset from the top
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11.0, vertical: 1.5),
      child: InkWell(
        onTap: () {
          AppRoutes.navigateToMyProfile(
              userId: widget.userModel.id, isOrganization: widget.userModel.isOrganization, back: true);
        },
        child: Row(
          children: [
            CircleAvatar(
                radius: 12.r,
                backgroundColor: AppColors.gradient1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    placeholder: (context, error) {
                      return CircleAvatar(
                        radius: 12.r,
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
                        fit: BoxFit.cover,
                        // width: 160.0,
                        height: 20.0,
                      );
                    },
                    imageUrl: widget.userModel.image,
                    // .replaceAll('\', '//'),
                    fit: BoxFit.cover,
                    // width: 160.0,
                    height: 160.0,
                  ),
                )),
            SizedBox(width: 10),
            Text(
              widget.userModel.name,
              textAlign: TextAlign.left,
              style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  letterSpacing:
                      0 /*percentages not used in flutter. defaulting to zero*/,
                  fontWeight: FontWeight.normal,
                  height: 1),
            ),
          ],
        ),
      ),
    );
  }
}
