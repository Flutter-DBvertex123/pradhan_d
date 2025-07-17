import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/pitch_screen.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shimmer/shimmer.dart';

import '../screen/home/post_card.dart';
import '../service/collection_name.dart';
import '../utils/app_assets.dart';
import '../utils/app_bar.dart';
import '../utils/app_routes.dart';
import 'ishwar_constants.dart';

class PromotersScreen extends StatefulWidget {
  final bool showAppBar;
  final String locationId;

  const PromotersScreen({super.key, required this.locationId, this.showAppBar = false});

  @override
  State<StatefulWidget> createState() => PromotersState();
}

class PromotersState extends State<PromotersScreen> {
  List<Map<String, dynamic>>? promoters;

  Future<bool> checkIfAmPradhaan() async {
    final doc = await FirebaseFirestore.instance
        .collection(PRADHAN_DB)
        .doc(widget.locationId)
        .get();

    return doc.data()?['pradhan_id'] == FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    fetchAdvertisers();
  }

  Future<void> fetchAdvertisers() async {
    print("ishwar: ${widget.locationId}");
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getAdvertisers');
      final response = await callable.call({"scope_suffix": widget.locationId});

      final responseData = response.data;
      promoters = [];

      if (responseData.containsKey('advertisers') ?? false) {
        for (var user in responseData['advertisers']) {
          var data = {
            'name': user['name'],
            'username': user['username'],
            'profile_pic': user['image'],
            'uid': user['uid'],
            'level': user['level'],
            'total_amount': user['total_amount'],
            'current_week_amount': user['current_week_amount'],
            'type': user['type']
          };
          promoters?.add(data);
        }
      }
      setState(() {});
    } catch (error) {
      print("ishwar: $error");
      setState(() {
        promoters = [];
      });
    }
  }

  Future<void> toggleCheck(bool select, String? promoterID, String uid) async {
    print("ishwar: $select $promoterID $uid");

    try {
      final reference = FirebaseFirestore.instance.collection(PROMOTER_DB);
      if (select) {
        if (promoterID == null) {
          await reference.doc().set({
            'uid': uid,
            'scope_suffix': widget.locationId,
            'selected': true
          });
        } else {
          await reference.doc(promoterID).set({
            'uid': uid,
            'scope_suffix': widget.locationId,
            'selected': true
          });
        }
      } else {
        await reference.doc(promoterID).update({'selected': false});
      }
    } catch (error) {
      longToastMessage('Something went wrong, $error');
    }
  }

  Future<void> pitch(Map<String, String> promoters) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => PitchScreen(usersToPitch: promoters, scope: widget.locationId)));
    if (mounted) {
      setState(() {});
    }
  }

  static bool isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Start of the week (Monday)
    final endOfWeek = startOfWeek.add(Duration(days: 6)); // End of the week (Sunday)
    print("ishwar:time startOfWeek: $startOfWeek");
    return (DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).isAtSameMomentAs(DateTime(date.year, date.month, date.day)) || date.isAfter(startOfWeek)) && date.isBefore(endOfWeek.add(Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<bool>(
      future: checkIfAmPradhaan(),
      builder: (context, pradhaanSnapshot) {
        bool amPradhaan = pradhaanSnapshot.data??false;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: (promoters?.isNotEmpty ?? false) ? FirebaseFirestore.instance.collection(PROMOTER_DB).where('scope_suffix', isEqualTo: widget.locationId).snapshots() : null,
            builder: (context, snapshot) {

              Map<String, dynamic> promotersData = {};
              Map<String, String> pitchablePromotersData = {};

              for (QueryDocumentSnapshot data in snapshot.data?.docs??[]) {
                Map<String, dynamic> dataJson = (data.data() ?? {}) as Map<String, dynamic>;
                final pitchDate = (dataJson['pitch_date'] ?? Timestamp.fromDate(DateTime(2001))).toDate();
                final item = {
                  'pitched': isCurrentWeek(pitchDate),
                  'selected': dataJson['selected'] ?? false,
                  'id': data.id
                };

                if (!item['pitched'] && item['selected']) {
                  pitchablePromotersData[dataJson['uid']] = data.id;
                }
                promotersData[dataJson['uid']] = item;
              }

              return Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.separated(
                      itemBuilder: (context, index) {

                        Map<String, dynamic> userData = promoters?[index] ?? {};

                        Widget tile = Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22.r,
                                    backgroundColor: getColorBasedOnLevel(userData['level'] ?? 1),
                                    child: CircleAvatar(
                                        radius: 20.r,
                                        backgroundColor: AppColors.gradient1,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          clipBehavior: Clip.hardEdge,
                                          child: CachedNetworkImage(
                                            placeholder: (context, error) {
                                              return CircleAvatar(
                                                radius: 15.r,
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
                                            imageUrl: userData['profile_pic'] ?? '',
                                            // .replaceAll('\', '//'),
                                            fit: BoxFit.cover,
                                            // width: 160.0,
                                            height: 160.0,
                                          ),
                                        )),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          color: Colors.white,
                                          child: Text(
                                              userData['name'] ?? 'Unknown',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black
                                              )
                                          ),
                                        ),
                                        SizedBox(height: 1),
                                        Container(
                                          color: Colors.white,
                                          child: Text(
                                              userData['username'] ?? '@unknown',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w400,
                                                  color: AppColors.gradient1
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(16)
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      margin: EdgeInsets.symmetric(horizontal: amPradhaan ? 12 : 0),
                                      child: Text(
                                          userData['type'] ?? 'Sponsor'
                                      )
                                  ),
                                  if (amPradhaan) SizedBox(
                                    width: MediaQuery.sizeOf(context).width * 0.05,
                                    height: MediaQuery.sizeOf(context).width * 0.05,
                                    child: Checkbox(
                                        value: promotersData[userData['uid']]?['selected'] ?? false,
                                        activeColor: promotersData[userData['uid']]?['pitched'] ?? false ? Colors.grey : AppColors.gradient1,
                                        focusColor: AppColors.gradient1,
                                        side: BorderSide(color: AppColors.gradient1, width: 2),
                                        onChanged: (value) {
                                          if (!(promotersData[userData['uid']]?['pitched'] ?? false)) {
                                            toggleCheck(value!, promotersData[userData['uid']]?['id'], userData['uid']);
                                          } else {
                                            longToastMessage('You have already pitched ${userData['name']} this week.');
                                          }
                                        }
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              _buildSummaryRow('Weekly Contributions', "₹${userData['current_week_amount']}"),
                              _buildSummaryRow('Total Contribution', "₹${(double.tryParse("${userData['total_amount'] ?? 0.0}") ?? 0.0).toStringAsFixed(2)}"),
                            ],
                          ),
                        );

                        if (promoters == null) {
                          return Shimmer.fromColors(baseColor: Colors.white, highlightColor: Colors.grey, child: tile);
                        } else {
                          return tile;
                        }
                      },
                      itemCount: promoters?.length ?? 8, separatorBuilder: (BuildContext context, int index) {
                      return Container(
                        color: Colors.white,
                        child: Divider(
                          color: Colors.grey.withOpacity(0.4),
                          indent: 50,
                        ),
                      );
                    },
                    )
                  ),
                ),
                if (amPradhaan) Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  margin: EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          pitchablePromotersData.isNotEmpty ? '${pitchablePromotersData.length} promoters selected' : 'No Promoter selected to pitch',
                          style: TextStyle(
                              fontSize: 15
                          ),
                        ),
                      ),
                      Card(
                        color: AppColors.gradient1.withOpacity(pitchablePromotersData.isNotEmpty ? 1.0 : 0.5),
                        clipBehavior: Clip.hardEdge,
                        elevation: 0,
                        child: InkWell(
                          onTap: pitchablePromotersData.isNotEmpty ? () async {
                            pitch(pitchablePromotersData);
                          } : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                            child: Text(
                              'Pitch',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            );
          }
        );
      }
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBarCustom(
          title: 'Promoters List',
          leadingBack: true,
          elevation: 0,
          showSearch: false,
        ),
        body: body,
      );
    } else {
      return body;
    }
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500)),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}