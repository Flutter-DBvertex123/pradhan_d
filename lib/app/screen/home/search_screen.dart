import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/controller/home/search_controller.dart';
import 'package:chunaw/app/screen/shimmer/post_shimmer.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/widgets/app_drawer.dart';
import 'package:chunaw/app/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController searchTextController = TextEditingController();
  SearchingController searchController = Get.put(SearchingController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Search',
        scaffoldKey: _scaffoldKey,
        elevation: 0,
      ),
      backgroundColor: AppColors.baseColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            AppSearchBar(
              controller: searchTextController,
              hintText: "Search User's",
              onChange: (text) {
                searchController.getUsers(text);
              },
            ),
            SizedBox(
              height: 7,
            ),
            Expanded(
                child: Obx(
              () => searchController.isLoading.value
                  ? ListView.builder(
                      itemCount: 10,
                      itemBuilder: (BuildContext context, int index) {
                        return userShimmer(add: false);
                      },
                    )
                  : searchTextController.text == "" &&
                          searchController.userList.isEmpty
                      ? Center(
                          child: Text("Start Typing...."),
                        )
                      : searchController.userList.isEmpty
                          ? Center(
                              child: Text("No User Available"),
                            )
                          : ListView.builder(
                              itemCount: searchController.userList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: InkWell(
                                    onTap: () {
                                      AppRoutes.navigateToMyProfile(
                                          userId: searchController
                                              .userList[index].id,
                                          isOrganization: searchController
                                              .userList[index].isOrganization,
                                          back: true);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          CircleAvatar(
                                              radius: 20.r,
                                              backgroundColor:
                                                  AppColors.gradient1,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                clipBehavior: Clip.hardEdge,
                                                child: CachedNetworkImage(
                                                  placeholder:
                                                      (context, error) {
                                                    return CircleAvatar(
                                                      radius: 20.r,
                                                      backgroundColor:
                                                          AppColors.gradient1,
                                                      child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                        color: AppColors
                                                            .highlightColor,
                                                      )),
                                                    );
                                                  },
                                                  errorWidget: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                      AppAssets.brokenImage,
                                                      fit: BoxFit.fitHeight,
                                                      width: 160.0,
                                                      height: 160.0,
                                                    );
                                                  },
                                                  imageUrl: searchController
                                                      .userList[index].image,
                                                  // .replaceAll('\', '//'),
                                                  fit: BoxFit.cover,
                                                  // width: 160.0,
                                                  height: 160.0,
                                                ),
                                              )),
                                          SizedBox(width: 14),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                searchController
                                                    .userList[index].name,
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    color: Color.fromRGBO(
                                                        0, 0, 0, 1),
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 12,
                                                    letterSpacing:
                                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    height: 1),
                                              ),
                                              SizedBox(
                                                height: 7,
                                              ),
                                              Text(
                                                "${searchController.userList[index].city.name}, ${searchController.userList[index].state.name} ${searchController.userList[index].country.name}",
                                                textAlign: TextAlign.left,
                                                style: TextStyle(
                                                    color: Color.fromRGBO(
                                                        51, 51, 51, 1),
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 10,
                                                    letterSpacing:
                                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    height: 1),
                                              )
                                            ],
                                          ),
                                          Expanded(
                                            child: SizedBox(
                                              width: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ))
          ],
        ),
      ),
    );
  }
}
