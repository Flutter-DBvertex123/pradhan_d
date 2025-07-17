import 'dart:convert';

import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  static Future<List<LocationModel>> getCountry() async {
    final QuerySnapshot result =
        await FirebaseFirestore.instance.collection(LOCATION_DB).get();
    final List<DocumentSnapshot<Object?>> documents = result.docs;
    if (documents.isNotEmpty) {
      List<LocationModel> list = [];
      for (var element in documents) {
        list.add(locationModelFromJson(jsonEncode(element.data())));
      }
      return list;
    } else {
      return [];
    }
  }

  static Future<List<LocationModel>> getState(String locId) async {
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(LOCATION_DB)
        .doc(locId)
        .collection(STATE_DB)
        .get();
    final List<DocumentSnapshot<Object?>> documents = result.docs;
    if (documents.isNotEmpty) {
      List<LocationModel> list = [];
      for (var element in documents) {
        list.add(locationModelFromJson(jsonEncode(element.data())));
      }
      return list;
    } else {
      return [];
    }
  }

  static Future<List<LocationModel>> getCity(
      String locId, String stateId) async {
    // print(stateId);
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(LOCATION_DB)
        .doc(locId)
        .collection(STATE_DB)
        .doc(stateId)
        .collection(CITY_DB)
        .get();

    final List<DocumentSnapshot<Object?>> documents = result.docs;
    // print(result.docs);
    if (documents.isNotEmpty) {
      List<LocationModel> list = [];
      for (var element in documents) {
        list.add(locationModelFromJson(jsonEncode(element.data())));
      }
      return list;
    } else {
      return [];
    }
  }

  static Future<List<LocationModel>> getPostal(
      String locId, String stateId, String cityID) async {
    // print(stateId);
    final QuerySnapshot result = await FirebaseFirestore.instance
        .collection(LOCATION_DB)
        .doc(locId)
        .collection(STATE_DB)
        .doc(stateId)
        .collection(CITY_DB)
        .doc(cityID)
        .collection(POSTAL_DB)
        .get();
    final List<DocumentSnapshot<Object?>> documents = result.docs;
    // print(result.docs);
    if (documents.isNotEmpty) {
      List<LocationModel> list = [];
      for (var element in documents) {
        list.add(locationModelFromJson(jsonEncode(element.data())));
      }
      return list;
    } else {
      return [];
    }
  }

  static Future<bool> addState(
      {required LocationModel locationModel, required String countryId}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(LOCATION_DB)
          .doc(countryId)
          .collection(STATE_DB)
          .doc(locationModel.id)
          .set(locationModel.toJson());
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> addCity(
      {required LocationModel locationModel,
      required String countryId,
      required String stateId}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(LOCATION_DB)
          .doc(countryId)
          .collection(STATE_DB)
          .doc(stateId)
          .collection(CITY_DB)
          .doc(locationModel.id)
          .set(locationModel.toJson());
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }

  static Future<bool> addPostal(
      {required LocationModel locationModel,
      required String countryId,
      required String stateId,
      required String cityId}) async {
    try {
      // String id = FirebaseFirestore.instance.collection(POST_DB).doc(likeModel.postId).collection(LIKE_DB).

      await FirebaseFirestore.instance
          .collection(LOCATION_DB)
          .doc(countryId)
          .collection(STATE_DB)
          .doc(stateId)
          .collection(CITY_DB)
          .doc(cityId)
          .collection(POSTAL_DB)
          .doc(locationModel.id)
          .set(locationModel.toJson());
      return true;
    } catch (e) {
      print(e);
      longToastMessage("Try again");
      return false;
    }
  }
}
