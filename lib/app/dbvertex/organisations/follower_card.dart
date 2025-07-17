import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/models/followers_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/screen/home/my_profile_screen.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../service/user_service.dart';

class FollowerCard extends StatefulWidget {
  final FollowerModel followerModel;
  final String admin;
  final String organizationId;

  const FollowerCard(
      {super.key,
      required this.followerModel,
      required this.admin,
      required this.organizationId});

  @override
  State<StatefulWidget> createState() => _FollowerState();
}

class _FollowerState extends State<FollowerCard> {
  bool isLoading = false;
  UserModel? userModel;
  @override
  void initState() {
    getUserData();
    super.initState();
  }

  Future<void> getUserData() async {
    try {
      userModel =
          await UserService.getUserData(widget.followerModel.followerId);
    } catch (_) {}
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
        width: 50,
        height: 50,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: userModel?.image ?? '',
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget: (context, url, error) => Image.asset(
              AppAssets.brokenImage,
              fit: BoxFit.fitHeight,
            ),
          ),
        ));
    final name = Text(userModel?.name ?? 'Loading...');
    final username = Text(
      "@${userModel?.username ?? 'Loading...'}",
      style: TextStyle(color: AppColors.primaryColor),
    );
    final String adminTag =
        (widget.admin == widget.followerModel.followerId) ? "Admin" : "";
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          leading: userModel == null ? _shimmer(image) : image,
          title: userModel == null
              ? _shimmer(Container(
                  color: Colors.white,
                  child: name,
                ))
              : name,
          subtitle: userModel == null
              ? _shimmer(Container(
                  color: Colors.white,
                  child: username,
                ))
              : username,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              userModel == null
                  ? _shimmer(Container(
                      color: Colors.white,
                      child: Text("$adminTag"),
                    ))
                  : Text("$adminTag"),
              SizedBox(
                width: 8,
              ),
              PopupMenuButton(
                onSelected: (value) async {
                  switch (value) {
                    case 'view':
                      Get.to(
                          MyProfileScreen(userId: userModel!.id, back: false));
                      break;
                    case 'delete':
                      await UserService.deleteFollowers(
                          userId: widget.organizationId,
                          followId: widget.followerModel.id!);
                      longToastMessage('Deleted member');
                  }
                },
                itemBuilder: (context) => [
                  if (FirebaseAuth.instance.currentUser!.uid == widget.admin)
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  PopupMenuItem(value: 'view', child: Text('Visit Profile')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _shimmer(Widget root) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.withOpacity(0.3),
      highlightColor: Colors.white,
      child: root,
    );
  }
}
