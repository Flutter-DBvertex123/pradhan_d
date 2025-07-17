import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../service/collection_name.dart';
import '../../utils/app_pref.dart';
import '../models/donation_details_model.dart';

class DonationsManager {
  static final DonationsManager _instance = DonationsManager._internal();

  factory DonationsManager() {
    return _instance;
  }

  DonationsManager._internal();
  Future<DonationDetailsModel> getDonationsForScope({String? scopeSuffix, bool? returnDonors, bool? groupContributors}) async {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getDonationDetailsForScope');

    print("ishwar: getDonationsForScope: ${scopeSuffix??(await getScopeSuffix())}");
    try {
      // Call the cloud function with parameters
      final response = await callable.call({
        'scope_suffix': scopeSuffix??(await getScopeSuffix()),
        'return_donors': returnDonors ?? true,
      });

      // Parse the response data
      var responseBody = response.data;

      print("ishwar: Response: $responseBody");

      for (var data in (responseBody as Map).entries) {
        print("ishwar: shared - $data");

      }

      // Deserialize the response into the DonationDetailsModel
      DonationDetailsModel donationDetails = DonationDetailsModel.fromJson(responseBody);

      if (groupContributors??false) {
        return donationDetails.grouped();
      }

      // Return the donation details model
      return donationDetails;

    } catch (e) {
      print("ishwar: Error occurred: $e");
      throw Exception("Failed to fetch donation details: $e");
    }
  }

  Future<String> getScopeSuffix() async {

    var snapshot = await FirebaseFirestore.instance.collection(USER_DB).where('id', isEqualTo: Pref.getString(Keys.USERID)).get();
    var data = snapshot.docs.firstOrNull;

    final int userLevel = data?['level'] ?? 1;
    final Map postal = data?['postal'] ?? {};
    final Map city = data?['city'] ?? {};
    final Map country = data?['country'] ?? {};
    final Map state = data?['state'] ?? {};

    List<Map> scopeData = [postal, city, state, country].sublist(max(0, userLevel - 2)).reversed.toList();
    String scopeSuffix = scopeData[scopeData.length - 1]['id'] ?? '';

    return city['id'];
  }

}