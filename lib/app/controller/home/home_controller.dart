// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:math';

import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/service/location_service.dart';
import 'package:chunaw/app/service/sachiv_service.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../dbvertex/models/ad_model.dart';
import '../../dbvertex/utils/ads_fetcher.dart';

class HomeController extends GetxController {
  String? _currentRequestId;
  var isLoading = false.obs;
  Rx<UserModel> areaSachiv = UserModel.empty().obs;
  List<PostModel> postList = List<PostModel>.empty(growable: true);
  // variable to hold the last doc
  DocumentSnapshot? lastDoc;
  RxBool stateLoading = false.obs;
  RxBool cityLoading = false.obs;
  RxBool postalLoading = false.obs;
  Rx<LocationModel> selectedCity = LocationModel.empty(name: "Select City").obs;
  Rx<LocationModel> selectedState =
      LocationModel.empty(name: "Select State").obs;
  Rx<LocationModel> selectedPostal =
      LocationModel.empty(name: "Select Postal").obs;
  List<String> fullAdd = [];
  RxInt filterby = 0.obs; // 0 : postal 1: City 2: state

  // DB Vertex
  List<AdModel?> adList = List<AdModel?>.empty(growable: true);
  List<String> loadedAdIDs = [];

  getCity() async {
    cityLoading(true);
    cityList = await LocationService.getCity("1-India", selectedState.value.id);
    cityLoading(false);
    update();
  }

  getPostal() async {
    postalLoading(true);
    print(selectedCity.value.id);
    postalList = await LocationService.getPostal(
        "1-India", selectedState.value.id, selectedCity.value.id);
    postalLoading(false);
    update();
  }

  List<LocationModel> stateList = List<LocationModel>.empty(growable: true).obs;
  List<LocationModel> cityList = List<LocationModel>.empty(growable: true).obs;
  List<LocationModel> postalList =
      List<LocationModel>.empty(growable: true).obs;

  Future<void> viewAd(AdModel ad) async {
    print("ishwar: Attempting to view ad: ${ad.id}");
    if (!loadedAdIDs.contains(ad.id) &&
        ad.uid != FirebaseAuth.instance.currentUser?.uid) {
      print("ishwar: if viewAd call//////");
      loadedAdIDs.add(ad.id);
      print("ishwar: viewing ads: ${ad.id}, $loadedAdIDs");
     await AdsFetcher().callStoreViewFunction(ad).then((_) {
        print("ishwar: View logged successfully: ${_}");
      }, onError: (error) {
       print("ishwar: yash: error on view add : $error");
        // if (loadedAdIDs.contains(ad.id)) loadedAdIDs.remove(ad.id);
      });
    }else{
      print("ishwar: else View skipped - already viewed or own ad: ${ad.id}");
    }
  }

  Future<void> addAdvertisement() async {
    AdModel? ad;
    int index = postList.length;
    print("ishwar: index: $index and len: ${adList.length}");

    if (index % 5 == 0 && index > adList.length /*&& AdsFetcher().getRandomDouble() > 0.1*/) {
      try {
        ad = await AdsFetcher().getRandomAd();
      } catch (er) {
        print("ishwar: skipped at: $er");
      }
      print("ishwar: added at: $index ${ad?.toJson()}");
    }

    adList.add(ad);
  }

  // List<UserModel> userListDisplay = List<UserModel>.empty(growable: true);
  @override
  void onInit() {
    getStates();
    selectedPostal.value = locationModelFromJson(getPrefValue(Keys.POSTAL));
    selectedState.value = locationModelFromJson(getPrefValue(Keys.STATE));
    selectedCity.value = locationModelFromJson(getPrefValue(Keys.CITY));
    fullAdd = [
      selectedCity.value.name,
      selectedPostal.value.name,
      selectedState.value.name,
    ];
    getPosts(0);

    super.onInit();
  }

  int limit = 10;
  getStates() async {
    stateLoading(true);
    stateList = await LocationService.getState("1-India");
    stateLoading(false);
    update();
  }

  applyFilter() {
    fullAdd = [];
    switch (filterby.value) {
      case 0:
        fullAdd = [
          selectedPostal.value.name,
        ];

        break;
      case 1:
        fullAdd = [
          selectedCity.value.name,
        ];

        break;
      case 2:
        fullAdd = [
          selectedState.value.name,
        ];

        break;
      default:
    }
  }

  getSachiv(int level) async {
    String docId = selectedPostal.value.id;
    print("level initial");
    switch (level) {
      case 1:
        docId = selectedPostal.value.id;
        print("level 1");
        areaSachiv.value = await SachivService.fetchSachivId(docId: docId);
        break;
      case 2:
        docId = selectedCity.value.id;
        print("level 2");
        areaSachiv.value = await SachivService.fetchSachivId(docId: docId);
        break;
      case 3:
        docId = selectedState.value.id;
        print("level 3");
        areaSachiv.value = await SachivService.fetchSachivId(docId: docId);
        break;
      case 4:
        docId = "1-India";
        areaSachiv.value = await SachivService.fetchSachivId(docId: docId);
        print("level 4");
        break;
      default:
        print("level default");
        docId = selectedPostal.value.id;
        areaSachiv.value = await SachivService.fetchSachivId(docId: docId);
    }
    print(areaSachiv.value.name);
  }

  List<T> getRandomSublist<T>(List<T> list, int maxLength) {
    if (list.length <= maxLength) return list;
    list.shuffle(Random());
    return list.sublist(0, maxLength);
  }

  getPosts(level, {bool nextSet = false,}) async {
    print("ishwar: yash  level is..............: $level,");
    isLoading(true);

    // generating the base query
    try {
      late final Query baseQuery;

      // if we are not asking for next set then
      if (!nextSet) {
            // clearing the posts and the last doc reference
            postList.clear();
            adList.clear();
            lastDoc = null;
          } else {
            // if the last doc is already null, we can't give the next set
            if (lastDoc == null) {
              isLoading(false);
              return;
            }
          }

      var res;
      switch (level) {
            case 0:
              // getting the selected states
              final List selectedStates = getPrefValue(Keys.PREFERRED_STATES).isEmpty
                  ? []
                  : getRandomSublist(jsonDecode(getPrefValue(Keys.PREFERRED_STATES)), 30);

              // list to store the user ids of users/organizations that we are following
              List<String> userIdsOfUsersWeAreFollowing = [];

              if (!Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
                // grabbing the docs where the follower id matches the current user
                final docsWhereFollowerIdMatches = await FirebaseFirestore.instance
                    .collectionGroup(FOLLOWERS_DB)
                    .where(
                      'follower_id',
                      isEqualTo: getPrefValue(Keys.USERID),
                    )
                    .get();

                // going through each doc
                for (QueryDocumentSnapshot doc in docsWhereFollowerIdMatches.docs) {
                  // grabbing the followee id
                  final followeeId = (doc.data() as Map)['followee_id'];

                  // grabbing the user id and adding that to the list
                  userIdsOfUsersWeAreFollowing.add(followeeId);
                }
              }

          userIdsOfUsersWeAreFollowing = getRandomSublist(userIdsOfUsersWeAreFollowing, 30);

              print('ishwar: we following: $userIdsOfUsersWeAreFollowing $selectedStates');

              if (userIdsOfUsersWeAreFollowing.isEmpty) {
                baseQuery = FirebaseFirestore.instance
                    .collection(POST_DB)
                    .orderBy("createdAt", descending: true)
                    .where("full_add", arrayContainsAny: selectedStates);
              } else {
                baseQuery = FirebaseFirestore.instance
                    .collection(POST_DB)
                    .orderBy("createdAt", descending: true)
                .where(Filter.or(
                    Filter("full_add", arrayContainsAny: selectedStates),
                    Filter("user_id", whereIn: userIdsOfUsersWeAreFollowing)
                ))/*
                    .where("full_add", arrayContainsAny: selectedStates)
                    .where("user_id", whereIn: userIdsOfUsersWeAreFollowing)*/;
              }
                  // .where(
                  //   userIdsOfUsersWeAreFollowing.isNotEmpty
                  //       ? Filter.or(
                  //           Filter("full_add", arrayContainsAny: selectedStates),
                  //           Filter("user_id", whereIn: userIdsOfUsersWeAreFollowing),
                  //         )
                  //       : Filter("full_add", arrayContainsAny: selectedStates),
                  // );

              break;
            // FIXME: IF WE JUST SWITCHED TO NEW TAB, WE SHOULD IGNORE PREVIOUS TAB REQUEST THAT WAS ONGOING
            case 1:
              baseQuery = FirebaseFirestore.instance
                  .collection(POST_DB)
                  .orderBy('createdAt', descending: true)
                  .where("full_add", arrayContainsAny: [selectedPostal.value.name]);

              break;
            case 2:
              baseQuery = FirebaseFirestore.instance
                  .collection(POST_DB)
                  .orderBy('createdAt', descending: true)
                  .where("full_add", arrayContainsAny: [selectedCity.value.name]);
              break;
            case 3:
              baseQuery = FirebaseFirestore.instance
                  .collection(POST_DB)
                  .orderBy('createdAt', descending: true)
                  .where("full_add", arrayContainsAny: [selectedState.value.name]);
              break;
            case 4:
              baseQuery = FirebaseFirestore.instance
                  .collection(POST_DB)
                  .orderBy('createdAt', descending: true)
                  .where("show_level", arrayContains: 4);
              break;
            default:
          }

      // to hold the count of valid documents we found
      int validDocumentsCount = 0;

      // flag variable for the loop
      // if we are requesting next set, it should be false on initialization
      bool isFirst = !nextSet;

      while (validDocumentsCount < 5) {
            // if this is the first iteration, then load the first set
            if (isFirst) {
              try {
                res = await baseQuery.limit(limit).get();
                print("ishwar: ${(res as QuerySnapshot).docs.length}");
              } catch (err) {
                print("ishwar: $err");
              }
              isFirst = false;
            } else {
              // otherwise, load the next set
              try {
                res = await baseQuery.startAfterDocument(lastDoc!).limit(limit).get();
              } catch (err) {
                print("ishwar: $err");
              }
            }

            // if the docs are not empty, set the last doc
            lastDoc = res.docs.isEmpty ? null : res.docs.last;

            for (var element in res.docs) {
              // creating the post
              final post = PostModel.fromJson(element.data());

              print(post.showlevel);

              // if level is 0
              if (level == 0) {
                // valid documents are only the once where show_level doesn't contain level 1
                if (!post.showlevel.contains(1)) {
                  postList.add(post);
                  await addAdvertisement();
                  validDocumentsCount++;
                }
              } else {
                // if current document can be shown on this level, it is a valid document
                if (post.showlevel.contains(level)) {
                  postList.add(post);
                  await addAdvertisement();
                  validDocumentsCount++;
                }
              }
            }

            print("Post List: $postList");

            // if there is no last doc, break
            if (lastDoc == null) {
              break;
            }
          }
    } catch (e) {
      print("ishwar : yash: error on getPost: $e");
    }

    isLoading(false);
  }


//change by yg test: 16-5-25
 /* Future<void> getPosts(int level, {bool nextSet = false}) async {
    final requestId = Uuid().v4(); // Generate unique request ID
    _currentRequestId = requestId; // Store current request ID
    print("ishwar: yash: requestId: $requestId");

    isLoading(true);
    try {
      late final Query baseQuery;

      // Clear posts and lastDoc if not fetching next set
      if (!nextSet) {
        postList.clear();
        adList.clear();
        lastDoc = null;
      } else if (lastDoc == null) {
        isLoading(false);
        return;
      }

      // Build base query based on level
      switch (level) {
        case 0:
          final List selectedStates = getPrefValue(Keys.PREFERRED_STATES).isEmpty
              ? []
              : getRandomSublist(jsonDecode(getPrefValue(Keys.PREFERRED_STATES)), 30);

          List<String> userIdsOfUsersWeAreFollowing = [];
          if (!Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
            final docs = await FirebaseFirestore.instance
                .collectionGroup(FOLLOWERS_DB)
                .where('follower_id', isEqualTo: getPrefValue(Keys.USERID))
                .get();
            userIdsOfUsersWeAreFollowing = docs.docs
                .map((doc) => (doc.data() as Map)['followee_id'] as String)
                .toList();
            userIdsOfUsersWeAreFollowing = getRandomSublist(userIdsOfUsersWeAreFollowing, 30);
          }

          if (userIdsOfUsersWeAreFollowing.isEmpty) {
            baseQuery = FirebaseFirestore.instance
                .collection(POST_DB)
                .orderBy("createdAt", descending: true)
                .where("full_add", arrayContainsAny: selectedStates);
          } else {
            baseQuery = FirebaseFirestore.instance
                .collection(POST_DB)
                .orderBy("createdAt", descending: true)
                .where(Filter.or(
              Filter("full_add", arrayContainsAny: selectedStates),
              Filter("user_id", whereIn: userIdsOfUsersWeAreFollowing),
            ));
          }
          break;
        case 1:
          baseQuery = FirebaseFirestore.instance
              .collection(POST_DB)
              .orderBy('createdAt', descending: true)
              .where("full_add", arrayContainsAny: [selectedPostal.value.name]);
          break;
        case 2:
          baseQuery = FirebaseFirestore.instance
              .collection(POST_DB)
              .orderBy('createdAt', descending: true)
              .where("full_add", arrayContainsAny: [selectedCity.value.name]);
          break;
        case 3:
          baseQuery = FirebaseFirestore.instance
              .collection(POST_DB)
              .orderBy('createdAt', descending: true)
              .where("full_add", arrayContainsAny: [selectedState.value.name]);
          break;
        case 4:
          baseQuery = FirebaseFirestore.instance
              .collection(POST_DB)
              .orderBy('createdAt', descending: true)
              .where("show_level", arrayContains: 4);
          break;
      }

      int validDocumentsCount = 0;
      bool isFirst = !nextSet;
      const int limit = 10;

      while (validDocumentsCount < 5 && _currentRequestId == requestId) {
        var res;
        if (isFirst) {
          res = await baseQuery.limit(limit).get();
          isFirst = false;
        } else {
          res = await baseQuery.startAfterDocument(lastDoc!).limit(limit).get();
        }

        // Ignore results if a new request has started
        if (_currentRequestId != requestId) {
          print("ishwar: Ignoring outdated request: $requestId");
          return;
        }

        lastDoc = res.docs.isEmpty ? null : res.docs.last;

        for (var element in res.docs) {
          final post = PostModel.fromJson(element.data());
          if (level == 0) {
            if (!post.showlevel.contains(1)) {
              postList.add(post);
              await addAdvertisement();
              validDocumentsCount++;
            }
          } else {
            if (post.showlevel.contains(level)) {
              postList.add(post);
              await addAdvertisement();
              validDocumentsCount++;
            }
          }
        }

        if (lastDoc == null) break;
      }

      update(); // Trigger UI update
    } catch (e) {
      print("ishwar: yash: error on getPost: $e");
    } finally {
      if (_currentRequestId == requestId) {
        isLoading(false);
      }
    }
  }*/

}
