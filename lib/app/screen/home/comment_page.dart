import 'package:chunaw/app/models/comment_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/screen/home/comment_card.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/post_service.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentPage extends StatelessWidget {
  CommentPage({Key? key, required this.postModel}) : super(key: key);
  final PostModel postModel;
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Comments',
        scaffoldKey: null,
        elevation: 0,
      ),
      backgroundColor: AppColors.white,
      body: commentView(),
    );
  }

  Widget commentView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          Expanded(
            child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection(POST_DB)
                    .doc(postModel.postId)
                    .collection(COMMENT_DB)
                    .orderBy("createdAt")
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: CommentCardWidget(
                              commentModel: CommentModel.fromJson(
                                  snapshot.data!.docs[index].id,
                                  snapshot.data!.docs[index].data())),
                        );
                      },
                    );
                  }
                  return Container();
                }),
          ),
          commentField(),
          SizedBox(height: 15.h),
        ],
      ),
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
              CommentModel commentModel = CommentModel(
                  postId: postModel.postId,
                  commentId: "",
                  userId: getPrefValue(Keys.USERID),
                  createdAt: Timestamp.now(),
                  comment: commentController.text);
              PostService.addCommentPost(commentModel: commentModel);
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
}
