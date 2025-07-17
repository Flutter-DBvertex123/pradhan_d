import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/models/followers_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../main.dart';
import '../../service/user_service.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_pref.dart';
import '../../utils/app_routes.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import 'create_organisation_screen.dart';
import 'organisation_details_screen.dart';

class AreaOrganizationsScreen extends StatefulWidget {
  final String locationId;
  const AreaOrganizationsScreen({super.key, required this.locationId});

  @override
  State<StatefulWidget> createState() => AreaOrganizationState();
}

class AreaOrganizationState extends State<AreaOrganizationsScreen> {

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Please sign in to view this page'),
          AppButton(
            onPressed: () {
              AppRoutes.navigateToLogin();
            },
            buttonText: 'Sign in',
            fontSize: 16,
          ),
        ],
      );
    }
    
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection(USER_DB).where('postal.id', isEqualTo: widget.locationId).orderBy('oadmin').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.error != null) {
          return Center(
            child: Text('Something went wrong', textAlign: TextAlign.center),
          );
        }
        if (snapshot.data == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.gradient1),
          );
        }
        List<Map<String, dynamic>>? organizations = snapshot.data?.docs.map<Map<String, dynamic>>((e) {
          return {...e.data(), 'id': e.id};
        }).toList();
        if (organizations!.isEmpty) {
          return Center(
            child: Text('No organisation yet', textAlign: TextAlign.center),
          );
        }
        return ListView.separated(
            itemBuilder: (context, index) {
              return StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection(USER_DB)
                      .doc(organizations[index]['id'])
                      .collection(FOLLOWERS_DB)
                      .where("follower_id",
                      isEqualTo: getPrefValue(Keys.USERID))
                      .snapshots(),
                  builder: (context, snapshot) => _createOrganizationTile(organizations[index], snapshot.data == null || snapshot.data!.docs.isEmpty ? null : FollowerModel.fromJson({...snapshot.data!.docs.first.data(), 'id': snapshot.data!.docs.first.id})),
              );
            },
            separatorBuilder: (context, index) => Divider(color: Colors.grey[200]), 
            itemCount: organizations.length
        );
      }
    );
  }

  _createOrganizationTile(Map<String, dynamic> organisation, FollowerModel? followerModel) {
    double size = MediaQuery.sizeOf(context).width;

    return Container(
        color: Colors.white,
        child: InkWell(
          onTap: () async {
            await Get.to(() => OrganisationDetailsScreen(organisationId: organisation['id']));
            setState(() {

            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: organisation['image'] ?? 'https://',
                      height: size * 0.165,
                      width: size * 0.165,
                      placeholder: (context, url) =>  Container(
                        color: Colors.grey[200],
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        AppAssets.brokenImage,
                        fit: BoxFit.fill,
                        height: size * 0.165,
                        width: size * 0.165,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              organisation['name'] ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600
                              ),
                            ),
                          ),
                          if (organisation['visibility'] == 'Private') ...[
                            SizedBox(width: 3),
                            Icon(
                                Icons.lock,
                                size: 14
                            )
                          ]
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        organisation['userdesc'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w400
                        ),
                      )
                    ],
                  ),
                ),
                organisation['oadmin'] == getPrefValue(Keys.USERID) ? PopupMenuButton(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      )
                    ];
                  },
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteOrganization(organisation);
                    } else if (value == 'edit') {
                      Get.to(CreateOrganisationScreen(organizationId: organisation['id']));
                    }
                  },
                ) : StreamBuilder(
                    stream: organisation['visibility'] == 'Private'? FirebaseFirestore.instance.collection('organization_req')
                        .where('org_id', isEqualTo: organisation['id']).where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid).snapshots() : null,
                    builder: (context, snapshot) {
                      bool? isRequested =  organisation['visibility'] == 'Private' ? snapshot.data?.docs.isNotEmpty : false;

                    return Card(
                      clipBehavior: Clip.hardEdge,
                      elevation: 0,
                      color: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () async {
                          try {
                            if (isRequested == null) {
                              return;
                            }
                            if (followerModel == null) {
                              if (organisation['visibility'] == 'Private') {
                                try {
                                  if (isRequested) {
                                    await snapshot.data!.docs.first.reference.delete();
                                  } else {
                                    final data = {
                                      'org_id': organisation['id'],
                                      'user_id': FirebaseAuth.instance.currentUser!.uid,
                                      'createdAt': DateTime.now(),
                                      'admin': organisation['oadmin']
                                    };
                                    final reference = FirebaseFirestore.instance.collection('organization_req').doc();

                                    await reference.set(data);
                                  }
                                } catch (error) {
                                  print("ishwar:new: $error");
                                  longToastMessage('Something went wrong');
                                }
                              } else {
                                await UserService.addFollowers(followerModel: FollowerModel(followerId: FirebaseAuth.instance.currentUser!.uid, followeeId: organisation['id'], createdAt: Timestamp.now()));
                              }
                            } else {
                              await UserService.deleteFollowers(userId: organisation['id'], followId: followerModel.id!);
                            }
                          } catch (error) {
                            longToastMessage('Something went wrong.');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
                          child: organisation['visibility'] == 'Private' ? Text(
                             isRequested == null ? 'Fetching...' : followerModel == null ? isRequested ? 'Cancel' : 'Request' : "Leave",
                            style: TextStyle(
                                color: Colors.white
                            ),
                          ) : Text(
                             followerModel == null ? 'Join' : "Leave",
                            style: TextStyle(
                                color: Colors.white
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                )
              ],
            ),
          ),
        )
    );
  }

  Future<void> _deleteOrganization(Map<String, dynamic> data) async {
    bool delete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(
            'This action is irreversible and will permanently delete the organization along with all its members and posts. Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(result: false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.gradient1),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back(result: true);
              },
              child: Text(
                'Delete Permanently',
                style: TextStyle(color: AppColors.gradient1),
              ),
            ),
          ],
        );
      },
    );

    if (delete) {
      loadingcontroller.updateLoading(true);
      try {
        final reference = FirebaseFirestore.instance.collection(USER_DB).doc(data['id']);
        await Future.wait([
          reference.delete(),
          if ((data['image'] ?? '').isNotEmpty) FirebaseStorage.instance.refFromURL(data['image']).delete()
        ]);
      } catch (error) {
        longToastMessage('Something went wrong');
      }
      loadingcontroller.updateLoading(false);
    }
  }

}