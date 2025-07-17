import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/level_selector_sheet.dart';
import 'package:chunaw/app/dbvertex/organisations/create_organisation_screen.dart';
import 'package:chunaw/app/dbvertex/organisations/my_organization_requests_screen.dart';
import 'package:chunaw/app/dbvertex/organisations/organisation_details_screen.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:chunaw/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/followers_model.dart';
import '../../service/collection_name.dart';
import '../../service/user_service.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_bar.dart';
import '../../utils/app_fonts.dart';
import '../../utils/app_routes.dart';
import '../../widgets/app_button.dart';

class OrganisationScreen extends StatefulWidget {
  const OrganisationScreen({super.key});

  @override
  State<StatefulWidget> createState() => OrganisationState();
}

class OrganisationState extends State<OrganisationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);
  Map<String, String> userIdsOfUsersWeAreFollowing = {};

  List<LocationModel> scopes = [];
  String? selectedPostalId;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final country =
        LocationModel.fromJson(jsonDecode(getPrefValue(Keys.COUNTRY)));
    final state = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.STATE)));
    final city = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.CITY)));
    final postal =
        LocationModel.fromJson(jsonDecode(getPrefValue(Keys.POSTAL)));

    scopes = [country, state, city, postal];
    // scopes = [ postal,city,state,country];
    selectedPostalId = postal.id;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Group',
        elevation: 0,
        actions: [
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              onPressed: () {
                Get.to(MyOrganizationRequestsScreen());
              },
              icon: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("organization_req")
                      .where("admin",
                          isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    return snapshot.data == null || snapshot.data!.docs.isEmpty
                        ? Icon(Icons.notifications_active_sharp)
                        : Badge(
                            label: Text("${snapshot.data!.docs.length}"),
                            child: Icon(
                              Icons.notifications_active_sharp,
                              color: AppColors.primaryColor,
                            ),
                          );
                  }),
            )
        ],
      ),
      floatingActionButton:
          FirebaseAuth.instance.currentUser != null ? _createFabButton() : null,
      body: FirebaseAuth.instance.currentUser == null
          ? Column(
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
            )
          : Column(
              children: [
                _createTabs(),
                // _createLocationSelector(),
                Expanded(
                  child: _createPages(),
                )
              ],
            ),
    );
  }

  Widget _createLocationSelector() {
    if (scopes.isEmpty) {
      return LinearProgressIndicator(
        color: AppColors.gradient1,
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      color: AppColors.textBackColor,
      margin:
          EdgeInsets.symmetric(vertical: 8, horizontal: 8).copyWith(bottom: 0),
      child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    var namedScope = scopes
                        .map(
                          (loc) => loc.name,
                        )
                        .toList();
                    return SizedBox(
                      height: MediaQuery.sizeOf(context).width * 0.08,
                      child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemBuilder: (context, index) => Center(
                                child: Text(
                                  namedScope[index],
                                  style: TextStyle(
                                      fontFamily: AppFonts.Montserrat,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          separatorBuilder: (context, index) => Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(Icons.arrow_forward, size: 12),
                                ),
                              ),
                          itemCount: namedScope.length),
                    );
                  },
                ),
              ),
              Card(
                color: AppColors.primaryColor,
                clipBehavior: Clip.hardEdge,
                margin: EdgeInsets.zero,
                child: InkWell(
                  onTap: () {
                    LevelSelectorSheet.show(context, (state, city, postal) {
                      if (state != null && city != null && postal != null) {
                        scopes.clear();
                        scopes.add(LocationModel(
                            name: 'India', text: "Ind", id: '1-India'));
                        scopes.add(state);
                        scopes.add(city);
                        scopes.add(postal);
                        selectedPostalId = postal.id;
                        setState(() {});
                      } else {
                        longToastMessage("Please all fields mandatory");
                      }
                    },
                        defaultState: scopes.length > 1 ? scopes[1] : null,
                        defaultCity: scopes.length > 2 ? scopes[2] : null,
                        defaultPostal: scopes.length > 3 ? scopes[3] : null,
                        allField: true);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                        .copyWith(right: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20,
                        ),
                        Text(
                          "Change",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          )),
    );
  }

  _createFabButton() {
    return FloatingActionButton(
      onPressed: _onCreateOrganisationClicked,
      child: Icon(Icons.add),
    );
  }

  Future<void> _onCreateOrganisationClicked() async {
    await Get.to(CreateOrganisationScreen());
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
        final organizationRef =
            FirebaseFirestore.instance.collection(USER_DB).doc(data['id']);

        // Query and delete related posts
        final postsQuery = FirebaseFirestore.instance
            .collection('posts')
            .where("user_id", isEqualTo: data['id']);
        final postsSnapshot = await postsQuery.get();

        // Delete all related posts in parallel
        final deletePosts =
            postsSnapshot.docs.map((doc) => doc.reference.delete());

        // Delete organization image if it exists
        final deleteImage = (data['image'] ?? '').isNotEmpty
            ? FirebaseStorage.instance.refFromURL(data['image']).delete()
            : Future.value();

        await Future.wait(
            [organizationRef.delete(), deleteImage, ...deletePosts]);
        longToastMessage('Organization and related posts deleted successfully');
        setState(() {});
        // Update the UI - Remove the deleted organization and posts from the screen
      } catch (error) {
        longToastMessage('Something went wrong');
      } finally {
        loadingcontroller.updateLoading(false);
      }
    }
  }

  _createTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        unselectedLabelColor: Colors.black,
        labelColor: AppColors.gradient1,
        indicatorColor: AppColors.gradient1,
        tabs: [
          Tab(text: 'Groups'),
          Tab(
            text: 'My Groups',
          )
        ],
      ),
    );
  }

  _createPages() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TabBarView(
        controller: _tabController,
        children: [_joinedOrganisations(), _myOrganisations()],
      ),
    );
  }

  _myOrganisations() {
    return _createOrganisationsList(true);
  }

  // _joinedOrganisations() {
  //   return
  //  _createOrganisationsList(false);
  // }
  _joinedOrganisations() {
    return Column(
      children: [
        _createLocationSelector(),
        Expanded(
          child: _createOrganisationsList(false),
        )
      ],
    );
  }

  Future<Stream<QuerySnapshot<Object?>>?> getOrganizationStream(
      bool onlyMine) async {
    try {
      // final docsWhereFollowerIdMatches = await FirebaseFirestore.instance
      //     .collectionGroup(FOLLOWERS_DB)
      //     .where(
      //       'follower_id',
      //       isEqualTo: getPrefValue(Keys.USERID),
      //     )
      //     .get();
      //
      // userIdsOfUsersWeAreFollowing = {};
      //
      // for (QueryDocumentSnapshot doc in docsWhereFollowerIdMatches.docs) {
      //   final followeeId = (doc.data() as Map)['followee_id'];
      //   userIdsOfUsersWeAreFollowing[followeeId] = doc.id;
      // }

      final rootRef = FirebaseFirestore.instance.collection(USER_DB);
      late Query query = rootRef.orderBy('updatedAt', descending: true);

      if (onlyMine) {
        query = query.where('oadmin', isEqualTo: getPrefValue(Keys.USERID));
      } else {
        if (selectedPostalId == null) {
          return null;
        }
        // query = query.orderBy('oadmin').where('postal.id',isEqualTo:LocationModel.fromJson(jsonDecode(getPrefValue(Keys.POSTAL))).id);
        debugPrint(
          "yash: -> selected postal id: $selectedPostalId",
        );
        query = query
            .orderBy('oadmin')
            .where('postal.id', isEqualTo: selectedPostalId);
      }

      return query.snapshots();
    } catch (error) {
      print("Error on getOrganizationStream : $error");
      return null;
    }
  }

  _createOrganisationsList(bool onlyMine) {
    try {
      return FutureBuilder(
          future: getOrganizationStream(onlyMine),
          builder: (context, streamSnapshot) {
            return StreamBuilder(
              stream: streamSnapshot.data,
              builder: (context, snapshot) {
                if (snapshot.error != null) {
                  return Center(
                    child: Text('Something went wrong',
                        textAlign: TextAlign.center),
                  );
                }
                if (snapshot.data == null) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: AppColors.gradient1),
                  );
                }
                final organisations = parseOrganisationData(snapshot.data!);
                print(
                    "yash: organisation length : ${organisations.length}, postal: $selectedPostalId");
                if (organisations.isEmpty) {
                  return Center(
                    child: Text('No organisation yet',
                        textAlign: TextAlign.center),
                  );
                }
                // return Column(
                //   children: [
                //     ListView.separated(
                //       itemCount: organisations.length,
                //       itemBuilder: (context, index) => _createOrganisationTile(
                //           organisations[index], onlyMine),
                //       separatorBuilder: (context, index) =>
                //           Divider(color: Colors.grey[200]),
                //     ),
                //   ],
                // );
                return ListView.separated(
                  itemCount: organisations.length,
                  itemBuilder: (context, index) =>
                      _createOrganisationTile(organisations[index], onlyMine),
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey[200]),
                );
              },
            );
          });
    } catch (error) {
      return Center(
        child: Text('Something went wrong'),
      );
    }
  }

  List<Map<String, dynamic>> parseOrganisationData(
      QuerySnapshot<Object?> snapshot) {
    final organisations = <Map<String, dynamic>>[];
    for (final _data in snapshot.docs) {
      final data = _data.data();
      if (data is Map<String, dynamic>) {
        data['id'] = _data.id;
        organisations.add(data);
      }
    }
    return organisations;
  }

  _createOrganisationTile(Map<String, dynamic> organisation, bool isMine) {
    double size = MediaQuery.sizeOf(context).width;

    return Container(
        color: Colors.white,
        child: InkWell(
          onTap: () async {
            await Get.to(() =>
                OrganisationDetailsScreen(organisationId: organisation['id']));
            setState(() {});
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
                      placeholder: (context, url) => Container(
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
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (organisation['visibility'] == 'Private') ...[
                            SizedBox(width: 3),
                            Icon(Icons.lock, size: 14)
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
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                ),
                isMine
                    ? PopupMenuButton(
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
                            Get.to(CreateOrganisationScreen(
                                organizationId: organisation['id']));
                          }
                        },
                      )
                    : StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection(USER_DB)
                            .doc(organisation['id'])
                            .collection(FOLLOWERS_DB)
                            .where("follower_id",
                                isEqualTo: getPrefValue(Keys.USERID))
                            .snapshots(),
                        builder: (context, snapshot) {
                          final followerModel = snapshot.data == null ||
                                  (snapshot.data?.docs.isEmpty ?? true)
                              ? null
                              : FollowerModel.fromJson({
                                  ...snapshot.data!.docs.first.data(),
                                  'id': snapshot.data!.docs.first.id
                                });

                          return StreamBuilder(
                              stream: organisation['visibility'] == 'Private'
                                  ? FirebaseFirestore.instance
                                      .collection('organization_req')
                                      .where('org_id',
                                          isEqualTo: organisation['id'])
                                      .where('user_id',
                                          isEqualTo: FirebaseAuth
                                              .instance.currentUser!.uid)
                                      .snapshots()
                                  : null,
                              builder: (context, snapshot) {
                                bool? isRequested =
                                    organisation['visibility'] == 'Private'
                                        ? snapshot.data?.docs.isNotEmpty
                                        : false;

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
                                          if (organisation['visibility'] ==
                                              'Private') {
                                            try {
                                              if (isRequested) {
                                                await snapshot
                                                    .data!.docs.first.reference
                                                    .delete();
                                              } else {
                                                final data = {
                                                  'org_id': organisation['id'],
                                                  'user_id': FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid,
                                                  'createdAt': DateTime.now(),
                                                  'admin':
                                                      organisation['oadmin']
                                                };
                                                final reference =
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            'organization_req')
                                                        .doc();

                                                await reference.set(data);
                                              }
                                            } catch (error) {
                                              print("ishwar:new: $error");
                                              longToastMessage(
                                                  'Something went wrong');
                                            }
                                          } else {
                                            await UserService.addFollowers(
                                                followerModel: FollowerModel(
                                                    followerId: FirebaseAuth
                                                        .instance
                                                        .currentUser!
                                                        .uid,
                                                    followeeId:
                                                        organisation['id'],
                                                    createdAt:
                                                        Timestamp.now()));
                                          }
                                        } else {
                                          await UserService.deleteFollowers(
                                              userId: organisation['id'],
                                              followId: followerModel.id!);
                                        }
                                      } catch (error) {
                                        longToastMessage(
                                            'Something went wrong.');
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0, vertical: 6),
                                      child: organisation['visibility'] ==
                                              'Private'
                                          ? Text(
                                              isRequested == null
                                                  ? 'Fetching...'
                                                  : followerModel == null
                                                      ? isRequested
                                                          ? 'Cancel'
                                                          : 'Request'
                                                      : "Leave",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            )
                                          : Text(
                                              followerModel == null
                                                  ? 'Join'
                                                  : "Leave",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                    ),
                                  ),
                                );
                              });
                        })
              ],
            ),
          ),
        ));
  }
}
//////////////////////////////
// import 'dart:convert';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:chunaw/app/dbvertex/organisations/create_organisation_screen.dart';
// import 'package:chunaw/app/dbvertex/organisations/my_organization_requests_screen.dart';
// import 'package:chunaw/app/dbvertex/organisations/organisation_details_screen.dart';
// import 'package:chunaw/app/models/location_model.dart';
// import 'package:chunaw/app/utils/app_colors.dart';
// import 'package:chunaw/app/utils/app_pref.dart';
// import 'package:chunaw/app/widgets/app_toast.dart';
// import 'package:chunaw/main.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:chunaw/app/dbvertex/level_selector_sheet.dart'; // Import LevelSelectorSheet
//
// import '../../models/followers_model.dart';
// import '../../service/collection_name.dart';
// import '../../service/user_service.dart';
// import '../../utils/app_assets.dart';
// import '../../utils/app_bar.dart';
// import '../../utils/app_routes.dart';
// import '../../widgets/app_button.dart';
//
// class OrganisationScreen extends StatefulWidget {
//   const OrganisationScreen({super.key});
//
//   @override
//   State<StatefulWidget> createState() => OrganisationState();
// }
//
// class OrganisationState extends State<OrganisationScreen>
//     with SingleTickerProviderStateMixin {
//   late final TabController _tabController =
//   TabController(length: 2, vsync: this);
//   Map<String, String> userIdsOfUsersWeAreFollowing = {};
//
//   // Location-related variables
//   List<LocationModel> scopes = [];
//   String? selectedPostalId;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeLocation();
//   }
//
//   Future<void> _initializeLocation() async {
//     // Initialize with user's saved location (country, state, city, postal)
//     final country = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.COUNTRY)));
//     final state = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.STATE)));
//     final city = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.CITY)));
//     final postal = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.POSTAL)));
//
//     scopes = [country, state, city, postal];
//     selectedPostalId = postal.id; // Default to user's postal ID
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBarCustom(
//         leadingBack: true,
//         title: 'Group',
//         elevation: 0,
//         actions: [
//           if (FirebaseAuth.instance.currentUser != null)
//             IconButton(
//               onPressed: () {
//                 Get.to(MyOrganizationRequestsScreen());
//               },
//               icon: StreamBuilder(
//                   stream: FirebaseFirestore.instance
//                       .collection("organization_req")
//                       .where("admin",
//                       isEqualTo: FirebaseAuth.instance.currentUser!.uid)
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     return snapshot.data == null || snapshot.data!.docs.isEmpty
//                         ? Icon(Icons.notifications_active_sharp)
//                         : Badge(
//                       label: Text("${snapshot.data!.docs.length}"),
//                       child: Icon(
//                         Icons.notifications_active_sharp,
//                         color: AppColors.primaryColor,
//                       ),
//                     );
//                   }),
//             )
//         ],
//       ),
//       floatingActionButton: FirebaseAuth.instance.currentUser != null
//           ? _createFabButton()
//           : null,
//       body: FirebaseAuth.instance.currentUser == null
//           ? Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text('Please sign in to view this page'),
//           AppButton(
//             onPressed: () {
//               AppRoutes.navigateToLogin();
//             },
//             buttonText: 'Sign in',
//             fontSize: 16,
//           ),
//         ],
//       )
//           : Column(
//         children: [
//           _createTabs(),
//           _createLocationSelector(), // Add location selector
//           Expanded(
//             child: _createPages(),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _createLocationSelector() {
//     if (scopes.isEmpty) {
//       return LinearProgressIndicator(color: AppColors.gradient1);
//     }
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
//       elevation: 0,
//       clipBehavior: Clip.hardEdge,
//       color: AppColors.textBackColor,
//       margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8).copyWith(bottom: 0),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         child: Row(
//           children: [
//             Expanded(
//               child: Builder(builder: (context) {
//                 var namedScope = scopes.map((loc) => loc.name).toList();
//                 return SizedBox(
//                   height: MediaQuery.sizeOf(context).width * 0.08,
//                   child: ListView.separated(
//                     scrollDirection: Axis.horizontal,
//                     shrinkWrap: true,
//                     itemBuilder: (context, index) => Center(
//                       child: Text(
//                         namedScope[index],
//                         style: TextStyle(
//                           fontFamily: 'Montserrat',
//                           color: Theme.of(context).colorScheme.onSurface,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     separatorBuilder: (context, index) => Center(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 2),
//                         child: Icon(Icons.arrow_forward, size: 12),
//                       ),
//                     ),
//                     itemCount: namedScope.length,
//                   ),
//                 );
//               }),
//             ),
//             Card(
//               color: AppColors.primaryColor,
//               clipBehavior: Clip.hardEdge,
//               margin: EdgeInsets.zero,
//               child: InkWell(
//                 onTap: () {
//                   LevelSelectorSheet.show(
//                     context,
//                         (state, city, postal) {
//                       if (state != null && city != null && postal != null) {
//                         scopes.clear();
//                         scopes.add(LocationModel(name: 'India', text: 'IND', id: '1-India'));
//                         scopes.add(state);
//                         scopes.add(city);
//                         scopes.add(postal);
//                         selectedPostalId = postal.id;
//                         setState(() {});
//                       } else {
//                         longToastMessage('Please select all fields');
//                       }
//                     },
//                     defaultState: scopes.length > 1 ? scopes[1] : null,
//                     defaultCity: scopes.length > 2 ? scopes[2] : null,
//                     defaultPostal: scopes.length > 3 ? scopes[3] : null,
//                     allField: true, // Enforce all fields mandatory
//                   );
//                 },
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8)
//                       .copyWith(right: 10),
//                   child: Row(
//                     children: [
//                       Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
//                       Text(
//                         'Change',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   _createFabButton() {
//     return FloatingActionButton(
//       onPressed: _onCreateOrganisationClicked,
//       child: Icon(Icons.add),
//     );
//   }
//
//   Future<void> _onCreateOrganisationClicked() async {
//     await Get.to(CreateOrganisationScreen());
//   }
//
//   Future<void> _deleteOrganization(Map<String, dynamic> data) async {
//     bool delete = await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Confirm Deletion'),
//           content: Text(
//             'This action is irreversible and will permanently delete the organization along with all its members and posts. Are you sure you want to proceed?',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Get.back(result: false);
//               },
//               child: Text(
//                 'Cancel',
//                 style: TextStyle(color: AppColors.gradient1),
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 Get.back(result: true);
//               },
//               child: Text(
//                 'Delete Permanently',
//                 style: TextStyle(color: AppColors.gradient1),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (delete) {
//       loadingcontroller.updateLoading(true);
//       try {
//         final organizationRef =
//         FirebaseFirestore.instance.collection(USER_DB).doc(data['id']);
//
//         final postsQuery = FirebaseFirestore.instance
//             .collection('posts')
//             .where("user_id", isEqualTo: data['id']);
//         final postsSnapshot = await postsQuery.get();
//
//         final deletePosts =
//         postsSnapshot.docs.map((doc) => doc.reference.delete());
//
//         final deleteImage = (data['image'] ?? '').isNotEmpty
//             ? FirebaseStorage.instance.refFromURL(data['image']).delete()
//             : Future.value();
//
//         await Future.wait(
//             [organizationRef.delete(), deleteImage, ...deletePosts]);
//         longToastMessage('Organization and related posts deleted successfully');
//         setState(() {});
//       } catch (error) {
//         longToastMessage('Something went wrong');
//       } finally {
//         loadingcontroller.updateLoading(false);
//       }
//     }
//   }
//
//   _createTabs() {
//     return Container(
//       color: Colors.white,
//       child: TabBar(
//         controller: _tabController,
//         unselectedLabelColor: Colors.black,
//         labelColor: AppColors.gradient1,
//         indicatorColor: AppColors.gradient1,
//         tabs: [
//           Tab(text: 'Groups'),
//           Tab(text: 'My Groups'),
//         ],
//       ),
//     );
//   }
//
//   _createPages() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TabBarView(
//         controller: _tabController,
//         children: [_joinedOrganisations(), _myOrganisations()],
//       ),
//     );
//   }
//
//   _myOrganisations() {
//     return _createOrganisationsList(true);
//   }
//
//   _joinedOrganisations() {
//     return _createOrganisationsList(false);
//   }
//
//   Future<Stream<QuerySnapshot<Object?>>?> getOrganizationStream(
//       bool onlyMine) async {
//     try {
//       final rootRef = FirebaseFirestore.instance.collection(USER_DB);
//       late Query query = rootRef.orderBy('updatedAt', descending: true);
//
//       if (onlyMine) {
//         query = query.where('oadmin', isEqualTo: getPrefValue(Keys.USERID));
//       } else {
//         if (selectedPostalId == null) {
//           return null; // No stream until postal is selected
//         }
//         query = query.orderBy('oadmin').where('postal.id', isEqualTo: selectedPostalId);
//       }
//
//       return query.snapshots();
//     } catch (error) {
//       return null;
//     }
//   }
//
//   _createOrganisationsList(bool onlyMine) {
//     try {
//       return FutureBuilder(
//           future: getOrganizationStream(onlyMine),
//           builder: (context, streamSnapshot) {
//             return StreamBuilder(
//               stream: streamSnapshot.data,
//               builder: (context, snapshot) {
//                 if (snapshot.error != null) {
//                   return Center(
//                     child: Text('Something went wrong',
//                         textAlign: TextAlign.center),
//                   );
//                 }
//                 if (snapshot.data == null) {
//                   return Center(
//                     child:
//                     CircularProgressIndicator(color: AppColors.gradient1),
//                   );
//                 }
//                 final organisations = parseOrganisationData(snapshot.data!);
//                 print("organisation : ${organisations.length}");
//                 if (organisations.isEmpty) {
//                   return Center(
//                     child: Text('No organisation yet',
//                         textAlign: TextAlign.center),
//                   );
//                 }
//                 return ListView.separated(
//                   itemCount: organisations.length,
//                   itemBuilder: (context, index) =>
//                       _createOrganisationTile(organisations[index], onlyMine),
//                   separatorBuilder: (context, index) =>
//                       Divider(color: Colors.grey[200]),
//                 );
//               },
//             );
//           });
//     } catch (error) {
//       return Center(
//         child: Text('Something went wrong'),
//       );
//     }
//   }
//
//   List<Map<String, dynamic>> parseOrganisationData(
//       QuerySnapshot<Object?> snapshot) {
//     final organisations = <Map<String, dynamic>>[];
//     for (final _data in snapshot.docs) {
//       final data = _data.data();
//       if (data is Map<String, dynamic>) {
//         data['id'] = _data.id;
//         organisations.add(data);
//       }
//     }
//     return organisations;
//   }
//
//   _createOrganisationTile(Map<String, dynamic> organisation, bool isMine) {
//     double size = MediaQuery.sizeOf(context).width;
//
//     return Container(
//         color: Colors.white,
//         child: InkWell(
//           onTap: () async {
//             await Get.to(() =>
//                 OrganisationDetailsScreen(organisationId: organisation['id']));
//             setState(() {});
//           },
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: ClipOval(
//                     child: CachedNetworkImage(
//                       fit: BoxFit.cover,
//                       imageUrl: organisation['image'] ?? 'https://',
//                       height: size * 0.165,
//                       width: size * 0.165,
//                       placeholder: (context, url) => Container(
//                         color: Colors.grey[200],
//                       ),
//                       errorWidget: (context, url, error) => Image.asset(
//                         AppAssets.brokenImage,
//                         fit: BoxFit.fill,
//                         height: size * 0.165,
//                         width: size * 0.165,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 4),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Flexible(
//                             child: Text(
//                               organisation['name'] ?? 'Unknown',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.w600),
//                             ),
//                           ),
//                           if (organisation['visibility'] == 'Private') ...[
//                             SizedBox(width: 3),
//                             Icon(Icons.lock, size: 14)
//                           ]
//                         ],
//                       ),
//                       SizedBox(height: 3),
//                       Text(
//                         organisation['userdesc'] ?? 'No description',
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w400),
//                       )
//                     ],
//                   ),
//                 ),
//                 isMine
//                     ? PopupMenuButton(
//                   itemBuilder: (context) {
//                     return [
//                       PopupMenuItem(
//                         value: 'delete',
//                         child: Text('Delete'),
//                       ),
//                       PopupMenuItem(
//                         value: 'edit',
//                         child: Text('Edit'),
//                       )
//                     ];
//                   },
//                   onSelected: (value) {
//                     if (value == 'delete') {
//                       _deleteOrganization(organisation);
//                     } else if (value == 'edit') {
//                       Get.to(CreateOrganisationScreen(
//                           organizationId: organisation['id']));
//                     }
//                   },
//                 )
//                     : StreamBuilder(
//                   stream: FirebaseFirestore.instance
//                       .collection(USER_DB)
//                       .doc(organisation['id'])
//                       .collection(FOLLOWERS_DB)
//                       .where("follower_id",
//                       isEqualTo: getPrefValue(Keys.USERID))
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     final followerModel = snapshot.data == null ||
//                         (snapshot.data?.docs.isEmpty ?? true)
//                         ? null
//                         : FollowerModel.fromJson({
//                       ...snapshot.data!.docs.first.data(),
//                       'id': snapshot.data!.docs.first.id
//                     });
//
//                     return StreamBuilder(
//                       stream: organisation['visibility'] == 'Private'
//                           ? FirebaseFirestore.instance
//                           .collection('organization_req')
//                           .where('org_id', isEqualTo: organisation['id'])
//                           .where('user_id',
//                           isEqualTo:
//                           FirebaseAuth.instance.currentUser!.uid)
//                           .snapshots()
//                           : null,
//                       builder: (context, snapshot) {
//                         bool? isRequested = organisation['visibility'] == 'Private'
//                             ? snapshot.data?.docs.isNotEmpty
//                             : false;
//
//                         return Card(
//                           clipBehavior: Clip.hardEdge,
//                           elevation: 0,
//                           color: AppColors.primaryColor,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: InkWell(
//                             onTap: () async {
//                               try {
//                                 if (isRequested == null) {
//                                   return;
//                                 }
//                                 if (followerModel == null) {
//                                   if (organisation['visibility'] == 'Private') {
//                                     try {
//                                       if (isRequested) {
//                                         await snapshot.data!.docs.first.reference
//                                             .delete();
//                                       } else {
//                                         final data = {
//                                           'org_id': organisation['id'],
//                                           'user_id':
//                                           FirebaseAuth.instance.currentUser!.uid,
//                                           'createdAt': DateTime.now(),
//                                           'admin': organisation['oadmin']
//                                         };
//                                         final reference = FirebaseFirestore.instance
//                                             .collection('organization_req')
//                                             .doc();
//
//                                         await reference.set(data);
//                                       }
//                                     } catch (error) {
//                                       print("ishwar:new: $error");
//                                       longToastMessage('Something went wrong');
//                                     }
//                                   } else {
//                                     await UserService.addFollowers(
//                                         followerModel: FollowerModel(
//                                             followerId: FirebaseAuth
//                                                 .instance.currentUser!.uid,
//                                             followeeId: organisation['id'],
//                                             createdAt: Timestamp.now()));
//                                   }
//                                 } else {
//                                   await UserService.deleteFollowers(
//                                       userId: organisation['id'],
//                                       followId: followerModel.id!);
//                                 }
//                               } catch (error) {
//                                 longToastMessage('Something went wrong.');
//                               }
//                             },
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 10.0, vertical: 6),
//                               child: organisation['visibility'] == 'Private'
//                                   ? Text(
//                                 isRequested == null
//                                     ? 'Fetching...'
//                                     : followerModel == null
//                                     ? isRequested
//                                     ? 'Cancel'
//                                     : 'Request'
//                                     : "Leave",
//                                 style: TextStyle(color: Colors.white),
//                               )
//                                   : Text(
//                                 followerModel == null ? 'Join' : "Leave",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 )
//               ],
//             ),
//           ),
//         ));
//   }
// }