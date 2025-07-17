import 'package:cloud_firestore/cloud_firestore.dart';

class DonationDetailsModel {
  final double totalDonatedAmount;
  final double usedAmount;
  final double totalDistanceProvided;
  late final List<DonorModel> donors;

  int get donorsLength => donors.map((donor) => donor.id).toSet().length;

  DonationDetailsModel(this.totalDonatedAmount, this.usedAmount, this.totalDistanceProvided, [List<DonorModel>? donors]) {
    this.donors = donors ?? [];
  }

  DonationDetailsModel grouped() {
    Map<String, DonorModel> donorsList = {};
    Map<String, DateTime> dates = {};

    for (var donor in donors) {
      if (donorsList.containsKey(donor.id)) {
        // Update the total donated amount if the donor exists
        donorsList[donor.id]?.amount += donor.amount;

        // Keep the most recent date for each donor
        if (donor.datetime.isAfter(donorsList[donor.id]?.datetime ?? DateTime(0))) {
          donorsList[donor.id]?.datetime = donor.datetime;
        }
      } else {
        // Add new donor to the list
        donorsList[donor.id] = donor;
      }
    }

    // Return the updated DonationDetailsModel with combined data
    return DonationDetailsModel(
      totalDonatedAmount,
      usedAmount,
      totalDistanceProvided,
      donorsList.values.toList(),
    );
  }

  // Named constructor for creating an instance from JSON
  DonationDetailsModel.fromJson(Map<dynamic, dynamic> json)
      : totalDonatedAmount = json['totalFundInCampaign']?.toDouble() ?? 0.0,
        usedAmount = json['usedFundFromCampaign']?.toDouble() ?? 0.0,
        totalDistanceProvided = json['totalRideProvided']?.toDouble() ?? 0.0 {
    if (json['donors'] != null) {
      donors = (json['donors'] as List)
          .map((donorJson) => DonorModel.fromJson(donorJson))
          .toList();
    } else {
      donors = [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFundInCampaign': totalDonatedAmount,
      'usedFundFromCampaign': usedAmount,
      'donors': donors.map((donor) => donor.toJson()).toList(),
    };
  }
}

class DonorModel {
  final String donorName;
  final String id;
  final String profileImage;
  double amount;
  DateTime datetime;

  DonorModel(this.donorName, this.id, this.profileImage, this.amount, this.datetime);

  // Named constructor for creating an instance from JSON
  DonorModel.fromJson(Map<dynamic, dynamic> json)
      : donorName = json['name'] ?? 'Unknown Donor',
        id = json['id'] ?? '',
        profileImage = json['profilePhoto'] ?? '',
        amount = json['totalDonated']?.toDouble() ?? 0.0,
        datetime = tryParseDate(json['datetime']);

  Map<String, dynamic> toJson() {
    return {
      'name': donorName,
      'id': id,
      'profilePhoto': profileImage,
      'totalDonated': amount,
      'datetime': datetime.toIso8601String(), // You can return it as a string or keep it as Timestamp if needed
    };
  }

  // Helper method to safely parse the date from Firestore's Timestamp
  static DateTime tryParseDate(dynamic json) {
    try {
      return (json is Timestamp) ? json.toDate() : (json is Map) ? Timestamp(json['_seconds'], json['_nanoseconds']).toDate() : DateTime.parse(json);
    } catch (error) {
      print("ishwar: Error parsing date: $error");
      return DateTime.now();
    }
  }
}
