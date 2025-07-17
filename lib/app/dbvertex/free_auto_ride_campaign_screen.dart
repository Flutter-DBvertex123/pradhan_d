import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
import 'package:chunaw/app/dbvertex/models/donation_details_model.dart';
import 'package:chunaw/app/dbvertex/transfer_to_campaign_fund_screen.dart';
import 'package:chunaw/app/dbvertex/utils/donations_manager.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/location_model.dart';
import '../service/collection_name.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_pref.dart';
import '../utils/app_routes.dart';
import '../widgets/app_button.dart';
import 'level_selector_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class FreeAutoRideCampaignScreen extends StatefulWidget {
  const FreeAutoRideCampaignScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _FreeAutoRideCampaignScreenState();
  }
}

class _FreeAutoRideCampaignScreenState
    extends State<FreeAutoRideCampaignScreen> {
  List<LocationModel> scope = [];
  List<Map> autos = [];
  bool isDataReady = false;
  DateTime selectedTime = DateTime.now();

  DonationDetailsModel? donationDetails;

  Future<bool> getAllData() async {
    setState(() {
      isDataReady = false;
    });

    try {
      print("ishwar: here");
      if (scope.isEmpty) {
        print("ishwar: empty");

        // if is guest login, load the location data from shared prefs instead
        if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
          scope = [
            locationModelFromJson(getPrefValue(Keys.COUNTRY)),
            locationModelFromJson(getPrefValue(Keys.STATE)),
            locationModelFromJson(getPrefValue(Keys.CITY)),
            locationModelFromJson(getPrefValue(Keys.POSTAL))
          ];
        } else {
          var snapshot = await FirebaseFirestore.instance
              .collection(USER_DB)
              .where('id', isEqualTo: Pref.getString(Keys.USERID))
              .get();

          final data = snapshot.docs.firstOrNull?.data();

          if (data != null) {
            final Map postal = data['postal'] ?? {};
            final Map city = data['city'] ?? {};
            final Map country = data['country'] ?? {};
            final Map state = data['state'] ?? {};

            scope = [
              LocationModel.fromJson(Map.from(country)),
              LocationModel.fromJson(Map.from(state)),
              LocationModel.fromJson(Map.from(city)),
              LocationModel.fromJson(Map.from(postal))
            ];
          }
        }
        print("ishwar: scope ${scope.map((d) => d.id)}");
      } else {
        print("ishwar: not empty $scope");
      }
      print("ishwar: ${scope.map((loc) => loc.name)} ${scope.lastOrNull?.id}");
      donationDetails = await DonationsManager().getDonationsForScope(
          scopeSuffix: scope.lastOrNull?.id,
          returnDonors: true,
          groupContributors: true);
      var snapshot = await FirebaseFirestore.instance
          .collection(AUTO_LINKS)
          .where('location', isEqualTo: scope.lastOrNull?.id)
          .get();

      final autosdata = snapshot.docs;
      autos.clear();
      print("ishwar: autos for ${scope.lastOrNull?.id} $autosdata");
      for (var map in autosdata) {
        final data = map.data();
        autos.add(data);
      }
      setState(() {
        isDataReady = true;
      });

      return true;
    } catch (error) {
      print("ishwar: $error");
      return false;
    }
  }

  @override
  void initState() {
    // scope = [LocationModel(name: 'India', text: 'IND', id: '1- India'), LocationModel(name: 'Rajasthan', text: 'RJ', id: '31-Rajasthan')];
    getAllData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
        child: Scaffold(
          // appBar: AppBarCustom(
          //   leadingBack: true,
          //   title: 'Free Auto Ride Campaign',
          //   elevation: 0
          // ),
          appBar: CalendarAppBar(
            selectedDate: selectedTime,
            onDateChanged: (value) {
              setState(() {
                selectedTime = value;
              });
            },
            firstDate: DateTime.now().subtract(Duration(days: 10)),
            lastDate: DateTime.now(),
            accent: AppColors.gradient1,
          ),
          backgroundColor: AppColors.textBackColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(

                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          elevation: 4,
                          clipBehavior: Clip.hardEdge,
                          color: AppColors.white,
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8)
                              .copyWith(bottom: 0),
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
                                getAllData();
                              },
                                  hidePostal: false,
                                  allField: false,
                                  defaultState:
                                      scope.length > 1 ? scope[1] : null,
                                  defaultCity: scope.length > 2 ? scope[2] : null,
                                  defaultPostal:
                                      scope.length > 3 ? scope[3] : null);
                            },
                            child: Container(
                              color: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Builder(builder: (context) {
                                      var namedScope =
                                          scope.map((loc) => loc.name).toList();

                                      return SizedBox(
                                        height: MediaQuery.sizeOf(context).width *
                                            0.08,
                                        child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            shrinkWrap: true,
                                            itemBuilder: (context, index) =>
                                                Center(
                                                  child: Text(
                                                    namedScope[index],
                                                    style: TextStyle(
                                                        fontFamily:
                                                            AppFonts.Montserrat,
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                            separatorBuilder: (context, index) =>
                                                Center(
                                                    child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 2),
                                                  child: Icon(Icons.arrow_forward,
                                                      size: 12,color: Colors.white,),
                                                )),
                                            itemCount: namedScope.length),
                                      );
                                    }),
                                  ),
                                  Icon(Icons.keyboard_arrow_down,color: Colors.white,)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Card(
                        color: AppColors.white,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text('Free Auto Ride Campaign',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Divider(color: Colors.grey.withOpacity(0.4)),
                              Column(
                                  children: [
                                {
                                  'title': 'Total Contributions',
                                  'value':
                                      '₹${donationDetails?.totalDonatedAmount.toStringAsFixed(1) ?? 0}'
                                },
                                {
                                  'title': 'Total Amount Spent',
                                  'value':
                                      '₹${donationDetails?.usedAmount.toStringAsFixed(1) ?? 0}'
                                },
                                {
                                  'title':
                                      'Total Kilometers Free Ride Provided',
                                  'value':
                                      '${donationDetails?.totalDistanceProvided.toStringAsFixed(1) ?? 0} KM'
                                },
                              ]
                                      .map((data) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 5),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                        data['title'] ?? '',
                                                        style: TextStyle(
                                                            fontSize: 15.5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                                Text(data['value'] ?? '',
                                                    style: TextStyle(
                                                        fontSize: 15.5))
                                              ],
                                            ),
                                          ))
                                      .toList())
                            ],
                          ),
                        ),
                      ),
                      Card(
                        color: AppColors.white,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                    'Data From ${DateFormat('dd MMM yyyy').format(selectedTime)}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                              Divider(color: Colors.grey.withOpacity(0.4)),
                              FutureBuilder(
                                  future: FirebaseFirestore.instance
                                      .collection(DAILY_RIDES_DB)
                                  .where('location', isEqualTo: scope.lastOrNull?.id)
                                      .where('datetime',
                                          isGreaterThanOrEqualTo:
                                              Timestamp.fromDate(DateTime(
                                                  selectedTime.year,
                                                  selectedTime.month,
                                                  selectedTime.day)))
                                      .where('datetime',
                                          isLessThan: Timestamp.fromDate(
                                              DateTime(
                                                      selectedTime.year,
                                                      selectedTime.month,
                                                      selectedTime.day)
                                                  .add(Duration(days: 1))))
                                      .get(),
                                  builder: (context, snapshot) {
                                    var data =
                                        snapshot.data?.docs.firstOrNull?.data();
                                    print(
                                        "ishwar: from ${snapshot.data?.docs.firstOrNull?.data()}");
                                    return Column(
                                        children: [
                                      {
                                        'title':
                                            'Kilometers Free Ride Provided',
                                        'value':
                                            '${(data?['distance'] ?? 0).toStringAsFixed(1)} KM'
                                      },
                                      {
                                        'title': 'Total Amount Spent',
                                        'value':
                                            '₹${(data?['amount'] ?? 0).toStringAsFixed(1)}'
                                      }
                                    ]
                                            .map((data) => Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 5),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                          child: Text(
                                                              data['title'] ??
                                                                  '',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      15.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500))),
                                                      Text(data['value'] ?? '',
                                                          style: TextStyle(
                                                              fontSize: 15.5))
                                                    ],
                                                  ),
                                                ))
                                            .toList());
                                  })
                            ],
                          ),
                        ),
                      ),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9)),
                        elevation: 4,
                        clipBehavior: Clip.hardEdge,
                        color: AppColors.white,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8)
                            .copyWith(bottom: 0),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text('Contributors List',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ),
                                Divider(color: Colors.grey.withOpacity(0.4)),
                                (donationDetails?.donors ?? []).isNotEmpty
                                    ? ListView(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        children: (donationDetails?.donors ??
                                                [])
                                            .map((donor) => InkWell(
                                                  onTap: () {
                                                    AppRoutes
                                                        .navigateToMyProfile(
                                                            userId: donor.id,
                                                            back: true,
                                                      isOrganization: false
                                                    );
                                                  },
                                                  child: ListTile(
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    leading: CircleAvatar(
                                                      backgroundImage:
                                                          CachedNetworkImageProvider(
                                                              donor
                                                                  .profileImage),
                                                      backgroundColor: AppColors
                                                          .gradient1
                                                          .withOpacity(0.1),
                                                    ),
                                                    title: Text(donor.donorName,
                                                        style: TextStyle(
                                                            fontSize: 15.5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                    subtitle: Text(
                                                        timeago.format(
                                                            donor.datetime),
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                    trailing: Text(
                                                        "₹${donor.amount.toStringAsFixed(1)}",
                                                        style: TextStyle(
                                                            fontSize: 15.5,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                  ),
                                                ))
                                            .toList(),
                                      )
                                    : Text("No Data Available")
                              ],
                            )),
                      ),
                      SizedBox(height: MediaQuery.sizeOf(context).width * 0.05),
                      Builder(
                        builder: (context) {
                          int donationAvl = (donationDetails?.totalDonatedAmount??0).toInt();
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9)),
                            elevation: 4,
                            clipBehavior: Clip.hardEdge,
                            color: AppColors.white,
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8)
                                .copyWith(bottom: 0),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                      child: Text('Auto List',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    if (autos.isNotEmpty && donationDetails != null) Padding(
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                      child: Text('Click on auto to see live location',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.normal)),
                                    ),
                                    Divider(color: Colors.grey.withOpacity(0.4)),
                                    autos.isNotEmpty
                                        ? ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        int amount = autos[index]['amount']??0;
                                        bool status = false;
                                        if (donationAvl >= amount) {
                                          donationAvl -= amount;
                                          status = true;
                                        }
                                        return Card(
                                          color: Colors.white,
                                          clipBehavior: Clip.hardEdge,
                                          margin: EdgeInsets.symmetric(vertical: 4.0),
                                          elevation: 0,
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                if (status) {
                                                  if (!await launchUrl(Uri.parse(autos[index]['link']))) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Couldn\'t load url! Please try again later.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    longToastMessage('Invalid location url');
                                                  }
                                                } else {
                                                  longToastMessage("Auto not available at the moment.");
                                                }
                                              } catch (e) {
                                                longToastMessage('Invalid location url $e');
                                              }
                                            },
                                            child: ListTile(
                                              title: Text('Auto ${index + 1}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                              // subtitle: Text("Click here to locate auto", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
                                              subtitle: Text.rich(
                                                  TextSpan(
                                                      text: autos[index]['from']??'Unknown',
                                                      children: [
                                                        WidgetSpan(child: Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                          child: Icon(Icons.swap_horiz_sharp, size: 16),
                                                        )),
                                                        TextSpan(
                                                          text: autos[index]['to']??'Unknown',
                                                        )
                                                      ]
                                                  )
                                              ),
                                              leading: Icon(Icons.local_taxi, color: AppColors.gradient1,),
                                              trailing: Icon(status ? Icons.location_on_rounded : Icons.money_off_csred, color: Colors.grey),
                                            ),
                                          ),
                                        );
                                      },
                                      itemCount: autos.length,
                                    )
                                        : Text("No Data Available")
                                  ],
                                )),
                          );
                        }
                      ),
                      SizedBox(height: MediaQuery.sizeOf(context).width * 0.05),
                      // AppButton(
                      //     onPressed: () => Navigator.of(context).push(
                      //         MaterialPageRoute(
                      //             builder: (context) =>
                      //                 TransferToCampaignScreen(() {
                      //                   print("ishwar: onWithdraw");
                      //                   getAllData();
                      //                 }, scopeSuffix: scope.lastOrNull?.id, title: 'People Contribution'))),
                      //     buttonText: 'Support Pradhaan'),
                      // SizedBox(height: MediaQuery.sizeOf(context).width * 0.4)
                    ],
                  ),
                ),
              ),
              if (!isDataReady)
                Container(
                  color: AppColors.textBackColor,
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.gradient1),
                  ),
                ),
              // Positioned(
              //   bottom: 0,
              //   left: 0,
              //   right: 0,
              //   child: Container(
              //     color: Theme.of(context).colorScheme.onPrimary,
              //     padding: EdgeInsets.symmetric(vertical: 16),
              //     child: AppButton(
              //         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAdScreen(onAddedCallbacks: () {}))),
              //         buttonText: 'Get Free Auto Ride'
              //     ),
              //   ),
              // )
            ],
          ),
        ));
  }
}
