import 'package:chunaw/app/models/location_model.dart';

class UserModel {
  String name;
  String username;
  String phone;
  String userdesc;
  String fcm;
  LocationModel state;
  LocationModel city;
  LocationModel country;
  LocationModel preferredElectionLocation;
  String image;
  String affiliateImage;
  String affiliateText;
  LocationModel postal;
  String id;
  dynamic level;
  int admin;
  String? oadmin;
  bool isOrganization;
  String organizationAddress;
  int upvoteCount;

  UserModel({
    required this.name,
    required this.username,
    required this.phone,
    required this.userdesc,
    required this.state,
    required this.city,
    required this.country,
    required this.id,
    required this.level,
    required this.image,
    required this.affiliateImage,
    required this.affiliateText,
    required this.admin,
     this.oadmin,
    required this.preferredElectionLocation,
    this.fcm = "",
    required this.postal,
    required this.isOrganization,
    required this.organizationAddress,
    required this.upvoteCount,
  });
  factory UserModel.empty() => UserModel(
        name: "",
        username: "",
        userdesc: "",
        phone: "",
        state: LocationModel.empty(),
        city: LocationModel.empty(),
        country: LocationModel.empty(),
        id: "",
        fcm: "",
        image: "",
        postal: LocationModel.empty(),
        preferredElectionLocation: LocationModel.empty(),
        level: "",
        admin: 0,
        affiliateImage: '',
        affiliateText: '',
        isOrganization: false,
        organizationAddress: '',
        upvoteCount: 0,
      );
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json["id"],
        state: LocationModel.fromJson(json["state"]),
        fcm: json["fcm"],
        userdesc: json["userdesc"],
        level: json["level"],
        image: json["image"],
        affiliateImage: json['affiliate_image'] ?? '',
        affiliateText: json['affiliate_text'] ?? '',
        city: LocationModel.fromJson(json["city"]),
        preferredElectionLocation: json['preferred_election_location'] != null
            ? LocationModel.fromJson(json['preferred_election_location'])
            : LocationModel.empty(),
        username: json["username"],
        country: LocationModel.fromJson(json["country"]),
        name: json["name"],
        phone: json["phone"] ?? "",
        postal: LocationModel.fromJson(json["postal"]),
        admin: json["admin"] ?? 0,
        oadmin: json["oadmin"],
        isOrganization: json['is_organization'] ?? false,
        organizationAddress: json['organization_address'] ?? '',
        upvoteCount: json['upvote_count'] ?? 0,
      );
  factory UserModel.specialModel(Map<String, dynamic> json) => UserModel(
        id: json["id"],
        state: LocationModel.empty(),
        fcm: json["fcm"] ?? "",
        userdesc: "",
        level: json["level"],
        image: json["image"],
        affiliateImage: json['affiliate_image'] ?? '',
        affiliateText: json['affiliate_text'] ?? '',
        city: LocationModel.empty(),
        username: json["username"] ?? "",
        country: LocationModel.empty(),
        preferredElectionLocation: LocationModel.empty(),
        name: json["name"] ?? "",
        phone: json["phone"] ?? "",
        postal: LocationModel.empty(),
        admin: 0,
        isOrganization: json['is_organization'] ?? false,
        organizationAddress: json['organization_address'] ?? '',
        upvoteCount: json['upvote_count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "state": state.toJson(),
        "fcm": fcm,
        "userdesc": userdesc,
        "level": level,
        "image": image,
        "oadmin": oadmin,
        "city": city.toJson(),
        "preferred_election_location": preferredElectionLocation.toJson(),
        "username": username,
        "country": country.toJson(),
        "name": name,
        "affiliate_image": affiliateImage,
        "affiliate_text": affiliateText,
        "is_organization": isOrganization,
        "organization_address": organizationAddress,
        'upvote_count': upvoteCount,
      };
  Map<String, dynamic> toSpecialJson() => {
        "id": id,
        "fcm": fcm,
        "userdesc": userdesc,
        "level": level,
        "image": image,
        "username": username,
        "name": name,
      };
}
