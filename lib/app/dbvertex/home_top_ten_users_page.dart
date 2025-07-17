import 'dart:convert';

import 'package:chunaw/app/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:screenshot/screenshot.dart';

import '../models/location_model.dart';
import '../screen/Location_features/user_card.dart';
import '../screen/shimmer/post_shimmer.dart';
import '../service/vote_service.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_pref.dart';
import '../widgets/app_drawer.dart';
import 'level_selector_sheet.dart';

class HomeTopTenUsersPage extends StatefulWidget {

  const HomeTopTenUsersPage({super.key});

  @override
  State<HomeTopTenUsersPage> createState() => _HomeTopTenUsersPageState();
}

class _HomeTopTenUsersPageState extends State<HomeTopTenUsersPage> {
  List<LocationModel> scopes = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<UserModel>? topUsers;

  @override
  void initState() {
    init();
    super.initState();
  }


  Future<void> init() async {
    final country = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.COUNTRY)));
    final state = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.STATE)));
    final city = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.CITY)));

    scopes = [country, state, city];
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      getData(city.text, 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(),
        appBar: AppBarCustom(leadingBack: true, title: 'Top 10 Leaders',
          scaffoldKey: _scaffoldKey,
          elevation: 0,
        ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9)),
            elevation: 0,
            clipBehavior: Clip.hardEdge,
            color: AppColors.white,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8)
                .copyWith(bottom: 0),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Builder(builder: (context) {
                      var namedScope = scopes.map((loc) => loc.name).toList();
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
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            separatorBuilder: (context, index) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(Icons.arrow_forward, size: 12),
                                )
                            ),
                            itemCount: namedScope.length),
                      );
                    }),
                  ),
                  // Icon(Icons.keyboard_arrow_down)
                  Card(
                    color: AppColors.primaryColor,
                    clipBehavior: Clip.hardEdge,
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () async {
                        LevelSelectorSheet.show(context,
                                (state, city, postal) {
                              scopes.clear();
                              scopes.add(LocationModel(name: 'India', text: 'IND', id: '1-India'));
                              if (state != null) {
                                scopes.add(state);
                                if (city != null) {
                                  scopes.add(city);
                                  if (postal != null) {
                                    scopes.add(postal);
                                  }
                                }
                              }
                              getData(scopes.last.text, 5 - scopes.length);
                            },
                            defaultState: scopes.length > 1 ? scopes[1] : null,
                            defaultCity: scopes.length > 2 ? scopes[2] : null,
                            defaultPostal:
                            scopes.length > 3 ? scopes[3] : null);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8)
                            .copyWith(right: 10),
                        child: Row(
                          children: [
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 20),
                            Text(
                              'Change',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(
            height: 16,
          ),
          Expanded(child: _createUserList())
        ],
      )
    );
  }

  _createUserList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 50),
      itemBuilder: (context, index) {
        return topUsers == null ? _createShimmerItem() : Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: UserCard(
            userModel: topUsers![index],
            upvote: false,
            onVoteUpdateFun: (){},
            overrideOnPressed: (isLiked) {
              return Future.value(false);
            },
          ),
        );
      },
      itemCount: topUsers?.length ?? 10,
    );
  }

  _createShimmerItem() {
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
        ));
  }

  Future<void> getData(String text, int level) async {
    print("ishwar:loc getting data for $text - $level");
    setState(() {
      topUsers = null;
    });
    topUsers = await VoteService.getHighestUpvotedUsers(text, level);
    print("ishwar:loc getting data for $text - $topUsers");
    setState(() {});
  }
}
