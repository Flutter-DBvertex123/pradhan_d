import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/utils/ads_fetcher.dart';
import 'package:chunaw/app/dbvertex/widgets/AdCard.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/app_button.dart';
import 'completed_ads_screen.dart';
import 'create_ad_screen.dart';
import 'models/ad_model.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyAdsState();
  }
}

class _MyAdsState extends State<MyAdsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool previewMode = false;

  List<AdModel>? myAds;

  @override
  void initState() {
    super.initState();
    fetchAds();
  }

  void fetchAds() {
    AdsFetcher().getMyAds(false, true).then((ads) {
      print('ishwar: getMyAds result: $ads');
      setState(() {
        myAds = ads;
      });
    }, onError: (error) {
      print('ishwar: getMyAds error: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'My Promotions',
        elevation: 0,
        trailling: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                previewMode = !previewMode;
              });
            },
            itemBuilder: (BuildContext context) {
              return ['Preview: ${previewMode ? 'On' : 'off'}']
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (myAds != null)
            SingleChildScrollView(
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CompletedAdsScreen()));
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'View Completed Promotions',
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    elevation: 0,
                    margin: EdgeInsets.all(previewMode ? 0 : 8).copyWith(
                        bottom: MediaQuery.of(context).size.width * 0.31),
                    color: AppColors.textBackColor,
                    child: Padding(
                      padding: previewMode
                          ? EdgeInsets.zero
                          : const EdgeInsets.all(16),
                      child: myAds!.isNotEmpty
                          ? ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return _buildAdDetails(myAds![index]);
                              },
                              separatorBuilder: (context, index) =>
                                  previewMode ? SizedBox() : Divider(),
                              itemCount: myAds!.length)
                          : ListTile(
                              title: Center(
                                child: Text(
                                  'You currently have no active ad.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 16),
              child: AppButton(
                  onPressed: () {
                    // if is guest login, ask for sign in
                    if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
                      AppRoutes.navigateToLogin();
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateAdScreen(onAddedCallbacks: fetchAds),
                      ),
                    );
                  },
                  buttonText: 'Create New Promotion'),
            ),
          ),
          if (myAds == null)
            Container(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gradient1),
              ),
            )
        ],
      ),
    );
  }

  // Helper method to build Ad details
  Widget _buildAdDetails(AdModel ad) {
    if (previewMode) {
      return AdCard(
        adModel: ad,
        onVisible: (AdModel ad) {},
      );
    }
    return Row(children: [
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
                child: Container(color: Colors.black12)),
            errorWidget: (context, url, error) => Container(
                color: Colors.black12,
                child: Icon(ad.videoUrl != null
                    ? Icons.video_collection
                    : Icons.image_not_supported)),
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
                Expanded(
                    child: Text(ad.title,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
                Text(DateFormat('dd/MM/yyy').format(ad.createdAt),
                    style: TextStyle(
                        fontSize: 14, color: AppColors.bottomNavUnactiveColor)),
              ],
            ),
            // Text('Views: ${ad.targetViews}', style: TextStyle(fontSize: 14, color: AppColors.bottomNavUnactiveColor)),
            Text('Views: ${ad.generatedViews}/${ad.targetViews}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text(
                'Total Budget: ₹${(1 - (ad.generatedViews / ad.targetViews)) * ad.proposedAmount}/₹${ad.proposedAmount}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            SizedBox(height: 3),
            Text(
                'Scope: ${ad.scope.reversed.map((scopeName) => scopeName).toList().join(', ')}',
                style: TextStyle(
                    fontSize: 14, color: AppColors.bottomNavUnactiveColor)),
          ],
        ),
      ),
    ]);
  }
}
