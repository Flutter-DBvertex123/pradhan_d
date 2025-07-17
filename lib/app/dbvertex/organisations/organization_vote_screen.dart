import 'package:chunaw/app/dbvertex/organisations/organisation_voting_controller.dart';
import 'package:chunaw/app/dbvertex/widgets/organization_voter_card.dart';
import 'package:chunaw/app/screen/Location_features/voting_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../models/comment_model.dart';
import '../../models/location_model.dart';
import '../../screen/home/comment_card.dart';
import '../../screen/shimmer/post_shimmer.dart';
import '../../service/collection_name.dart';
import '../../service/pradhan_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_pref.dart';
import '../../utils/app_routes.dart';

class OrganizationVoteScreen extends StatefulWidget {
  final String organizationID;

  const OrganizationVoteScreen({super.key, required this.organizationID});

  @override
  State<StatefulWidget> createState() => OrganizationVoteState();
}

class OrganizationVoteState extends State<OrganizationVoteScreen> {
  late final OrganisationVotingController organisationVotingController;

  final commentController = TextEditingController();

  @override
  void initState() {
    organisationVotingController = OrganisationVotingController(organizationID: widget.organizationID);
    organisationVotingController.initialize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final test = await FirebaseFirestore.instance.collection('users').where('visibility', whereIn: ['Private', 'Public']).get();
                      print("ishwar:posting ${test.docs.length}");
                    },
                    child: VotingTimerWidget(),
                  ),
                  userArea(),
                  commentView()
                ],
              ),
            ),
          ),
        ),
        Obx(
              () => !organisationVotingController.voting.value
              ? Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 20,
              top: 20,
            ),
            child: Text(
              "Voting is not started yet, you can comment once voting is started",
              textAlign: TextAlign.center,
            ),
          )
              : commentField(),
        ),
      ],
    );
  }

  Widget commentView() {
    final now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month);
    DateTime endOfMonth =
    DateTime(now.year, now.month + 1);
    print("ishwar:new comment ${endOfMonth}");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 10.h),
        Divider(height: 2, color: AppColors.greyTextColor),
        SizedBox(height: 10.h),
        StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection(PRADHAN_DB)
                .doc(widget.organizationID)
                .collection(COMMENT_DB)
                .where('createdAt',
                isGreaterThanOrEqualTo: startOfMonth,
                isLessThan: endOfMonth)
                .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                Center(child: CupertinoActivityIndicator());
              }
              if (!snapshot.hasData) {
                Container();
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 16.0.sp,
                            right: 16.0.sp,
                            top: 16.0.sp,
                            bottom: 0.0.sp),
                        child: CommentCardWidget(
                            commentModel: CommentModel.fromJson(
                                snapshot.data!.docs[index].id,
                                snapshot.data!.docs[index].data())),
                      ),
                    );
                  },
                );
              }
              return Container();
            }),
      ],
    );
  }

  Widget commentField() {
    return Container(
      color: Colors.transparent,
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
                    border: Border.all(color: Colors.black54)),
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                      hintText: "Type Here...",
                      border: InputBorder.none,
                      prefix: Text("    "),
                      contentPadding: EdgeInsets.only(bottom: 5.0)),
                ),
              )),
          SizedBox(width: 15),
          InkWell(
            onTap: () {
              // if is guest login, ask to login
              if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
                AppRoutes.navigateToLogin(removeGuestLogin: true);
                return;
              }

              CommentModel commentModel = CommentModel(
                  postId: widget.organizationID,
                  commentId: commentController.text,
                  userId: getPrefValue(Keys.USERID),
                  createdAt: Timestamp.now(),
                  comment: commentController.text);
              PradhanService.addCommentPradhanLocation(
                  commentModel: commentModel);
              commentController.text = "";
            },
            child: Icon(
              Icons.send,
              color: AppColors.gradient1,
            ),
          ),
          SizedBox(width: 5),
        ],
      ),
    );
  }


  Widget userArea() {
    return Obx(
          () => organisationVotingController.isLoading.value
          ? ListView.builder(
        shrinkWrap: true,
        itemCount: 10,
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 10),
        itemBuilder: (BuildContext context, int index) {
          return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.only(
                    left: 16.0.sp,
                    right: 16.0.sp,
                    top: 9.0.sp,
                    bottom: 9.0.sp),
                child: userShimmer(),
              )
          );
        },
      )
          : ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: organisationVotingController.userList.value.length,
        padding: EdgeInsets.only(top: 10),
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: OrganizationVoterCard(
              userModel: organisationVotingController.userList.value[index],
              upvote: organisationVotingController.voting.value,
              onVoteUpdateFun: () {
                organisationVotingController.initialize();
              }, organizationId: widget.organizationID,
            ),
          );
        },
      ),
    );
  }
}