import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentCardWidget extends StatefulWidget {
  const CommentCardWidget({
    Key? key,
    required this.commentModel,
  }) : super(key: key);

  final CommentModel commentModel;

  @override
  State<CommentCardWidget> createState() => _CommentCardWidgetState();
}

class _CommentCardWidgetState extends State<CommentCardWidget> {
  UserModel? userModel;
  @override
  void initState() {
    super.initState();
    getUserModel();
  }

  getUserModel() async {
    userModel = await UserService.getUserData(widget.commentModel.userId);
    setState(() {
      loading = false;
    });
  }

  bool loading = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        loading
            ? userShimmer(add: false)
            : Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  CircleAvatar(
                      radius: 12.r,
                      backgroundColor: AppColors.gradient1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
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
                              fit: BoxFit.fitHeight,
                              width: 160.0,
                              height: 160.0,
                            );
                          },
                          imageUrl: userModel!.image,
                          // .replaceAll('\', '//'),
                          fit: BoxFit.cover,
                          // width: 160.0,
                          height: 160.0,
                        ),
                      )),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userModel!.name,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 1),
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            letterSpacing:
                                0 /*percentages not used in flutter. defaulting to zero*/,
                            fontWeight: FontWeight.normal,
                            height: 1),
                      ),
                    ],
                  ),
                  Expanded(child: SizedBox(width: 15)),
                  Column(
                    children: [
                      // SizedBox(height: 12),
                      Text(
                        timeago.format(widget.commentModel.createdAt.toDate()),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          color: const Color(0xff000000),
                        ),
                        softWrap: false,
                      ),
                    ],
                  )
                ],
              ),
        SizedBox(height: 4.h),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            widget.commentModel.comment,
            textAlign: TextAlign.left,
            style: TextStyle(
                color: Color.fromRGBO(51, 51, 51, 1),
                fontFamily: 'Montserrat',
                fontSize: 12,
                letterSpacing:
                    0 /*percentages not used in flutter. defaulting to zero*/,
                fontWeight: FontWeight.normal,
                height: 1.8),
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}
