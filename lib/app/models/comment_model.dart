// To parse this JSON data, do
//
//     final commentModel = commentModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

// CommentModel commentModelFromJson(String str) =>
//     CommentModel.fromJson(json.decode(str));

String commentModelToJson(CommentModel data) => json.encode(data.toJson());

class CommentModel {
  CommentModel({
    required this.postId,
    required this.commentId,
    required this.userId,
    required this.createdAt,
    required this.comment,
  });

  String commentId;
  String postId;
  String userId;
  Timestamp createdAt;
  String comment;

  factory CommentModel.fromJson(String id, Map<String, dynamic> json) =>
      CommentModel(
        commentId: id,
        postId: json["post_id"],
        userId: json["user_id"],
        createdAt: json["createdAt"],
        comment: json["comment"],
      );
  
  Map<String, dynamic> toJson() => {
        "post_id": postId,
        "user_id": userId,
        "createdAt": createdAt,
        "comment": comment,
      };
}
