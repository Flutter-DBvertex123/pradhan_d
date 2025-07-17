import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/new_withdraw_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/location_model.dart';
import '../service/user_service.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_routes.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_toast.dart';
import 'level_selector_sheet.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RevenueState();
  }
}

class _RevenueState extends State<RevenueScreen> {
  List<LocationModel> scope = [];

  bool isDataReady = false;

  double? revenueOnOffer;
  double? amountPaidToPradhanas;
  double? totalAdsCreated;
  double? totalViewsGenerated;

  String? currentPradhanID;
  String? currentPradhanName;
  String? currentPradhanDesc;
  String? currentPradhanImage;
  double? currentPradhanRevenue;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // scope = [LocationModel(name: 'India', text: 'IND', id: '1- India'), LocationModel(name: 'Rajasthan', text: 'RJ', id: '31-Rajasthan')];
    getData(useMyScope: true);
  }

  Future<void> getData({bool useMyScope = false}) async {
    if (useMyScope) {
      var userModel = await UserService.getUserData(
          FirebaseAuth.instance.currentUser?.uid ?? '');

      scope = [userModel!.city, userModel.state, userModel.country]
          .reversed
          .toList() /*.sublist(max(0, userModel.level - 1)).reversed.toList()*/;
      // print("ishwar: ${[userModel!.postal, userModel.city, userModel.state, userModel.country].map((e) => e.name)} ${scope.map((e) => e.name)}, level: ${userModel.level}");
    }

    if (scope.isEmpty) {
      longToastMessage('Please select a scope to view revenue details');
    }
    setState(() {
      isDataReady = false;
    });
    print("ishwar: scope: ${scope.map((loc) => loc.name).toList()}, scope Suffix: ${scope.lastOrNull?.id}");
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('getRevenueDetailsForScope');
      final response = await callable.call({
        "scope": scope.map((loc) => loc.name).toList(),
        "scope_suffix": scope.lastOrNull?.id
      });

      var responseBody = response.data;
      print("ishwar: $responseBody");


      revenueOnOffer = responseBody['revenueOnOffer']?.toDouble();
      amountPaidToPradhanas =
          responseBody['totalRevenueTransferred']?.toDouble() ?? 0;
      totalAdsCreated = responseBody['totalAdsCreated']?.toDouble();
      totalViewsGenerated = responseBody['totalViewsGenerated']?.toDouble();

      var pradhanModel = responseBody['pradhanData'];
      print("ishwar pradhanModel !=null :${pradhanModel !=null} , is Map: ${pradhanModel is Map}");
      if (pradhanModel != null && pradhanModel is Map) {
        print("ishwar: if");
        currentPradhanID = pradhanModel['pradhanId'];
        currentPradhanName = pradhanModel['pradhanName'];
        currentPradhanDesc = pradhanModel['pradhanDesc'] == null ||
                pradhanModel['pradhanDesc'].isEmpty
            ? 'Pradhaan of ${scope.last.name}'
            : pradhanModel['pradhanDesc'];
        currentPradhanImage = pradhanModel['pradhanProfileImage'];
        currentPradhanRevenue = pradhanModel['pradhaanRevenue']?.toDouble();
      } else {
        print("ishwar: else");

        currentPradhanID = null;
        currentPradhanName = null;
        currentPradhanDesc = null;
        currentPradhanImage = null;
        currentPradhanRevenue = null;
      }
      print(
          "ishwar: response of revenue data for scope: (${scope.map((loc) => loc.name).toList()}): ${response.data}");
    } catch (e) {
      print("ishwar: while getting revenue data for scope: ($scope): $e");

      revenueOnOffer = null;
      amountPaidToPradhanas = null;
      totalAdsCreated = null;
      totalViewsGenerated = null;

      currentPradhanID = null;
      currentPradhanName = null;
      currentPradhanDesc = null;
      currentPradhanImage = null;
      currentPradhanRevenue = null;
    }
    setState(() {
      isDataReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Revenue',
        scaffoldKey: _scaffoldKey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Scope Selection Section
            if (!isDataReady)
              LinearProgressIndicator(color: AppColors.gradient1),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              elevation: 0,
              clipBehavior: Clip.hardEdge,
              color: AppColors.textBackColor,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8)
                  .copyWith(bottom: 0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Builder(builder: (context) {
                        var namedScope = scope.map((loc) => loc.name).toList();

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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: Icon(Icons.arrow_forward, size: 12),
                                  )),
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
                            scope.clear();
                            scope.add(LocationModel(
                                name: 'India', text: 'IND', id: '1-India'));
                            if (state != null) {
                              scope.add(state);
                              if (city != null) {
                                scope.add(city);
                                if (postal != null) {
                                  scope.add(postal);
                                }
                              }
                            }
                            getData();
                          },
                              defaultState: scope.length > 1 ? scope[1] : null,
                              defaultCity: scope.length > 2 ? scope[2] : null,
                              defaultPostal:
                                  scope.length > 3 ? scope[3] : null);
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

            // Total Revenue Summary Section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              elevation: 0,
              margin: EdgeInsets.all(8),
              color: AppColors.textBackColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue Summary', style: _sectionTitleStyle()),
                    SizedBox(height: 8),
                    _buildSummaryRow('Revenue On Offer',
                        "₹${revenueOnOffer?.toStringAsFixed(1)}" ?? '_'),
                    _buildSummaryRow('Amount Paid to Pradhaans',
                        "₹${amountPaidToPradhanas?.toStringAsFixed(1)}" ?? "_"),
                    _buildSummaryRow('Total Promotions Created',
                        totalAdsCreated?.toStringAsFixed(0) ?? '_'),
                    _buildSummaryRow('Total Views Generated',
                        totalViewsGenerated?.toStringAsFixed(0) ?? "_"),
                  ],
                ),
              ),
            ),

            // Current Pradhan Details Section
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              elevation: 0,
              margin: EdgeInsets.all(8),
              color: AppColors.textBackColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Pradhaan', style: _sectionTitleStyle()),
                    SizedBox(height: 8),
                    _buildPradhanDetails(
                        currentPradhanName ?? 'Unavailable',
                        currentPradhanDesc ?? '_',
                        currentPradhanImage ?? 'https://',
                        currentPradhanRevenue == null
                            ? '_'
                            : "${currentPradhanRevenue?.toStringAsFixed(1)} /-"),
                  ],
                ),
              ),
            ),

            // Previous Pradhans List
            // Card(
            //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            //   elevation: 0,
            //   margin: EdgeInsets.all(8),
            //   color: AppColors.textBackColor,
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text('Previous Pradhaans', style: _sectionTitleStyle()),
            //         ListView.separated(
            //             physics: NeverScrollableScrollPhysics(),
            //             shrinkWrap: true,
            //             itemBuilder: (context, index) => _buildPradhanDetails('Dummy Pradhaan 1', '28 August 2024', '', '₹20,000', false),
            //             separatorBuilder: (context, index) => Divider(),
            //             itemCount: 2
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            SizedBox(
              height: MediaQuery.sizeOf(context).width * 0.2,
            )
          ],
        ),
      ),
    );
  }

  // Helper method to build summary rows
  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Helper method to build Pradhan details
  Widget _buildPradhanDetails(String name, String title, String profileImage,
      [String amount = '', bool highlightAmount = true]) {
    late Widget amountWidget;
    if (amount.isNotEmpty) {
      amountWidget = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('$amount',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: highlightAmount ? Colors.white : Colors.green)),
      );
      if (highlightAmount) {
        amountWidget =
            Card(elevation: 0, color: AppColors.gradient1, child: amountWidget);
      }
    }
    return currentPradhanID == null ||
            currentPradhanID!.isEmpty ||
            currentPradhanID == 'none'
        ? ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 2),
            title: Text(isDataReady ? 'No Pradhaan Available.' : "Loading...",
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal)),
          )
        : GestureDetector(
            onTap: () {
              if (currentPradhanID == FirebaseAuth.instance.currentUser?.uid) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => NewWithdrawScreen()));
              } else {
                AppRoutes.navigateToMyProfile(
                    userId: currentPradhanID!,
                    back: true,
                    isOrganization: false);
              }
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
               // mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    color: AppColors.baseColor,
                    clipBehavior: Clip.hardEdge,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1000)),
                    child: CachedNetworkImage(
                      height: MediaQuery.sizeOf(context).width * 0.14,
                      width: MediaQuery.sizeOf(context).width * 0.14,
                      imageUrl: profileImage,
                      placeholderFadeInDuration: Duration.zero,
                      fit: BoxFit.contain,
                      placeholder: (context, error) => Shimmer.fromColors(
                          baseColor: Colors.grey.withOpacity(0.3),
                          highlightColor: Colors.white,
                          child: Container(color: Colors.black12)),
                      errorWidget: (context, url, error) => Container(
                          color: Colors.black12,
                          child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.bold)),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(title,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.bottomNavUnactiveColor)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: amount.isNotEmpty ? amountWidget : null,
            ),
          );
  }

  // Section title style
  TextStyle _sectionTitleStyle() {
    return TextStyle(
        fontSize: 17.5, fontWeight: FontWeight.bold, color: AppColors.black);
  }
}
