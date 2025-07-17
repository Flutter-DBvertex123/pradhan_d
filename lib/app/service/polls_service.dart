import 'package:chunaw/app/controller/home/home_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PollsService {
  static final HomeController homeController = Get.put(HomeController());

  // method to load the polls for a postal
  static Stream<QuerySnapshot> getPollsForPostal() {
    // getting the ids
    final locationIds = getLocationIds();

    // creating the query
    return FirebaseFirestore.instance
        .collection('polls')
        .where('postal', isEqualTo: locationIds[LocationId.postalId])
        .where('city', isEqualTo: locationIds[LocationId.cityId])
        .where('state', isEqualTo: locationIds[LocationId.stateId])
        .where('country', isEqualTo: locationIds[LocationId.countryId])
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // method to load the polls for a city
  static Stream<QuerySnapshot> getPollsForCity() {
    // getting the ids
    final locationIds = getLocationIds();

    // creating the query
    return FirebaseFirestore.instance
        .collection('polls')
        .where('postal', isEqualTo: '')
        .where('city', isEqualTo: locationIds[LocationId.cityId])
        .where('state', isEqualTo: locationIds[LocationId.stateId])
        .where('country', isEqualTo: locationIds[LocationId.countryId])
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // method to load the polls for a state
  static Stream<QuerySnapshot> getPollsForState() {
    // getting the ids
    final locationIds = getLocationIds();

    // creating the query
    return FirebaseFirestore.instance
        .collection('polls')
        .where('postal', isEqualTo: '')
        .where('city', isEqualTo: '')
        .where('state', isEqualTo: locationIds[LocationId.stateId])
        .where('country', isEqualTo: locationIds[LocationId.countryId])
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // method to load the polls for a country
  static Stream<QuerySnapshot> getPollsForCountry() {
    // getting the ids
    final locationIds = getLocationIds();

    // creating the query
    return FirebaseFirestore.instance
        .collection('polls')
        .where('postal', isEqualTo: '')
        .where('city', isEqualTo: '')
        .where('state', isEqualTo: '')
        .where('country', isEqualTo: locationIds[LocationId.countryId])
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // method to get the ids
  static Map getLocationIds() {
    // grabbing the data from home controller
    final homeControllerPostal = homeController.selectedPostal.value;
    final homeControllerCity = homeController.selectedCity.value;
    final homeControllerState = homeController.selectedState.value;

    // grabbing the data from prefs only if home controller doesn't have any active filters. If active filters are there, grab their value instead
    final postalId = homeControllerPostal.name == 'Select Postal'
        ? locationModelFromJson(getPrefValue(Keys.POSTAL)).id
        : homeControllerPostal.id;
    final cityId = homeControllerCity.name == 'Select City'
        ? locationModelFromJson(getPrefValue(Keys.CITY)).id
        : homeControllerCity.id;
    final stateId = homeControllerState.name == 'Select State'
        ? locationModelFromJson(getPrefValue(Keys.STATE)).id
        : homeControllerState.id;
    final countryId = locationModelFromJson(getPrefValue(Keys.COUNTRY)).id;

    return {
      LocationId.postalId: postalId,
      LocationId.cityId: cityId,
      LocationId.stateId: stateId,
      LocationId.countryId: countryId,
    };
  }
}

enum LocationId {
  postalId,
  cityId,
  stateId,
  countryId,
}
