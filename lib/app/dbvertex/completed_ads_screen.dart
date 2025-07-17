import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
import 'package:chunaw/app/dbvertex/utils/ads_fetcher.dart';
import 'package:chunaw/app/dbvertex/widgets/AdCard.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/app_assets.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/app_button.dart';
import '../widgets/app_drawer.dart';
import 'get_certificate_dialog.dart';
import 'models/ad_model.dart';

class CompletedAdsScreen extends StatefulWidget {
  const CompletedAdsScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CompletedAdsState();
  }
}

class _CompletedAdsState extends State<CompletedAdsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool previewMode = false;
  List<AdModel>? myAds;
  List<MapEntry<String, Map<String, dynamic>>>? weekWiseContributions;

  @override
  void initState() {
    super.initState();
    fetchAds();
  }

  Future<void> fetchAds() async {
    try {
      myAds = await AdsFetcher().getMyAds(true, false);
      weekWiseContributions = await getPradhaanWiseDetails();
    } catch (error) {
      myAds ??= [];
      weekWiseContributions ??= [];
      print('ishwar: getMyAds error: $error');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Completed Promotions',
        elevation: 0,
        trailling:  Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                previewMode = !previewMode;
              });
            },
            itemBuilder: (BuildContext context) {
              return ['Preview: ${previewMode ? 'On' : 'off'}'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              })
                  .toList();
            },
          ),
        ),
      ),
      body: myAds != null ? SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              elevation: 0,
              clipBehavior: Clip.hardEdge,
              color: AppColors.textBackColor,
              margin: previewMode
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(vertical: 8, horizontal: 8)
                  .copyWith(bottom: 0),
              child: InkWell(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Weekly Certificates'),
                          actions: [
                            TextButton(
                                onPressed: () {
                                 Navigator.pop(context);
                                },
                                child: Text(
                                  'Dismiss',
                                  style: TextStyle(
                                    color: AppColors.gradient1
                                  ),
                                )
                            )
                          ],
                          icon: Icon(Icons.celebration_rounded),
                          content: _createContributionView(),
                        );
                      }
                  );
                },
                child: Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Get Weekly Certificates',
                          style: TextStyle(
                              fontFamily: AppFonts.Montserrat,
                              color: AppColors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded)
                    ],
                  ),
                ),
              ),
            ),
              if (previewMode) SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              elevation: 0,
              margin: EdgeInsets.all(previewMode ? 0 : 8),
              color: AppColors.textBackColor,
              child: Padding(
                padding: previewMode ? EdgeInsets.zero : const EdgeInsets.all(16),
                child: myAds!.isNotEmpty ? ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildAdDetails(myAds![index]);
                    },
                    separatorBuilder: (context, index) => previewMode ? SizedBox() : Divider(),
                    itemCount: myAds!.length
                ) : ListTile(
                  title: Center(
                    child: Text(
                      'You currently have no active ad.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            //
            // if (!previewMode && (weekWiseContributions?.isNotEmpty ?? false)) Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            //   child: Text(
            //     'Weekly Pradhaan-Wise Contributions',
            //     style: TextStyle(
            //         fontSize: 16,
            //         color: Colors.black,
            //         fontWeight: FontWeight.w500
            //     ),
            //   ),
            // ),
            // if (!previewMode && (weekWiseContributions?.isNotEmpty ?? false)) _createContributionView()
          ],
        ),
      ) : Container(
        color: Colors.white,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gradient1),
        ),
      ),
    );
  }

  // Helper method to build Ad details
  Widget _buildAdDetails(AdModel ad) {
    if (previewMode) {
      return AdCard(adModel: ad, onVisible: (AdModel ad) {  },);
    }
    return Row(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).width * 0.2,
            width: MediaQuery.sizeOf(context).width * 0.2,
            child: Card(
              clipBehavior: Clip.hardEdge,
              elevation: 0,
              margin: EdgeInsets.zero,
              child: CachedNetworkImage(
                height: MediaQuery.sizeOf(context).width * 0.2,
                width: MediaQuery.sizeOf(context).width * 0.2,
                imageUrl: ad.images.firstOrNull ?? '',
                placeholderFadeInDuration: Duration.zero,
                fit: BoxFit.cover,
                placeholder: (context, error) => Shimmer.fromColors(
                    baseColor: Colors.grey.withOpacity(0.3),
                    highlightColor: Colors.white,
                    child: Container(color: Colors.black12)
                ),
                errorWidget: (context, url, error) => Container(color: Colors.black12, child: Icon(ad.videoUrl != null ? Icons.video_collection : Icons.image_not_supported)),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(ad.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    Text(DateFormat('dd/MM/yyy').format(ad.createdAt), style: TextStyle(fontSize: 14, color: AppColors.bottomNavUnactiveColor)),
                  ],
                ),
                // Text('Views: ${ad.targetViews}', style: TextStyle(fontSize: 14, color: AppColors.bottomNavUnactiveColor)),
                Text('Views: ${ad.generatedViews}/${ad.targetViews}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text('Total Budget: ₹${(1 - (ad.generatedViews/ad.targetViews)) * ad.proposedAmount}/₹${ad.proposedAmount}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                SizedBox(height: 3),
                Text('Scope: ${ad.scope.reversed.map((scopeName) => scopeName).toList().join(', ')}', style: TextStyle(fontSize: 14, color: AppColors.bottomNavUnactiveColor)),
              ],
            ),
          ),
        ]
    );
  }

  _createContributionView() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      elevation: 0,
      margin: EdgeInsets.all(8),
      color: AppColors.textBackColor,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: !previewMode && (weekWiseContributions?.isNotEmpty ?? false) ? ListView.separated(
              // shrinkWrap: true,
              // physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                MapEntry<String, Map<String, dynamic>> child = weekWiseContributions![index];
                Map<String, dynamic> data = child.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22.r,
                            backgroundColor: getColorBasedOnLevel(data['pradhan_level'] ?? 1),
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
                                    imageUrl: data['pradhan_image'] ?? '',
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
                                Text(
                                  data['pradhan_name'] ?? 'Unknown',
                                  maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black
                                  )
                                ),
                                Text(
                                    data['pradhan_username'] ?? '@unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.gradient1
                                    )
                                ),
                              ],
                            ),
                          ),
                          Card(
                            color: AppColors.gradient1,
                            clipBehavior: Clip.hardEdge,
                            margin: EdgeInsets.zero,
                            child: InkWell(
                              onTap: () {
                                CertificateDialog.show(
                                    context,
                                    data['pradhan_name'] ?? 'Admin',
                                    data['scope'] ?? 'India',
                                  data['total_amount'] ?? 0.0
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Text(
                                    'Get',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            )
                          )
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildSummaryRow('Views Generated', "${data['total_views'] ?? 0}"),
                      _buildSummaryRow('Contribution', "₹${(data['total_amount'] as double).toStringAsFixed(2)}"),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => Divider(),
              itemCount: weekWiseContributions?.length ?? 0
          ) : Text(
              'You have made no contribution in this week.',
            textAlign: TextAlign.center
          )
      ),
    );
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


  Future<List<MapEntry<String, Map<String, dynamic>>>?> getPradhaanWiseDetails() async {
    print("ishwar: getting pradhan wise details: ${myAds?.map((ad) => ad.id)}");
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday)).copyWith(hour: 22, minute: 0, second: 10);

      // final doc = await FirebaseFirestore.instance.collection(VIEWS_DB).where('ad_id', whereIn: myAds?.map((ad) => ad.id)).where('created_at', isGreaterThanOrEqualTo: startOfWeek).get();
      final oldDoc = await FirebaseFirestore.instance.collection(VIEWS_DB).where('ad_id', whereIn: myAds?.map((ad) => ad.id)).where('created_at', isGreaterThanOrEqualTo: startOfWeek).get();
      final newDoc = await FirebaseFirestore.instance.collectionGroup(VIEWERS_DB).where('ad_id', whereIn: myAds?.map((ad) => ad.id)).where('created_at', isGreaterThanOrEqualTo: startOfWeek).orderBy('created_at').get();
      final doc=[...oldDoc.docs, ...newDoc.docs];
      Map<String, Map<String, dynamic>> pradhaanWiseData = {};
      // for (final view in doc.docs) {
      for (final view in doc) {
        final viewData = view.data();


        String pradhanId = viewData['pradhan_id'] ?? 'admin';
        if (!pradhaanWiseData.containsKey(pradhanId)) {

          String pradhanName = 'admin';
          String pradhanUsername = 'admin';
          String image = '';
          int level = 1;

          if (pradhanId != 'admin') {
            final pradhanData = (await FirebaseFirestore.instance.collection(USER_DB).doc(pradhanId).get()).data() ?? {};
            pradhanName = pradhanData['name'] ?? 'Unknown';
            pradhanUsername = pradhanData['username'] ?? 'unknown';
            image = pradhanData['image'] ?? '';
            level = pradhanData['level'] ?? 1;
          }

          AdModel? ad = myAds?.where((a) => a.id == viewData['ad_id']).firstOrNull;

    pradhaanWiseData[pradhanId] = {
            'amountPerView': (ad?.proposedAmount ?? 0) / (ad?.targetViews ?? 1), // remove 10%
            'ad_name': ad?.title,
            'scope': ad?.scopeSuffix,
            'pradhan_name': pradhanName,
            'pradhan_username': '@$pradhanUsername',
            'pradhan_image': image,
            'pradhan_level': level
          };
        }
        pradhaanWiseData[pradhanId]?['ad_id'] = viewData['ad_id'] ?? '';
        pradhaanWiseData[pradhanId]?['total_views'] = ((pradhaanWiseData[pradhanId]?['total_views'] ?? 0) as int) + 1;
      }

      for (final entry in pradhaanWiseData.entries) {
        entry.value['total_amount'] = entry.value['amountPerView'] * entry.value['total_views'];
      }

      print("ishwar: $pradhaanWiseData");


      return pradhaanWiseData.entries.toList(growable: false);
    } catch (error) {
      print("ishwar: $error");
      return [];
    }

  }

}
