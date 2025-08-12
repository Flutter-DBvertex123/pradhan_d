import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/organisations/organisation_screen.dart';
import 'package:chunaw/app/dbvertex/promoters_screen.dart';
import 'package:chunaw/app/screen/admin/location_admin.dart';
import 'package:chunaw/app/screen/home/select_election_location.dart';
import 'package:chunaw/app/screen/home/select_states_screen.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/firebase_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../dbvertex/my_ads_screen.dart';
import '../dbvertex/new_withdraw_screen.dart';
import '../screen/home/edit_home_location_page.dart';
import '../screen/home/my_profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key, this.onStatePreferenceUpdated}) : super(key: key);

  final Function? onStatePreferenceUpdated;

  @override
  Widget build(BuildContext context) {
    // if is guest login
    final isGuestLogin = Pref.getBool(Keys.IS_GUEST_LOGIN, false);

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: <Widget>[
                UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                      begin: Alignment(-0.35, -1.272),
                      end: Alignment(0.84, 0.87),
                      colors: [AppColors.gradient1, AppColors.gradient2],
                      stops: [0.0, 1.0],
                      tileMode: TileMode.mirror,
                    )),
                    accountName: isGuestLogin
                        ? Text('Guest')
                        : Text(getPrefValue(Keys.NAME)),
                    accountEmail: isGuestLogin
                        ? null
                        : Text("@${getPrefValue(Keys.USERNAME)}"),
                    currentAccountPicture: ClipOval(
                      child: CachedNetworkImage(
                        placeholder: (context, error) {
                          return CircleAvatar(
                            radius: 14.r,
                            backgroundColor: AppColors.gradient1,
                            child: Center(
                                child: CircularProgressIndicator(
                              color: AppColors.highlightColor,
                            )),
                          );
                        },
                        errorWidget: (context, error, stackTrace) {
                          return CircleAvatar(
                            backgroundColor: AppColors.highlightColor,
                            child: Text(
                              // "M",
                              isGuestLogin
                                  ? 'G'
                                  : "${getPrefValue(Keys.NAME)[0].capitalize}",
                              style: TextStyle(fontSize: 40.0),
                            ),
                          );
                        },
                        imageUrl: getPrefValue(Keys.PROFILE_PHOTO),
                        fit: BoxFit.cover,
                        // width: 150.0,
                        height: 150.0,
                      ),
                    )),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: SvgPicture.asset(AppAssets.homeIcon),
                  ),
                  title: Text("Home"),
                  dense: false,
                  minLeadingWidth: 10,
                  onTap: () {
                    AppRoutes.navigateOffHomeTabScreen();
                  },
                ),
                // for now, show this only for admin
                if (getPrefValue(Keys.ADMIN) == '1')
                  ListTile(
                    leading: Icon(CupertinoIcons.settings),
                    dense: false,
                    minLeadingWidth: 10,
                    title: Text("Settings"),
                    onTap: () {
                      if (getPrefValue(Keys.ADMIN) == "1") {
                        Get.to(() => LocationAdmin(
                              type: LoactionType.State,
                            ));
                      } else {
                        Get.back();
                      }
                    },
                  ),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.star_rate_rounded, size: 25),
                  ),
                  dense: false,
                  minLeadingWidth: 10,
                  title: Text("State Preferences"),
                  onTap: () async {
                    final updated = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SelectStatesScreen(),
                      ),
                    );

                    if (updated && onStatePreferenceUpdated != null) {
                      onStatePreferenceUpdated!();
                    }
                  },
                ),

                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.location_city, size: 25),
                  ),
                  dense: false,
                  minLeadingWidth: 10,
                  title: Text("Groups"),
                  subtitle: Text("College, Ward, NGO, Union etc"),
                  subtitleTextStyle:
                      TextStyle(color: Colors.grey[500], fontSize: 13),
                  onTap: () async {
                    final updated = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OrganisationScreen(),
                      ),
                    );

                    if (updated && onStatePreferenceUpdated != null) {
                      onStatePreferenceUpdated!();
                    }
                  },
                ),
                // ListTile(
                //   leading: Padding(
                //     padding: const EdgeInsets.only(left: 2.0),
                //     child: Icon(Icons.local_taxi, size: 25),
                //   ),
                //   dense: false,
                //   minLeadingWidth: 10,
                //   title: Text("Free Auto Ride"),
                //   onTap: () async {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (context) => FreeAutoRideCampaignScreen(),
                //       ),
                //     );
                //   },
                // ),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.attach_money, size: 25),
                  ),
                  dense: false,
                  minLeadingWidth: 10,
                  title: Text("Your Account"),
                  onTap: () async {
                    if (isGuestLogin) {
                      AppRoutes.navigateToLogin();
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NewWithdrawScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.ads_click, size: 25),
                  ),
                  dense: false,
                  minLeadingWidth: 10,
                  title: Text("Promote Pradhaan"),
                  onTap: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MyAdsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.people_alt_outlined, size: 25),
                  ),
                  dense: false,
                  minLeadingWidth: 10,
                  title: Text("Promoters List"),
                  onTap: () async {
                    final userSnapshot = await FirebaseFirestore.instance
                        .collection(USER_DB)
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get();
                    final userData = userSnapshot.data() ?? {};
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PromotersScreen(
                          locationId: userData['state']?['id'] ?? '',
                          showAppBar: true,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.location_on_outlined, size: 25),
                  ),
                  dense: false,
                  minLeadingWidth: 10,
                  title: Text("Edit Home Location"),
                  onTap: () async {
                    final updated = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditHomeLocationPage(),
                      ),
                    );

                    if (updated && onStatePreferenceUpdated != null) {
                      onStatePreferenceUpdated!();
                    }
                  },
                ),
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.where_to_vote_outlined, size: 25),
                  ),
                  dense: false,
                  minLeadingWidth: 10,
                  title: Text("Select Election Location"),
                  onTap: () async {
                    final updated = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SelectElectionLocation(),
                      ),
                    );
                    if (updated && onStatePreferenceUpdated != null) {
                      onStatePreferenceUpdated!();
                    }
                  },
                ),

                // ListTile(
                //   leading: Padding(
                //     padding: const EdgeInsets.only(left: 2.0),
                //     child: Icon(Icons.directions_walk_outlined, size: 25),
                //   ),
                //   dense: false,
                //   minLeadingWidth: 10,
                //   title: Text("Get Free Auto Ride"),
                //   onTap: () async {
                //     if (isGuestLogin) {
                //       AppRoutes.navigateToLogin();
                //       return;
                //     }
                //
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (context) => GetFreeAutoRideScreen(),
                //       ),
                //     );
                //   },
                // ),

                // Divider(color: Colors.grey.withOpacity(0.2)),
                //       ListTile(
                //         leading: Padding(
                //           padding: const EdgeInsets.only(left: 2.0),
                //           child: Icon(Icons.launch, size: 22),
                //         ),
                //         dense: false,
                //         minLeadingWidth: 10,
                //         title: Text("Neuro Card"),
                //         onTap: () async {
                //           // URL to be launched
                //           const String url = 'https://pradhaan.in/neuro.html';
                //
                //           if (!await canLaunch(url)) {
                //             // Launch the URL
                //             await launch(url);
                //           } else {
                //             // Show a toast message if the URL can't be launched
                //             longToastMessage("couldn't launch the $url");
                //           }
                //         },
                //       ),
                //       ListTile(
                //         leading: Padding(
                //           padding: const EdgeInsets.only(left: 2.0),
                //           child: Icon(Icons.launch, size: 22),
                //         ),
                //         dense: false,
                //         minLeadingWidth: 10,
                //         title: Text("Pledge Card"),
                //         onTap: () async {
                //           // URL to be launched
                //           const String url =
                //               'https://pradhaan.in/pradhaanpledge.html';
                //
                //           // Check if the URL can be launched
                //           if (!await canLaunch(url)) {
                //             // Launch the URL
                //             await launch(url);
                //           } else {
                //             // Show a toast message if the URL can't be launched
                //             longToastMessage("couldn't launch the $url");
                //           }
                //         },
                //       ),
              ],
            ),
          ),
          ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Icon(Icons.account_circle_outlined, size: 22),
            ),
            dense: false,
            minLeadingWidth: 10,
            title: Text("My Profile"),
            onTap: () {
              Get.to(MyProfileScreen(
                userId: getPrefValue(Keys.USERID),
                back: true,
              ));
            },
          ),
          ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Icon(Icons.logout_outlined, size: 22),
            ),
            dense: false,
            minLeadingWidth: 10,
            title: Text("Sign Out"),
            onTap: () {
              FirebaseService().signout();
            },
          ),
        ],
      ),
    );
  }
}
