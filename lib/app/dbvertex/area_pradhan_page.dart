// import 'dart:convert';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
// import 'package:chunaw/app/dbvertex/models/ad_model.dart';
// import 'package:chunaw/app/models/location_model.dart';
// import 'package:chunaw/app/models/user_model.dart';
// import 'package:chunaw/app/service/collection_name.dart';
// import 'package:chunaw/app/utils/app_pref.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
//
// import '../screen/home/post_card.dart';
// import '../utils/app_assets.dart';
// import '../utils/app_bar.dart';
// import '../utils/app_colors.dart';
// import '../utils/app_fonts.dart';
// import '../utils/app_routes.dart';
// import '../widgets/app_drawer.dart';
// import 'level_selector_sheet.dart';
//
// class AreaPradhanPage extends StatefulWidget {
//   final String? suffix;
//   final bool showAppbar;
//
//   const AreaPradhanPage({super.key, required this.showAppbar, this.suffix});
//
//   @override
//   State<StatefulWidget> createState() => AreaPradhanState();
// }
//
// class AreaPradhanState extends State<AreaPradhanPage> {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   String locationName = '';
//   List<LocationModel> scopes = [];
//
//   List<Map<String, dynamic>>? pradhaans;
//
//   @override
//   void initState() {
//     init();
//     super.initState();
//   }
//
//   Future<void> init() async {
//     print("ishwar: [AreaPradhanPage] [init] call , widget suffix: ${widget.suffix} ", );
//     if (widget.suffix == null) {
//       final country = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.COUNTRY)));
//       final state = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.STATE)));
//       final city = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.CITY)));
//
//       scopes = [country, state, city];
// print("ishwar : [areaPradhaan][init], cityId: ${city.id}");
//       await getData(city.id);
//     } else {
//       await getData(widget.suffix!);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: AppDrawer(),
//       appBar: widget.showAppbar ? AppBarCustom(leadingBack: true, title: locationName == ''
//             ? 'Pradhaan'
//             : 'Pradhaans of $locationName',
//         scaffoldKey: _scaffoldKey,
//         elevation: 0,
//       ) : null,
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           /*   if (!isDataReady)*/
//           if (pradhaans == null)LinearProgressIndicator(color: AppColors.gradient1),
//           if (scopes.isNotEmpty)
//             Card(
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(9)),
//               elevation: 0,
//               clipBehavior: Clip.hardEdge,
//               color: AppColors.textBackColor,
//               margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8)
//                   .copyWith(bottom: 0),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Builder(builder: (context) {
//                         var namedScope = scopes.map((loc) => loc.name).toList();
//                         return SizedBox(
//                           height: MediaQuery.sizeOf(context).width * 0.08,
//                           child: ListView.separated(
//                               scrollDirection: Axis.horizontal,
//                               shrinkWrap: true,
//                               itemBuilder: (context, index) => Center(
//                                 child: Text(
//                                   namedScope[index],
//                                   style: TextStyle(
//                                       fontFamily: AppFonts.Montserrat,
//                                       color: Theme.of(context).colorScheme.onSurface,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w500),
//                                 ),
//                               ),
//                               separatorBuilder: (context, index) => Center(
//                                   child: Padding(
//                                     padding: const EdgeInsets.symmetric(horizontal: 2),
//                                     child: Icon(Icons.arrow_forward, size: 12),
//                                   )
//                               ),
//                               itemCount: namedScope.length),
//                         );
//                       }),
//                     ),
//                     // Icon(Icons.keyboard_arrow_down)
//                     Card(
//                       color: AppColors.primaryColor,
//                       clipBehavior: Clip.hardEdge,
//                       margin: EdgeInsets.zero,
//                       child: InkWell(
//                         onTap: () async {
//                           LevelSelectorSheet.show(context,
//                                   (state, city, postal) {
//                                 scopes.clear();
//                                 scopes.add(LocationModel(name: 'India', text: 'IND', id: '1-India'));
//                                 if (state != null) {
//                                   scopes.add(state);
//                                   if (city != null) {
//                                     scopes.add(city);
//                                     if (postal != null) {
//                                       scopes.add(postal);
//                                     }
//                                   }
//                                 }
//                                 getData(scopes.last.id);
//                               },
//                               defaultState: scopes.length > 1 ? scopes[1] : null,
//                               defaultCity: scopes.length > 2 ? scopes[2] : null,
//                               defaultPostal:
//                               scopes.length > 3 ? scopes[3] : null);
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(
//                               vertical: 6, horizontal: 8)
//                               .copyWith(right: 10),
//                           child: Row(
//                             children: [
//                               Icon(Icons.keyboard_arrow_down,
//                                   color: Colors.white, size: 20),
//                               Text(
//                                 'Change',
//                                 style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           SizedBox(
//             height: 16,
//           ),
//           Expanded(
//             child: pradhaans == null
//                 ? Center(
//               child: CircularProgressIndicator(
//                   color: AppColors.primaryColor),
//             ) : pradhaans!.isEmpty
//                 ? Center(
//               child: Text('No Pradhaan found'),
//             ) : ListView.separated(
//                 itemBuilder: (context, index) => _createPradhanTile(pradhaans![index]),
//                 separatorBuilder: (context, index) =>
//                     Divider(color: Colors.grey[400]),
//                 itemCount: pradhaans?.length ?? 0),
//           ),
//         ],
//       )
//     );
//   }
//
//   DateTime getSunday(Timestamp timestamp) {
//     final date = timestamp.toDate().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
//     return date.subtract(Duration(days: date.weekday % 7));
//   }
//
//   Future<void> getData(String suffix) async {
//
//     setState(() {
//       pradhaans = null;
//     });
//
//     // suffix = '1-India';
//     Map<DateTime, MapEntry<String, Map<String, int>>> viewsData = {};
//
//     try {
//       final oldSnapshot = await FirebaseFirestore.instance.collection(VIEWS_DB).where('scope', isEqualTo: suffix).get();
//       final newSnapshot = await FirebaseFirestore.instance.collectionGroup(VIEWERS_DB).where('scope', isEqualTo: suffix).orderBy('scope',).get();
//      // print("ishwar: [AreaPradhanPage] [get data] call , snapshot: ${snapshot.docs.length} ", );
//
//       final snapshot = [...oldSnapshot.docs, ...newSnapshot.docs];
//
//
//       for (final snap in snapshot) {
//         final viewData = snap.data();
//
//         final pradhanId = viewData['pradhan_id'];
//         if (pradhanId == 'admin') continue;
//
//         final sunday = getSunday(viewData['created_at']);
//         final adId = viewData['ad_id'];
//
//
//         if (viewsData.containsKey(sunday)) {
//           viewsData[sunday]?.value[adId] = (viewsData[sunday]?.value[adId] ?? 0) + 1;
//         } else {
//           viewsData[sunday] = MapEntry(pradhanId, {adId: 1});
//         }
//       }
//     } catch (error) {
//       temp("Error while getting views data, Error : $error");
//     }
//
//     pradhaans = [];
//
//     try {
//       for (final viewData in viewsData.entries) {
//         DateTime start = viewData.key;
//         DateTime end = start.add(const Duration(days: 7));
// print("ishwar viewdatavaluekey: ${viewData.value.key}");
//         final userSnapshot = await FirebaseFirestore.instance.collection(USER_DB).doc(viewData.value.key).get();
//         UserModel? pradhan;
//         try {
//           pradhan = UserModel.fromJson(userSnapshot.data()??{});
//         } catch (err) {
//           temp('Error while getting user data for ${viewData.value.key}');
//           continue;
//         }
//
//         double amount = 0.0;
//         print("ishwar: viewData.value.value.entries: ${viewData.value.value.entries}");
//         for (final ad in viewData.value.value.entries) {
// print("ishwar: ad.key: ${ad.key}");
//           try {
//             final adSnapshot = await FirebaseFirestore.instance.collection(AD_DB).doc(ad.key).get();
//             print("ishwar: ad snapshot: ${adSnapshot.data()}");
//             AdModel adModel = AdModel.fromJson(adSnapshot.data() ?? {});
// print("ishwar: ad.value: ${ad.value}");
//             amount += ad.value * (adModel.proposedAmount / adModel.targetViews);
//           } catch (err) {
//             temp('calculating ad amount for $ad');
//             continue;
//           }
//         }
//
//         pradhaans?.add({
//           'pradhan': pradhan,
//           'amount': amount,
//           'startDate': start,
//           'endDate': end
//         });
//       }
//
//       DateTime start = getSunday(Timestamp.now());
//       temp("sunday: $start");
//
//       if (!viewsData.containsKey(start)) {
//         DateTime end = start.add(const Duration(days: 7));
//
//         final userSnapshot = await FirebaseFirestore.instance.collection(PRADHAN_DB).doc(suffix).get();
//         try {
//           temp((userSnapshot.data()??{})['pradhan_model']);
//           UserModel pradhan = UserModel.specialModel((userSnapshot.data()??{})['pradhan_model']);
//           if (pradhan.name.isNotEmpty) {
//             pradhaans?.add({
//               'pradhan': pradhan,
//               'amount': 0.0,
//               'startDate': start,
//               'endDate': end
//             });
//           }
//         } catch (err) {
//           temp('Error while getting user data for $suffix $err');
//         }
//       }
//     } catch (error) {
//       temp("Error while resolving views data");
//     }
//
//     pradhaans?.sort((a, b) {
//       return (b['startDate'] as DateTime).compareTo(a['startDate']);
//     });
//     setState(() {});
//   }
//
//   _createPradhanTile(Map<String, dynamic> pradhaan) {
//    // print("ishwar: pradhan : $pradhaan");
//     return ListTile(
//         onTap: () {
//           AppRoutes.navigateToMyProfile(userId: pradhaan['pradhan'].id, isOrganization: false, back: true);
//         },
//         leading: CircleAvatar(
//           radius: 22.r,
//           backgroundColor: getColorBasedOnLevel(1),
//           child: CircleAvatar(
//               radius: 25.r,
//               backgroundColor: AppColors.gradient1,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 clipBehavior: Clip.hardEdge,
//                 child: CachedNetworkImage(
//                   placeholder: (context, error) {
//                     return CircleAvatar(
//                       radius: 25.r,
//                       backgroundColor: AppColors.gradient1,
//                       child: Center(
//                           child: CircularProgressIndicator(
//                             color: AppColors.highlightColor,
//                           )),
//                     );
//                   },
//                   errorWidget: (context, error, stackTrace) {
//                     return Image.asset(
//                       AppAssets.brokenImage,
//                       fit: BoxFit.fitHeight,
//                       width: 160.0,
//                       height: 160.0,
//                     );
//                   },
//                   imageUrl: pradhaan['pradhan'].image ?? '',
//                   // .replaceAll('\', '//'),
//                   fit: BoxFit.cover,
//                   // width: 160.0,
//                   height: 160.0,
//                 ),
//               )),
//         ),
//         tileColor: Colors.white,
//         title: Text(pradhaan['pradhan'].name.isEmpty ? 'Admin' : pradhaan['pradhan'].name),
//         subtitle:
//         Text('Earning: Rs ${pradhaan['amount'].toStringAsFixed(2)}'),
//         trailing: Column(
//           children: [
//             Text(DateFormat("dd-MM-yyyy").format(pradhaan['startDate'])),
//             SizedBox(
//               height: 1,
//             ),
//             Text("To"),
//             SizedBox(
//               height: 1,
//             ),
//             Text(DateFormat("dd-MM-yyyy").format(pradhaan['endDate'])),
//           ],
//         ) /*Text(
//           '${pradhaan.value.key} ${pradhaan.value.key == 1 ? 'View' : 'Views'}'),*/
//     );
//   }
//
//   temp(dynamic message) {
//     print("ishwar:voting... $message");
//   }
//
// }
/////////////////////////////////////////////////////////////
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
import 'package:chunaw/app/dbvertex/models/ad_model.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../screen/home/post_card.dart';
import '../utils/app_assets.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_routes.dart';
import '../widgets/app_drawer.dart';
import 'level_selector_sheet.dart';

class AreaPradhanPage extends StatefulWidget {
  final String? suffix;
  final bool showAppbar;

  const AreaPradhanPage({super.key, required this.showAppbar, this.suffix});

  @override
  State<StatefulWidget> createState() => AreaPradhanState();
}

class AreaPradhanState extends State<AreaPradhanPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String locationName = '';
  List<LocationModel> scopes = [];

  List<Map<String, dynamic>>? pradhaans;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    print(
      "ishwar: [AreaPradhanPage] [init] call , widget suffix: ${widget.suffix} ",
    );
    if (widget.suffix == null) {
      final country =
          LocationModel.fromJson(jsonDecode(getPrefValue(Keys.COUNTRY)));
      final state =
          LocationModel.fromJson(jsonDecode(getPrefValue(Keys.STATE)));
      final city = LocationModel.fromJson(jsonDecode(getPrefValue(Keys.CITY)));

      scopes = [country, state, city];
      print("ishwar : [areaPradhaan][init], cityId: ${city.id}");
      await getData(city.id);
    } else {
      await getData(widget.suffix!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(),
        appBar: widget.showAppbar
            ? AppBarCustom(
                leadingBack: true,
                title: locationName == ''
                    ? 'Pradhaan'
                    : 'Pradhaans of $locationName',
                scaffoldKey: _scaffoldKey,
                elevation: 0,
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /*   if (!isDataReady)*/
            if (pradhaans == null)
              LinearProgressIndicator(color: AppColors.gradient1),
            if (scopes.isNotEmpty)
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
                          var namedScope =
                              scopes.map((loc) => loc.name).toList();
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
                                      child:
                                          Icon(Icons.arrow_forward, size: 12),
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
                              scopes.clear();
                              scopes.add(LocationModel(
                                  name: 'India', text: 'IND', id: '1-India'));
                              if (state != null) {
                                scopes.add(state);
                                if (city != null) {
                                  scopes.add(city);
                                  if (postal != null) {
                                    scopes.add(postal);
                                  }
                                }
                              }
                              getData(scopes.last.id);
                            },
                                defaultState:
                                    scopes.length > 1 ? scopes[1] : null,
                                defaultCity:
                                    scopes.length > 2 ? scopes[2] : null,
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
            Expanded(
              child: pradhaans == null
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor),
                    )
                  : pradhaans!.isEmpty
                      ? Center(
                          child: Text('No Pradhaan found'),
                        )
                      : ListView.separated(
                          itemBuilder: (context, index) =>
                              _createPradhanTile(pradhaans![index]),
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey[400]),
                          itemCount: pradhaans?.length ?? 0),
            ),
          ],
        ));
  }

  DateTime getSunday(Timestamp timestamp) {
    final date = timestamp.toDate().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    return date.subtract(Duration(days: date.weekday % 7));
  }
  DateTime getPreviousSunday(Timestamp timestamp) {
    final date = timestamp.toDate().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );

    // Agar date Sunday hai (weekday == 7), to pichhla Sunday paane ke liye 7 din pehle jaayein
    final daysToSubtract = date.weekday % 7 == 0 ? 7 : date.weekday % 7;
    return date.subtract(Duration(days: daysToSubtract));
  }
  Future<void> getData(String suffix) async {
    setState(() {
      pradhaans = null;
    });

    // suffix = '1-India';
    // Map<DateTime, MapEntry<String, Map<String, int>>> viewsData = {};

    try {
      // final oldSnapshot = await FirebaseFirestore.instance.collection(VIEWS_DB).where('scope', isEqualTo: suffix).get();
      // final newSnapshot = await FirebaseFirestore.instance.collectionGroup(VIEWERS_DB).where('scope', isEqualTo: suffix).orderBy('scope',).get();
      // print("ishwar: [AreaPradhanPage] [get data] call , snapshot: ${snapshot.docs.length} ", );
      print("ishwar: payout :------");

      final payouts = await FirebaseFirestore.instance
          .collectionGroup(LOCATIONS_PAY_DB)
          .where('scope', isEqualTo: suffix)
          .orderBy('created_at', descending: true)
          .get();

      // final snapshot = [...oldSnapshot.docs, ...newSnapshot.docs];

    //   for (final snap in snapshot) {
    //     final viewData = snap.data();
    //
    //     final pradhanId = viewData['pradhan_id'];
    //     if (pradhanId == 'admin') continue;
    //
    //     final sunday = getSunday(viewData['created_at']);
    //     final adId = viewData['ad_id'];
    //
    //     if (viewsData.containsKey(sunday)) {
    //       viewsData[sunday]?.value[adId] =
    //           (viewsData[sunday]?.value[adId] ?? 0) + 1;
    //     } else {
    //       viewsData[sunday] = MapEntry(pradhanId, {adId: 1});
    //     }
    //   }
    // } catch (error) {
    //   temp("Error while getting views data, Error : $error");
    // }

        pradhaans = [];
        if (payouts.docs.isEmpty) {
          print('ishwar: No payout data found for scope: $suffix');
        } else {
          print('ishwar: Payouts for scope: $suffix (${payouts.docs.length} documents)');
          for (final doc in payouts.docs) {
            final data = doc.data();
            // final startDate = getSunday(data['created_at']);
            final startDate = getPreviousSunday(data['created_at']);
            final endDate = data['created_at']?.toDate();


            // Fetch profile picture from users collection
            String? profilePicture;
            String userId = data['user_id'] ?? 'N/A';
            try {
              final userSnapshot = await FirebaseFirestore.instance
                  .collection(USER_DB)
                  .doc(userId)
                  .get();
              print("ishwar profile pic : ${userSnapshot.data()}");
              final userData = userSnapshot.data();
              profilePicture = userData?['image'];
              print('ishwar: Profile picture for $userId: $profilePicture');
            } catch (err) {
              print('ishwar: Error fetching user data for $userId: $err');
            }

            pradhaans!.add({
              'pradhan': {
                'id': userId,
                'name': data['pradhan_name'] ?? 'Unknown',
                'image': profilePicture,
              },
              'amount': data['amount_due']?.toDouble() ?? 0.0,
              'startDate': startDate,
              'endDate': endDate,
            });

            // Log for debugging
            print('ishwar: Payout Document ID: ${doc.id}');
            print('ishwar  User ID: $userId');
            print('ishwar  Pradhan Name: ${data['pradhan_name'] ?? 'Unknown'}');
            print('ishwar  Amount Due: ${data['amount_due']?.toStringAsFixed(2) ?? '0.00'}');
            print('ishwar  Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}');
            print('ishwar  End Date: ${DateFormat('yyyy-MM-dd').format(endDate)}');
            print('ishwar---');
          }
        }
      } catch (error) {
        print('ishwar: Error fetching payouts for scope $suffix: $error');
      }
    setState(() {});
  }
}
  // _createPradhanTile(Map<String, dynamic> pradhaan) {
  //   // print("ishwar: pradhan : $pradhaan");
  //   return ListTile(
  //       onTap: () {
  //         print("ishwar: pradhan id: ${pradhaan['pradhan'].id}");
  //         AppRoutes.navigateToMyProfile(
  //             userId: pradhaan['pradhan'].id,
  //             isOrganization: false,
  //             back: true);
  //       },
  //       // leading: CircleAvatar(
  //       //   radius: 22.r,
  //       //   backgroundColor: getColorBasedOnLevel(1),
  //       //   child: CircleAvatar(
  //       //       radius: 25.r,
  //       //       backgroundColor: AppColors.gradient1,
  //       //       child: ClipRRect(
  //       //         borderRadius: BorderRadius.circular(20),
  //       //         clipBehavior: Clip.hardEdge,
  //       //         child: CachedNetworkImage(
  //       //           placeholder: (context, error) {
  //       //             return CircleAvatar(
  //       //               radius: 25.r,
  //       //               backgroundColor: AppColors.gradient1,
  //       //               child: Center(
  //       //                   child: CircularProgressIndicator(
  //       //                 color: AppColors.highlightColor,
  //       //               )),
  //       //             );
  //       //           },
  //       //           errorWidget: (context, error, stackTrace) {
  //       //             return Image.asset(
  //       //               AppAssets.brokenImage,
  //       //               fit: BoxFit.fitHeight,
  //       //               width: 160.0,
  //       //               height: 160.0,
  //       //             );
  //       //           },
  //       //           imageUrl: pradhaan['pradhan'].image ?? '',
  //       //           // .replaceAll('\', '//'),
  //       //           fit: BoxFit.cover,
  //       //           // width: 160.0,
  //       //           height: 160.0,
  //       //         ),
  //       //       )),
  //       // ),
  //       tileColor: Colors.white,
  //       title: Text(pradhaan['pradhan'].name.isEmpty
  //           ? 'Admin'
  //           : pradhaan['pradhan'].name),
  //       subtitle: Text('Earning: Rs ${pradhaan['amount'].toStringAsFixed(2)}'),
  //       trailing: Column(
  //         children: [
  //           Text(DateFormat("dd-MM-yyyy").format(pradhaan['startDate'])),
  //           SizedBox(
  //             height: 1,
  //           ),
  //           Text("To"),
  //           SizedBox(
  //             height: 1,
  //           ),
  //           Text(DateFormat("dd-MM-yyyy").format(pradhaan['endDate'])),
  //         ],
  //       ) /*Text(
  //         '${pradhaan.value.key} ${pradhaan.value.key == 1 ? 'View' : 'Views'}'),*/
  //       );
  // }
Widget _createPradhanTile(Map<String, dynamic> pradhaan) {
  return ListTile(
    onTap: () {
      temp('ishwar: pradhan id: ${pradhaan['pradhan']['id']}');
      AppRoutes.navigateToMyProfile(
        userId: pradhaan['pradhan']['id'],
        isOrganization: false,
        back: true,
      );
    },
    leading: CircleAvatar(
      radius: 22.r,
      backgroundColor: getColorBasedOnLevel(1), // Adjust if level is available
      child: CircleAvatar(
        radius: 20.r,
        backgroundColor: AppColors.gradient1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          clipBehavior: Clip.hardEdge,
          child: pradhaan['pradhan']['image'] != null && pradhaan['pradhan']['image'].isNotEmpty
              ? CachedNetworkImage(
            imageUrl: pradhaan['pradhan']['image'],
            placeholder: (context, url) => CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.gradient1,
              child: CircularProgressIndicator(
                color: AppColors.highlightColor,
              ),
            ),
            errorWidget: (context, url, error) => Image.asset(
              AppAssets.brokenImage,
              fit: BoxFit.cover,
              width: 40.r,
              height: 40.r,
            ),
            fit: BoxFit.cover,
            width: 40.r,
            height: 40.r,
          )
              : Image.asset(
            AppAssets.brokenImage,
            fit: BoxFit.cover,
            width: 40.r,
            height: 40.r,
          ),
        ),
      ),
    ),
    tileColor: Colors.white,
    title: Text(
      pradhaan['pradhan']['name'].isEmpty ? 'Admin' : pradhaan['pradhan']['name'],
    ),
    subtitle: Text('Earning: Rs ${pradhaan['amount'].toStringAsFixed(2)}'),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(DateFormat("dd-MM-yyyy").format(pradhaan['startDate'])),
        const SizedBox(height: 1),
        const Text("To"),
        const SizedBox(height: 1),
        Text(DateFormat("dd-MM-yyyy").format(pradhaan['endDate'])),
      ],
    ),
  );
}
  temp(dynamic message) {
    print("ishwar:voting... $message");
  }

