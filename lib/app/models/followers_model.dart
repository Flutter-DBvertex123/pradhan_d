// To parse this JSON data, do
//
//     final followerModel = followerModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

FollowerModel followerModelFromJson(String str) =>
    FollowerModel.fromJson(json.decode(str));

String followerModelToJson(FollowerModel data) => json.encode(data.toJson());

class FollowerModel {
  String? id;
  String followerId;
  String followeeId;
  Timestamp createdAt;

  FollowerModel({
    required this.followerId,
    required this.followeeId,
    required this.createdAt,
    this.id,
  });

  factory FollowerModel.fromJson(Map<String, dynamic> json) => FollowerModel(
        id: json["id"],
        followerId: json["follower_id"],
        followeeId: json["followee_id"],
        createdAt: json["createdAt"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "follower_id": followerId,
        "followee_id": followeeId,
        "createdAt": createdAt,
      };
}
