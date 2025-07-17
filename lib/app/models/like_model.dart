// To parse this JSON data, do
//
//     final likeModel = likeModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

UpLikeModel likeModelFromJson(String str) =>
    UpLikeModel.fromJson(json.decode(str));

String likeModelToJson(UpLikeModel data) => json.encode(data.toJson());

class UpLikeModel {
  UpLikeModel({
    required this.postId,
    required this.userId,
    required this.postUserId,
    required this.createdAt,
  });

  String postId;
  String userId;
  String postUserId;
  Timestamp createdAt;

  factory UpLikeModel.fromJson(Map<String, dynamic> json) => UpLikeModel(
        postId: json["post_id"],
        userId: json["user_id"],
        createdAt: json["createdAt"],
        postUserId: json["post_user_id"] ?? "",
  );

  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "user_id": userId,
        "createdAt": createdAt,
        "post_user_id": postUserId
      };
}
