// To parse this JSON data, do
//
//     final commentModel = commentModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

// CommentModel commentModelFromJson(String str) =>
//     CommentModel.fromJson(json.decode(str));

String commentModelToJson(PradhanCommentModel data) =>
    json.encode(data.toJson());

class PradhanCommentModel {
  PradhanCommentModel({
    required this.locationId,
    required this.commentId,
    required this.userId,
    required this.createdAt,
    required this.comment,
  });

  String commentId;
  String locationId;
  String userId;
  Timestamp createdAt;
  String comment;

  factory PradhanCommentModel.fromJson(String id, Map<String, dynamic> json) =>
      PradhanCommentModel(
        commentId: id,
        locationId: json["location_id"],
        userId: json["user_id"],
        createdAt: json["createdAt"],
        comment: json["comment"],
      );

  Map<String, dynamic> toJson() => {
        "post_id": locationId,
        "user_id": userId,
        "createdAt": createdAt,
        "comment": comment,
      };
}
