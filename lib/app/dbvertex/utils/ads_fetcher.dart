import 'dart:convert';
import 'dart:math';

import 'package:chunaw/app/service/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/location_model.dart';
import '../../utils/app_pref.dart';
import '../ishwar_constants.dart';
import '../models/ad_model.dart';

class AdsFetcher {
  static final AdsFetcher _instance = AdsFetcher._internal();

  AdsFetcher._internal();

  factory AdsFetcher() {
    return _instance;
  }

  final cachedAds = <AdModel>[];

  final Random randomness = Random();

  double getRandomDouble() {
    return randomness.nextDouble();
  }

  int getRandomInt(int bound) {
    return randomness.nextInt(bound);
  }

  Future<List<AdModel>> getMyAds(
      bool filterCompleted, bool filterRunning) async {
    // if is guest login, just return an empty list
    if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
      return [];
    }

    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(AD_DB)
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('created_at', descending: true)
        .get();
    final List<DocumentSnapshot<Object?>> documents = result.docs;

    if (documents.isNotEmpty) {
      print("ishwar: if: ${documents.isNotEmpty}");
      List<AdModel> list = [];
      for (var element in documents) {
        AdModel ad = AdModel.fromJson(element.data() as Map);
        if ((filterCompleted && ad.generatedViews >= ad.targetViews) ||
            (filterRunning && ad.targetViews > ad.generatedViews)) {
          list.add(ad);
        }
      }
      return list;
    } else {
      print("ishwar: else ${documents.isNotEmpty}");
      return [];
    }
  }

  Future<AdModel?> getRandomAd() async {
    print("ishwar: 1");
    final List<String> selectedStates = getPrefValue(Keys.PREFERRED_STATES).isEmpty ? [] : List<String>.from(jsonDecode(getPrefValue(Keys.PREFERRED_STATES)));
    print("ishwar: 2");
    selectedStates.add(locationModelFromJson(getPrefValue(Keys.STATE)).name);
    print("ishwar: 3");
    print("ishwar: $selectedStates");
    if (cachedAds.isEmpty) {
      print("ishwar: 4");
      try {
        print("ishwar: 41");
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getRandomAd');
        print("ishwar: 42");
        final response = await callable.call({"scope": selectedStates});
        print("ishwar: 43");
        print("ishwar: ${response.data}");

        if (response.data is List) {
          print("ishwar: 431");
          print("ishwar: total ads: ${response.data.length}");
          for (var doc in response.data) {
            print("ishwar: 432");
            AdModel ad = AdModel.fromJson(doc);
            print("ishwar: 433");
            cachedAds.add(ad);
            print("ishwar: 434");
          }
          print("ishwar: 435");
        } else {
          print("ishwar: 44");
          throw response.data['message'];
        }
        print("ishwar: 45");

      } catch (e) {
        print("ishwar: 46: $e");
        rethrow;
      }

      print("ishwar: 47");

    }
    print("ishwar: 5");
    AdModel? ad;
    print("ishwar: 6");
    if (cachedAds.isNotEmpty) {
      print("ishwar: 61");
      int index = getRandomInt(cachedAds.length);
      print("ishwar: 62");
      ad = cachedAds[index];
      print("ishwar: 63");
      cachedAds.removeAt(index);
      print("ishwar: 64");
    }
    print("ishwar: 7");
    return ad;

  }
  // Future<AdModel?> getRandomAd(List<String>? scope, List<String> idsToAvoid) async {
  //   List<String> scopeToShow = scope == null ? [] : [scope.last];
  //
  //   final randomValue = getRandomDouble();
  //   print("ishwar: getRandomAd(${scopeToShow}, ${idsToAvoid}, $randomValue})");
  //
  //   List<DocumentSnapshot<Object?>> documents = (await _getAd(scopeToShow, randomValue)).where((ad) {
  //     print("ishwar: item $ad");
  //     return (ad['target_views']??0) > (ad['generated_views']??0) && !idsToAvoid.contains(ad['id']);
  //   }).toList();
  //   if (documents.isEmpty) {
  //     documents = (await _getAd(scopeToShow, randomValue)).where((ad) => (ad['target_views']??0) > (ad['generated_views']??0) && !idsToAvoid.contains(ad['id'])).toList();
  //   }
  //
  //   print("ishwar: getRandomAd ${documents}");
  //
  //   if (documents.isNotEmpty) {
  //     List<AdModel> list = [];
  //     for (var element in documents) {
  //       AdModel ad = AdModel.fromJson(element.data() as Map);
  //       if (ad.targetViews > ad.generatedViews) {
  //         list.add(ad);
  //       }
  //     }
  //
  //     list.sort((a, b) {
  //       // First compare by priority in descending order
  //       int priorityComparison = b.priority.compareTo(a.priority);
  //
  //       if (priorityComparison != 0) {
  //         return priorityComparison;
  //       }
  //
  //       // Handle null safety and avoid division by zero
  //       double aRatio = (a.generatedViews) / (a.targetViews != 0 ? a.targetViews : 1);
  //       double bRatio = (b.generatedViews) / (b.targetViews != 0 ? b.targetViews : 1);
  //
  //       // Compare the ratios in descending order
  //       return bRatio.compareTo(aRatio);
  //     });
  //
  //     print("ishwar: printing sorted ads");
  //     for (var ad in list) {
  //       print('ishwar: ${ad.scope.join(',')} == ${scope?.join(',')}');
  //     }
  //     print("ishwar:");
  //
  //     if (list.isNotEmpty) {
  //       return list[0];
  //     }
  //   }
  //   return null;
  // }
  //
  // Future<List<DocumentSnapshot<Object?>>> _getAd(List preferredStates, double randomValue) async {
  //   final Query query = FirebaseFirestore.instance
  //       .collection(AD_DB)
  //       .where('scope', arrayContainsAny: preferredStates)
  //       // .where('remaining_amount', isNotEqualTo: 0)
  //       .where('randomness', isGreaterThanOrEqualTo: randomValue)
  //   // .where('uid', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
  //   // .where('id', whereNotIn: idsToAvoid)
  //       .limit(5);
  //   final QuerySnapshot result = await query.get();
  //   return result.docs;
  // }

  Future<void> postAd(AdModel ad) async {
    try {
      await FirebaseFirestore.instance
          .collection(AD_DB)
          .doc(ad.id)
          .set(ad.toJson());
    } catch (e) {
      print("ishwar: $e");
      throw 'Failed to post ad';
    }
  }

  // Future<String> _getPradhaan(AdModel adModel) async {
  //   final DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
  //       .collection(PRADHAN_DB)
  //       .doc(adModel.scopeSuffix).get();
  //   return snapshot.data()?['pradhan_id']??'admin';
  // }

  Future<Map<String, dynamic>> callStoreViewFunction(AdModel ad) async {
    try {

      if (ad.id.isEmpty) {
        print("if adid is empty: ${ad.id.isEmpty}");
        throw Exception('Ad ID is empty');
      }

      // Construct document path for the ad
      final documentPath = 'ads/${ad.id}';

      final userModel = await UserService.getUserData(FirebaseAuth.instance.currentUser!.uid);
      final level = [
        userModel!.postal,
        userModel.city,
        userModel.state,
        userModel.country
      ][userModel.level - 1];

      print("ishwar:newpoints :: level -> ${level.toJson()}");
      print("ishwar: Scope suffix: ${level.id}, Ad ID: ${ad.id}");
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('storeViewAndUpdateGeneratedViews');
      print("ishwar: Calling storeViewAndUpdateGeneratedViews for ad ${ad.id}, scope suffix: ${level.id}");
      final response = await callable.call({"ad_id": ad.id, "scopeSuffix": level.id});


      // // Call Firebase Cloud Function
      // final callable = FirebaseFunctions.instance.httpsCallable('storeViewAndUpdateGeneratedViews');
      // final response = await callable.call({
      //   'documentPath': documentPath,
      //   'scopeSuffix': level.id,
      //   'viewerId': FirebaseAuth.instance.currentUser!.uid,
      // });

      print("ishwar: Response: ${response.data}");
      return response.data;
    } catch (e) {
      print("ishwar: Error calling storeViewAndUpdateGeneratedViews: $e");
      throw "ishwar:newpoints :: error -> calling function : $e";
    }
  }

  // Future<void> pingViewCount(AdModel ad) async {
  //   if (!(await existsViewerForAd(ad))) {
  //     String? fetchedPradhaanId = await _getPradhaan(ad);
  //     fetchedPradhaanId = await _getPradhaan(ad);
  //
  //     print("ishwar: pradhaan: $fetchedPradhaanId");
  //
  //     String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  //
  //     ad.generatedViews++;
  //
  //     DocumentReference doc = FirebaseFirestore.instance
  //         .collection(AD_DB)
  //         .doc(ad.id);
  //     DocumentSnapshot docresult = await doc.get();
  //     if (docresult.exists) {
  //       await doc.update({'generated_views': docresult['generated_views'] + 1});
  //     }
  //
  //     var viewer = AdViewerModel(ad.id, uid, fetchedPradhaanId, ad.scope);
  //     await FirebaseFirestore.instance
  //         .collection(VIEWS_DB)
  //         .doc(ad.id)
  //         .set(viewer.toJson());
  //
  //     print("ishwar: added ${ad.id} as ${viewer.toJson()}");
  //   }
  // }
  //
  // Future<bool> existsViewerForAd(AdModel ad) async {
  //   final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection(VIEWS_DB).doc(ad.id).get(const GetOptions(source: Source.server));
  //   bool exists = snapshot.exists && snapshot.get('viewer_id') == FirebaseAuth.instance.currentUser?.uid;
  //   print("ishwar: checking existence ${exists ? snapshot.get('viewer_id') : null}==${FirebaseAuth.instance.currentUser?.uid} exists: $exists");
  //   return exists;
  // }
}
