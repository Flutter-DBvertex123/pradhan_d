import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/models/like_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/screen/home/post_card.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/vote_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:like_button/like_button.dart';

class UserCard extends StatefulWidget {
  const UserCard(
      {super.key,
      required this.userModel,
      this.onVoteUpdateFun,
      this.overrideOnPressed,
      this.upvote = false});
  final UserModel userModel;
  final Function()? onVoteUpdateFun;
  final LikeButtonTapCallback? overrideOnPressed;
  final bool upvote;

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.only(
            left: 16.0.sp, right: 16.0.sp, top: 9.0.sp, bottom: 9.0.sp),
        child: InkWell(
          onTap: () {
            AppRoutes.navigateToMyProfile(
              isOrganization: widget.userModel.isOrganization,
                userId: widget.userModel.id, back: true);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CircleAvatar(
                radius: 17.r,
                backgroundColor: getColorBasedOnLevel(widget.userModel.level),
                child: CircleAvatar(
                    radius: 15.r,
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
                        imageUrl: widget.userModel.image,
                        // .replaceAll('\', '//'),
                        fit: BoxFit.cover,
                        // width: 160.0,
                        height: 160.0,
                      ),
                    )),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userModel.name,
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
                  // SizedBox(
                  //   height: 7,
                  // ),
                  // SizedBox(
                  //   width: Get.width * 0.35,
                  //   child: Text(
                  //     "${widget.postModel.fullAdd.sublist(0, 3).join(",")}.",
                  //     textAlign: TextAlign.left,
                  //     style: TextStyle(
                  //         color: Color.fromRGBO(51, 51, 51, 1),
                  //         fontFamily: 'Montserrat',
                  //         fontSize: 10,
                  //         letterSpacing:
                  //             0 /*percentages not used in flutter. defaulting to zero*/,
                  //         fontWeight: FontWeight.normal,
                  //         height: 1),
                  //   ),
                  // )
                ],
              ),
              Expanded(
                child: SizedBox(
                  width: 15,
                ),
              ),
              Column(
                children: [
                  upvoteButton(),
                  const SizedBox(
                    height: 5,
                  ),
                  StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection(USER_DB)
                          .doc(widget.userModel.id)
                          .snapshots(),
                      builder: (context, AsyncSnapshot snapshot) {
                        // grabbing the data
                        final votes = snapshot.data == null
                            ? 0
                            : snapshot.data.data()['weekly_vote'];

                        return Text(
                          "$votes Votes",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Color.fromRGBO(51, 51, 51, 1),
                              fontFamily: 'Montserrat',
                              fontSize: 12.sp,
                              letterSpacing:
                                  0 /*percentages not used in flutter. defaulting to zero*/,
                              fontWeight: FontWeight.normal,
                              height: 1),
                        );
                      }),
                  //  Icon(
                  //   Icons.chat_bubble_outline,
                  //   color: AppColors.gradient1,
                  //   size: 25,
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget upvoteButton() {
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(USER_DB)
            .doc(widget.userModel.id)
            .collection(UPVOTE_DB)
            .where('user_id', isEqualTo: getPrefValue(Keys.USERID))
            .where('post_id', isEqualTo: "Prdhan Voting")
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          return LikeButton(
            isLiked: snapshot.data != null && snapshot.data!.docs.isNotEmpty,
            bubblesColor: BubblesColor(
              dotPrimaryColor: AppColors.gradient2,
              dotSecondaryColor: AppColors.gradient1,
            ),
            circleSize: 20,
            onTap: widget.overrideOnPressed ?? (isLiked) async {
            // is is guest, redirect to login instead
            if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
              AppRoutes.navigateToLogin();
              return isLiked;
            }

            if (widget.upvote) {
              if (isLiked) {
                VoteService.unVotePradhan(
                  userId: widget.userModel.id,
                  upvoteId: snapshot.data!.docs[0].id,
                );
              } else {
                UpLikeModel likeModel = UpLikeModel(
                    postId: "Prdhan Voting",
                    userId: getPrefValue(Keys.USERID),
                    postUserId: widget.userModel.id,
                    createdAt: Timestamp.now());
                VoteService.pradhanVotingUpvote(upvoteModel: likeModel);
              }
              widget.onVoteUpdateFun?.call();
              return !isLiked;
            } else {
              longToastMessage(
                  "You can only vote in your location and once voting starts");
              return null;
            }
          },
            likeBuilder: (isLiked) {
              return isLiked
                  ? Container(
                      alignment: Alignment.center,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1.5,
                            color: AppColors.darkRedColor,
                          ),
                          borderRadius: BorderRadius.circular(200),
                          // color: AppColors.black,
                        ),
                        padding: EdgeInsets.all(0.5),
                        alignment: Alignment.center,
                        child: Image.asset(AppAssets.voteActiveImage,),
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      child: Container(
                        height: 25,
                        width: 25,
                        decoration: BoxDecoration(
                           color: AppColors.darkRedColor,
                          border: Border.all(
                            width: 1.5,
                            color: AppColors.darkRedColor,
                          ),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(0.5),
                        child: Image.asset(AppAssets.voteActiveImage),
                      ),
                    );
            },
            circleColor:
                CircleColor(start: AppColors.white, end: AppColors.white),
          );
        });
  }
}
