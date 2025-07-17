import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/screen/home/my_profile_screen.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/followers_model.dart';
import '../../screen/home/post_card.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_bar.dart';

class MyOrganizationRequestsScreen extends StatefulWidget {
  const MyOrganizationRequestsScreen({super.key});

  @override
  State<StatefulWidget> createState() => MyOrganizationRequestsState();
}

class MyOrganizationRequestsState extends State<MyOrganizationRequestsScreen> {

  List<Map<String, dynamic>>? requests;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Requests',
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('organization_req').where('admin',isEqualTo: FirebaseAuth.instance.currentUser!.uid).orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              parseRequests(snapshot.data?.docs);
              if (requests == null) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primaryColor),
                );
              }
              if (requests!.isEmpty) {
                return Center(
                  child: Text('No requests'),
                );
              }
              return ListView.separated(
                  itemBuilder: (context, index) => _createTile(index),
                  separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
                  itemCount: requests!.length
              );
            },
        ),
      ),
    );
  }

  Future<UserModel> _getUser(String id) async {
    try {
      return UserModel.fromJson((await FirebaseFirestore.instance.collection(USER_DB).doc(id).get()).data() ?? {});
    } catch (errr) {
      return UserModel.empty();
    }
  }

  _createTile(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: FutureBuilder(
        future: _getUser(requests![index]['user_id']),
        builder: (context, snapshot) {
          final tile = Container(
            color: Colors.white,
            child: InkWell(
              onTap: () => Get.to(MyProfileScreen(userId: requests![index]['user_id'], back: true)),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20).copyWith(right: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundColor: getColorBasedOnLevel(1),
                      child: CircleAvatar(
                          radius: 25.r,
                          backgroundColor: AppColors.gradient1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.hardEdge,
                            child: CachedNetworkImage(
                              placeholder: (context, error) {
                                return CircleAvatar(
                                  radius: 25.r,
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
                              imageUrl: snapshot.data?.image ?? '',
                              // .replaceAll('\', '//'),
                              fit: BoxFit.cover,
                              // width: 160.0,
                              height: 160.0,
                            ),
                          )),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(snapshot.data?.name ?? 'Loading', style:
                          TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 16
                          ),),
                          FutureBuilder(
                              future: UserService.getUserData(requests![index]['org_id']??''),
                            builder: (context, snapshot) {
                              return Text(snapshot.data == null ? 'Fetching...' : 'Requested to join ${snapshot.data!.name}',
                                style:
                              TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13
                              ),);
                            }
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: 4),
                    Card(
                      clipBehavior: Clip.hardEdge,
                      color: AppColors.primaryColor,
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () async {
                          try {
                            final snapshot = await FirebaseFirestore.instance.collection('organization_req')
                                .where('org_id', isEqualTo: requests![index]['org_id']).where('user_id', isEqualTo: requests![index]['user_id']).get();

                
                            final followerModel = FollowerModel(
                                followerId: requests![index]['user_id'],
                                followeeId: requests![index]['org_id'],
                                createdAt: Timestamp.now()
                            );


                            await snapshot.docs.first.reference.delete();
                          await UserService.addFollowers(followerModel: followerModel);

                          } catch (error) {
                            print("ishwar:new: $error");
                            longToastMessage('Something went wrong');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: Text(
                            'Accept',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 12
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          final snapshot = await FirebaseFirestore.instance.collection('organization_req')
                              .where('org_id', isEqualTo: requests![index]['org_id']).where('user_id', isEqualTo: requests![index]['user_id']).get();
                          await snapshot.docs.first.reference.delete();
                        } catch (error) {
                          longToastMessage('Something went wrong');
                        }
                      },
                      icon: Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          );

          return snapshot.data == null ? Shimmer.fromColors(baseColor: Colors.white, highlightColor: Colors.grey, child: tile) : tile;
        }
      ),
    );
  }

  void parseRequests(List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs) {
    if (docs != null) {
      requests = docs.map((e) => e.data()).toList();
    }
  }
}