import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/controller/home/create_post_controller.dart';
import 'package:chunaw/app/controller/home/home_controller.dart';
import 'package:chunaw/app/dbvertex/area_pradhan_page.dart';
import 'package:chunaw/app/dbvertex/home_top_ten_users_page.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/screen/home/home_screen.dart';
import 'package:chunaw/app/screen/home/my_profile_screen.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/location_service.dart';
import 'package:chunaw/app/service/sachiv_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_drawer.dart';
import 'package:chunaw/app/widgets/app_drop_down.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../dbvertex/revenue_screen.dart';
import '../../dbvertex/utils/donations_manager.dart';
import '../../widgets/app_toast.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with SingleTickerProviderStateMixin {
  final RxInt index = 0.obs;

  late final TabController _tabController;

  iconWidget(String icon) {
    return Column(
      children: [
        Container(
          height: 3,
          transform: Matrix4.translationValues(0, -6, 0),
        ),
        SizedBox(
          height: 6,
        ),
        SvgPicture.asset(
          icon,
        ),
        SizedBox(
          height: 5,
        ),
      ],
    );
  }
  String getLevelName(dynamic pradhan) {
    if (pradhan == null) return 'N/A';
    final level = pradhan['level'];
    print('dss :- level $level');
    switch (level) {
      case 1:
        return 'Ward-Pradhaan';
      case 2:
        return 'City-Pradhaan';
      case 3:
        return 'State-Pradhaan';
      case 4:
        return 'Country-Pradhaan';
      default:
        return 'N/A';
    }
  }

  activeIconWidget(Widget icon) {
    return Column(
      children: [
        Container(
          transform: Matrix4.translationValues(0, -6, 0),
          child: SvgPicture.string(
            '<svg viewBox="54.0 748.0 24.0 3.0" ><defs><linearGradient id="gradient" x1="0.0" y1="0.5" x2="1.0" y2="0.5"><stop offset="0.0" stop-color="#f4881c" /><stop offset="1.0" stop-color="#ff1570" /></linearGradient></defs><path transform="translate(54.0, 748.0)" d="M 1.5 0 L 22.5 0 C 23.32842636108398 0 24 0.6715728044509888 24 1.5 C 24 2.328427314758301 23.32842636108398 3 22.5 3 L 20.13351249694824 3 L 1.5 3 C 0.6715728044509888 3 0 2.328427314758301 0 1.5 C 0 0.6715728044509888 0.6715728044509888 0 1.5 0 Z" fill="url(#gradient)" stroke="none" stroke-width="1" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
            allowDrawingOutsideViewBox: true,
            fit: BoxFit.cover,
            color: AppColors.primaryColor,
            width: 26,
            height: 3,
          ),
        ),
        SizedBox(
          height: 5,
        ),
        icon,
        SizedBox(
          height: 5,
        ),
      ],
    );
  }

  final HomeController homeController = Get.put(HomeController());

  // state whether they selected the state, city or not
  late LocationModel selectedState;
  late LocationModel selectedCity;
  late LocationModel selectedPostal;

  // futures
  late Future getStates;
  late Future getCities;
  late Future getPostals;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    selectedState = homeController.selectedState.value;
    selectedCity = homeController.selectedCity.value;
    selectedPostal = homeController.selectedPostal.value;
  }

  @override
  Widget build(BuildContext context) {
    final isGuestLogin = Pref.getBool(Keys.IS_GUEST_LOGIN, false);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        heroTag: 'filter button',
        onPressed: () {
          // updating the values of selected data
          setState(() {
            selectedState = homeController.selectedState.value;
            selectedCity = homeController.selectedCity.value;
            selectedPostal = homeController.selectedPostal.value;
          });

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              // now we show the dropdown for the states
              return StatefulBuilder(
                builder: (context, setState) {
                  getStates = LocationService.getState("1-India");
                  getCities =
                      LocationService.getCity("1-India", selectedState.id);
                  getPostals = LocationService.getPostal(
                      "1-India", selectedState.id, selectedCity.id);

                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _getFilterDropDownWithCancellationFutureBuilder(
                          setState: setState,
                          activeName: selectedState.name,
                          hintText: 'Select State',
                          future: getStates,
                          onChanged: (unit) {
                            setState(() {
                              selectedState = unit;
                              clearCity();
                              clearPostal();
                            });
                          },
                          onClear: () {
                            setState(() {
                              clearState();
                              clearCity();
                              clearPostal();
                            });
                          },
                          showClearButtonCondition: selectedState.id !=
                              locationModelFromJson(
                                getPrefValue(Keys.STATE),
                              ).id,
                          forWhat: 'State',
                        ),
                        _getFilterDropDownWithCancellationFutureBuilder(
                          setState: setState,
                          future: getCities,
                          activeName: selectedCity.name,
                          hintText: 'Select City',
                          onChanged: (unit) {
                            setState(() {
                              selectedCity = unit;
                              clearPostal();
                            });
                          },
                          onClear: () {
                            setState(() {
                              clearCity();
                              clearPostal();
                            });
                          },
                          showClearButtonCondition: selectedCity.id !=
                              locationModelFromJson(
                                getPrefValue(Keys.CITY),
                              ).id,
                          forWhat: 'City',
                        ),
                        _getFilterDropDownWithCancellationFutureBuilder(
                          setState: setState,
                          future: getPostals,
                          activeName: selectedPostal.name,
                          hintText: 'Select Postal',
                          onChanged: (unit) {
                            setState(() {
                              selectedPostal = unit;
                            });
                          },
                          onClear: () {
                            setState(() {
                              clearPostal();
                            });
                          },
                          showClearButtonCondition: selectedPostal.id !=
                              locationModelFromJson(
                                getPrefValue(Keys.POSTAL),
                              ).id,
                          forWhat: 'Postal',
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              padding: MaterialStateProperty.all(
                                const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                            onPressed: () {
                              // setting the filters
                              homeController.selectedState.value =
                                  selectedState;
                              homeController.selectedCity.value = selectedCity;
                              homeController.selectedPostal.value =
                                  selectedPostal;

                              // closing the sheet
                              Navigator.of(context).pop();

                              // setting the required data and navigating to the relevant page
                              if (selectedPostal.id !=
                                  locationModelFromJson(
                                    getPrefValue(Keys.POSTAL),
                                  ).id) {
                                homeController.filterby.value = 1;
                                SachivService.addImpDetailInSachiv(
                                    docId: getLatestWelcomeScreenLocId(1),
                                    locationName: getLatestWelcomeScreenText(1),
                                    level: 1);
                                _tabController.animateTo(1);
                              } else if (selectedCity.id !=
                                  locationModelFromJson(getPrefValue(Keys.CITY))
                                      .id) {
                                homeController.filterby.value = 2;
                                SachivService.addImpDetailInSachiv(
                                    docId: getLatestWelcomeScreenLocId(2),
                                    locationName: getLatestWelcomeScreenText(2),
                                    level: 2);
                                _tabController.animateTo(2);
                              } else if (selectedState.id !=
                                  locationModelFromJson(
                                          getPrefValue(Keys.STATE))
                                      .id) {
                                homeController.filterby.value = 3;
                                SachivService.addImpDetailInSachiv(
                                    docId: getLatestWelcomeScreenLocId(3),
                                    locationName: getLatestWelcomeScreenText(3),
                                    level: 3);
                                _tabController.animateTo(3);
                              }

                              // applying filters, getting posts, and getting the sachiv
                              homeController.applyFilter();
                              homeController
                                  .getPosts(homeController.filterby.value);
                              homeController
                                  .getSachiv(homeController.filterby.value);
                            },
                            child: Text('Apply Filter'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ).whenComplete(() => setState(() {}));
        },
        clipBehavior: Clip.hardEdge,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: selectedPostal.id !=
                    locationModelFromJson(
                      getPrefValue(Keys.POSTAL),
                    ).id ||
                selectedCity.id !=
                    locationModelFromJson(
                      getPrefValue(Keys.CITY),
                    ).id ||
                selectedState.id !=
                    locationModelFromJson(
                      getPrefValue(Keys.STATE),
                    ).id
            ? Icon(
                Icons.location_on,
                size: 25,
              )
            : Icon(
                Icons.location_on_outlined,
                size: 25,
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: index.value,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 9,
            color: const Color(0xffff1570),
            fontWeight: FontWeight.w500,
          ),
          elevation: 7,
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 9,
            color: const Color(0xff959595),
          ),
          onTap: (int ind) {
            index.value = ind;
          },
          items: [
            BottomNavigationBarItem(
              label: "",
              backgroundColor: Colors.white,
              icon: iconWidget(AppAssets.homeIcon),
              activeIcon: activeIconWidget(
                SvgPicture.asset(
                  AppAssets.homeIcon,
                  color: AppColors.gradient2,
                ),
              ),
            ),
            BottomNavigationBarItem(
              label: "",
              backgroundColor: Colors.white,
              icon: Image.asset(
                'assets/leadership.png',
                height: 26.w,
                width: 26.w,
                color: Color(0xFF6F767E),
              ),
              activeIcon: activeIconWidget(
                  Image.asset(
                    'assets/leadership.png',
                    height: 26.w,
                    width: 26.w,
                    color: AppColors.primaryColor,
                  )
              ),
            ),
            // BottomNavigationBarItem(
            //   label: "",
            //   backgroundColor: Colors.white,
            //   icon: SizedBox(),
            //   activeIcon: activeIconWidget(
            //       SizedBox()
            //   ),
            // ),
            BottomNavigationBarItem(
              label: "",
              backgroundColor: Colors.white,
              // icon: iconWidget(AppAssets.profileIcon),
              icon: Image.asset(
                'assets/top_ten.png',
                height: 25.w,
                width: 25.w,
                color: Color(0xFF6F767E),
              ),
              // activeIcon: activeIconWidget(
              //   SvgPicture.asset(
              //     AppAssets.profileIcon,
              //     color: AppColors.gradient2,
              //   ),
              // ),
              activeIcon: activeIconWidget(Image.asset(
                'assets/top_ten.png',
                height: 25.w,
                width: 25.w,
                color: AppColors.primaryColor,
              ))
            ),
            BottomNavigationBarItem(
              label: "",
              backgroundColor: Colors.white,
              icon: Icon(
                Icons.monetization_on_outlined,
                size: 22,
              ),
              activeIcon: activeIconWidget(
                Icon(
                  Icons.monetization_on_outlined,
                  color: AppColors.gradient2,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop)  {
          _showExitDialog(context);
        },
        child: Stack(
          children: [
            Obx(() => AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: [
                    HomeScreen(
                      _tabController,
                    ),
                    // EditHomeLocationPage(),
                    AreaPradhanPage(showAppbar: true),
                    isGuestLogin
                        ? _buildSignInPlaceholderPage(title: 'Top 10 Leaders')
                        : HomeTopTenUsersPage(
                          ),
                    isGuestLogin
                        ? _buildSignInPlaceholderPage(title: 'Revenue')
                        : RevenueScreen(),
                  ][index.value],
                )),
            Positioned(
              bottom: 15,
              right: 15,
              child: FloatingActionButton(
                heroTag: 'Add post',
                onPressed: () async {
                  // if is guest login, ask to login
                  if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
                    AppRoutes.navigateToLogin(removeGuestLogin: true);
                    return;
                  }
                  print('dss : - ${Timestamp.now()}');
                  //final int? navigateTo = await AppRoutes.navigateToAddPost();
                  final int? navigateTo =  await AppRoutes.navigateToAddPost();
                  //print('navigate to: $navigateTo');
                  // if navigateTo is null, do nothing
                  if (navigateTo == null) {
                    return;
                  }

                  // else navigate to the tab where the post was posted
                  setState(() {
                    _tabController.animateTo(navigateTo);
                  });
                  homeController.filterby.value = navigateTo;
                  SachivService.addImpDetailInSachiv(
                      docId: getLatestWelcomeScreenLocId(navigateTo),
                      locationName: getLatestWelcomeScreenText(navigateTo),
                      level: navigateTo);
                  homeController.getPosts(navigateTo);
                  homeController.getSachiv(navigateTo);
                },
                clipBehavior: Clip.hardEdge,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                child: Icon(Icons.add_box_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Scaffold _buildSignInPlaceholderPage({required String title}) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: AppDrawer(),
      appBar: AppBarCustom(
        scaffoldKey: scaffoldKey,
        title: title,
      ),
      body: Column(
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
      ),
    );
  }

  Future<dynamic> _showExitDialog(BuildContext context) {
    bool? wasPradhaanBefore;
    bool? isPradhaanAtHisLevel;
    double revenue = 0.0;
    bool isLoading = true;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Align(
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    width: 1,
                    color: Colors.black,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                child: Text(
                  'Pradhaan Card'.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            content: Pref.getBool(Keys.IS_GUEST_LOGIN, false)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          AppRoutes.navigateToLogin();
                        },
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: 'Please'),
                              TextSpan(
                                text: ' sign in',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              TextSpan(text: ' to get your Pradhaan card.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildExitButton(),
                      ),
                    ],
                  )
                : StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection(USER_DB)
                        .where('id', isEqualTo: Pref.getString(Keys.USERID))
                        .snapshots(),
                    builder: (context, snapshot) {
                      // grabbing the data
                      final data = snapshot.data?.docs.firstOrNull?.data();

                      // if there is no data, return
                      if (data == null) {
                        return Text('Could not load user data');
                      }

                      // otherwise, extracting the data we need
                      final String userId = data['id'];
                      final String profileImage = data['image'] ?? '';
                      final String name = data['name'];
                      final int userLevel = data['level'];
                      final Map postal = data['postal'];
                      final Map city = data['city'];
                      final Map country = data['country'];
                      final Map state = data['state'];
                      final Map userLevelLocation =
                          _getLocationAccordingToLevel(
                        level: userLevel,
                        city: city,
                        postal: postal,
                        state: state,
                        country: country,
                      );
                      final int upvotesReceived = data['upvote_count'] ?? 0;
                      print('dss : - $userId');
                      List<Map> scopeData = [postal, city, state, country]
                          .sublist(max(0, userLevel - 2))
                          .reversed
                          .toList();
                      String scopeSuffix =
                          scopeData[scopeData.length - 1]['id'] ?? '';
                      List<String> scope =
                          scopeData.map<String>((val) => val['name']).toList();


                      print("ishwar: $scope suffix: $scopeSuffix");

                      if (wasPradhaanBefore == null && isLoading) {
                        run() async {
                          final HttpsCallable callable = FirebaseFunctions
                              .instance
                              .httpsCallable('getRevenueDetailsForPradhaan');
                          try {
                            final revenueResponse =
                                await callable.call({"pradhaan_id": userId});
                            var revenueBody = revenueResponse.data;
                            print("ishwar: revenueResponse: $revenueBody");
                            final rev = revenueBody['pradhaanRevenue'] ?? 0.0;
                            revenue = rev is int ? rev.toDouble() : rev;
                            wasPradhaanBefore = revenue > 0;
                          } catch (error) {
                            print("ishwar: revenueResponseError: $error");
                            revenue = 0.0;
                          }

                          try {
                            isPradhaanAtHisLevel =
                                await _checkIsPradhaanAtCurrentLevel(
                                    userId: userId, docId: scopeSuffix);
                            wasPradhaanBefore = (wasPradhaanBefore ?? false) ||
                                (isPradhaanAtHisLevel ?? false);
                            isLoading = false;
                          } catch (_) {
                            wasPradhaanBefore = false;
                            isPradhaanAtHisLevel = false;
                            isLoading = false;
                            rethrow;
                          }
                        }

                        run().then((_) {
                          setState(() {});
                        }, onError: (error) {
                          setState(() {});
                        });
                      }

                      return FutureBuilder(
                          future: DonationsManager()
                              .getDonationsForScope(returnDonors: true),
                          builder: (context, snapshot) {
                            return FutureBuilder(
                              future: FirebaseFirestore.instance.collection(PRADHAN_DB).where('pradhan_id', isEqualTo: userId).get(),
                              builder: (context, asyncSnapshot) {

                                if(snapshot.hasData || (!snapshot.hasData || asyncSnapshot.data!.docs.isEmpty) ) {
                                  var pradhan = (!asyncSnapshot.hasData || asyncSnapshot.data!.docs.isEmpty)  ? null : asyncSnapshot.data!.docs.first;
                                  return Stack(
                                    children: [
                                      Image.asset('assets/text_india_map.png'),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildProfileImage(profileImage),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            name.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Image.asset(
                                            'assets/pradhaan_card_divider.png',
                                            width: min(
                                                120,
                                                MediaQuery
                                                    .of(context)
                                                    .size
                                                    .width /
                                                    2),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          _buildExitDialogDataRow(
                                            'User Level',
                                            valueWidget: Text(
                                              userLevelLocation['name'] +
                                                  ((isPradhaanAtHisLevel ??
                                                      false)
                                                      ? ' - Pradhaan'
                                                      : ''),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.primaryColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                         /* _buildExitDialogDataRow(
                                            'Designation',
                                            valueWidget: Text(
                                              getLevelName(pradhan),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.primaryColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),*/
                                          _buildExitDialogDataRow('Votes:',
                                              value: upvotesReceived
                                                  .toString()),
                                          _buildExitDialogDataRow('Revenue Raised',
                                              value:
                                              "₹${revenue.toStringAsFixed(1)}"),
                                          // _buildExitDialogDataRow('Free Auto Fund',
                                          //     value: "₹${snapshot.data?.totalDonatedAmount.toStringAsFixed(1)??0}"),
                                          // const SizedBox(
                                          //   height: 20,
                                          // ),
                                          // _buildExitDialogDataRow(
                                          //     'Contributions to\nPradhaan Free Taxi',
                                          //     titleColor: AppColors.primaryColor,
                                          //     value: "₹${snapshot.data?.totalDonatedAmount.toStringAsFixed(1) ?? 0}"
                                          // ),
                                          const SizedBox(
                                            height: 50,
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .end,
                                            children: [
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (isLoading = false) {
                                                      return;
                                                    }

                                                    // if not loading, but value is still null, there was probably an error
                                                    if (isPradhaanAtHisLevel ==
                                                        null) {
                                                      Navigator
                                                          .of(context)
                                                          .pop();
                                                      showSnackBar(context,
                                                          message:
                                                          'Something went wrong!');
                                                      return;
                                                    }

                                                    // if everything went well, push the download
                                                    AppRoutes
                                                        .navigateToDownloadPradhaanCard(
                                                      designation: getLevelName(pradhan),
                                                        fundsRaised:
                                                        revenue.toString(),
                                                        imageUrl: profileImage,
                                                        name: name,
                                                        userLevelLocation:
                                                        userLevelLocation[
                                                        'name'],
                                                        votesReceived:
                                                        upvotesReceived
                                                            .toString(),
                                                        isPradhaanAtHisLevel:
                                                        isPradhaanAtHisLevel!,
                                                        autoFund:
                                                        "₹${snapshot.data
                                                            ?.totalDonatedAmount
                                                            .toStringAsFixed(
                                                            1) ?? 0}");
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                    MaterialStateProperty.all(
                                                      Colors.transparent,
                                                    ),
                                                    padding: WidgetStatePropertyAll(
                                                        EdgeInsets.zero),
                                                    shape: MaterialStateProperty
                                                        .all(
                                                      RoundedRectangleBorder(
                                                        side: BorderSide(
                                                          width: 1.5,
                                                          color: (wasPradhaanBefore ??
                                                              false)
                                                              ? AppColors
                                                              .primaryColor
                                                              .withOpacity(0.6)
                                                              : AppColors
                                                              .primaryColor,
                                                        ),
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                            7),
                                                      ),
                                                    ),
                                                    elevation:
                                                    MaterialStateProperty.all(
                                                        0),
                                                  ),
                                                  child: isLoading
                                                      ? SizedBox(
                                                    height: 15,
                                                    width: 15,
                                                    child:
                                                    CircularProgressIndicator(
                                                      color: AppColors
                                                          .primaryColor,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                      : Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 2),
                                                    child: Text(
                                                      'Download',
                                                      overflow:
                                                      TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: _buildExitButton(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                else{
                                  return SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: CircularProgressIndicator(),
                                  );
                                }

                              }
                            );
                          });
                    },
                  ),
          );
        });
      },
    );
  }

  ElevatedButton _buildExitButton() {
    return ElevatedButton(
      onPressed: () {
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          AppColors.primaryColor,
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            side: BorderSide(
              width: 1.5,
              color: AppColors.primaryColor,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        elevation: MaterialStateProperty.all(0),
      ),
      child: Text(
        'Quit',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }

  Future<bool> _checkIsPradhaanAtCurrentLevel({
    required String userId,
    required String docId,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection(PRADHAN_DB)
        .doc(docId)
        .get();

    return doc.data()?['pradhan_id'] == userId;
  }

  Row _buildExitDialogDataRow(
    String title, {
    String? value,
    Color? titleColor,
    Widget? valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        if (value != null)
          Text(
            value,
            maxLines: 1,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
              fontSize: 16,
            ),
          ),
        if (valueWidget != null) valueWidget
      ],
    );
  }

  Widget _buildProfileImage(String profilePhoto) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: Colors.black,
        ),
        borderRadius: BorderRadius.circular(45),
      ),
      child: CircleAvatar(
        radius: 45.r,
        backgroundColor: AppColors.gradient1,
        child: ClipOval(
          clipBehavior: Clip.hardEdge,
          child: CachedNetworkImage(
            placeholder: (context, error) {
              // printError();
              return CircleAvatar(
                radius: 35.r,
                backgroundColor: AppColors.gradient1,
                child: Center(
                    child: CircularProgressIndicator(
                  color: AppColors.highlightColor,
                )),
              );
            },
            errorWidget: (context, error, stackTrace) {
              // printError();
              return Image.asset(
                AppAssets.brokenImage,
                fit: BoxFit.fitHeight,
                // width: 160.0,
                height: 122.0,
              );
            },
            imageUrl: profilePhoto,
            // .replaceAll('\', '//'),
            fit: BoxFit.cover,
            // width: 160.0,
            height: 160.0,
          ),
        ),
      ),
    );
  }

  FutureBuilder<dynamic> _getFilterDropDownWithCancellationFutureBuilder({
    required StateSetter setState,
    required Future future,
    required String activeName,
    required String hintText,
    required Function onChanged,
    required Function onClear,
    required bool showClearButtonCondition,
    required String forWhat,
  }) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        // if loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 55,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.baseColor,
            ),
          )
              .animate(onComplete: (controller) => controller.repeat())
              .shimmer(delay: 500.ms, duration: 800.ms);
        }

        // grabbing the states
        List<LocationModel> data = snapshot.data;

        // sorting the data
        data.sort((a, b) => a.name.compareTo(b.name));

        return Row(
          children: [
            Expanded(
              child: AppDropDown(
                hint: hintText,
                hintWidget: Text(
                  activeName,
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      color: selectedState.id == ""
                          ? Colors.black.withOpacity(0.51)
                          : AppColors.black,
                      fontSize: 14),
                ),
                items: data
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.name),
                      ),
                    )
                    .toList(),
                onChanged: (unit) {
                  // calling the onChanged only if the value actually changed meaning that the user didn't select the same value again
                  if ((forWhat == 'State' && unit.name != selectedState.name) ||
                      (forWhat == 'City' && unit.name != selectedCity.name) ||
                      (forWhat == 'Postal' &&
                          unit.name != selectedPostal.name)) {
                    onChanged(unit);
                  }
                },
              ),
            ),
            if (showClearButtonCondition)
              const SizedBox(
                width: 5,
              ),
            if (showClearButtonCondition)
              GestureDetector(
                onTap: () {
                  onClear();
                },
                child: Container(
                  height: 25,
                  width: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1.4,
                      color: Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void clearState() {
    selectedState = locationModelFromJson(getPrefValue(Keys.STATE));
  }

  void clearCity() {
    selectedCity = locationModelFromJson(getPrefValue(Keys.CITY));
  }

  void clearPostal() {
    selectedPostal = locationModelFromJson(getPrefValue(Keys.POSTAL));
  }

  String getLatestWelcomeScreenLocId(int index) {
    switch (index) {
      case 0:
        return locationModelFromJson(getPrefValue(Keys.CITY)).id;
      case 1:
        return homeController.selectedPostal.value.id;

      case 2:
        return homeController.selectedCity.value.id;
      case 3:
        return homeController.selectedState.value.id;
      case 4:
        return "1-India";

      default:
        return homeController.selectedState.value.id;
    }
  }

  String getLatestWelcomeScreenText(int index) {
    switch (index) {
      case 0:
        return locationModelFromJson(getPrefValue(Keys.CITY)).text;
      case 1:
        return homeController.selectedPostal.value.text;

      case 2:
        return homeController.selectedCity.value.text;
      case 3:
        return homeController.selectedState.value.text;
      case 4:
        return "IND";
      default:
        return homeController.selectedState.value.text;
    }
  }

  Map _getLocationAccordingToLevel({
    required int level,
    required Map city,
    required Map country,
    required Map postal,
    required Map state,
  }) {
    switch (level) {
      case 1:
        return postal;
      case 2:
        return city;
      case 3:
        return state;
      case 4:
        return country;
      default:
        return {};
    }
  }

  /*Future<int> getRecentPostCount() async {
    int todayPosts = 0;
    final userId = getPrefValue(Keys.USERID);

    final querySnapshot = await FirebaseFirestore.instance
        .collection(POST_DB)
        .where('user_id', isEqualTo: userId)
        .get();

    final now = DateTime.now();

    for (var doc in querySnapshot.docs) {
      final postTimestamp = doc['createdAt'] as Timestamp;
      final postDate = postTimestamp.toDate();
      print('dss post : - $postDate');

      if (postDate.year == now.year &&
          postDate.month == now.month &&
          postDate.day == now.day) {
        todayPosts++;
      }
    }
    print('dss : - $todayPosts');
    return todayPosts;
  }

  Future<int?> checkPostLimit() async {
    final level = getPrefValue(Keys.LEVEL);
    int todayPosts = await getRecentPostCount();

    switch (level) {
      case "1":
        return await AppRoutes.navigateToAddPost();

      case "2":
        if (todayPosts < 5) {
          return await AppRoutes.navigateToAddPost();
        } else {
          longToastMessage('Your daily post limit is exceeded');
          return null;
        }

      case "3":
        if (todayPosts < 3) {
          return await AppRoutes.navigateToAddPost();
        } else {
          longToastMessage('Your daily post limit is exceeded');
          return null;
        }

      case "4":
        if (todayPosts < 1) {
          return await AppRoutes.navigateToAddPost();
        } else {
          longToastMessage('Your daily post limit is exceeded');
          return null;
        }

      default:
        print('Error occurred while checking daily post limit');
        return null;
    }
  }*/
}
