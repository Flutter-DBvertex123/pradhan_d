// To parse this JSON data, do
//
//     final postModel = postModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'comment_model.dart';

PostModel postModelFromJson(String str) => PostModel.fromJson(json.decode(str));

String postModelToJson(PostModel data) => json.encode(data.toJson());

class PostModel {
  PostModel({
    required this.postId,
    required this.userId,
    required this.postDesc,
    this.postImage,
    this.backgroundMusic,
    required this.postImages,
    required this.postVideo,
    required this.createdAt,
    required this.level,
    required this.location,
    required this.likeCount,
    required this.upvoteCount,
    required this.commentsCount,
    required this.fullAdd,
    required this.showlevel,
    this.specialComment,
    required this.viewsCount,
    this.posterId,
  });

  String postId;
  String userId;
  String postDesc;
  String? postImage;
  String? backgroundMusic;
  List postImages;
  String postVideo;
  Timestamp createdAt;
  int level;
  int likeCount;
  int upvoteCount;
  int commentsCount;
  String location;
  List<String> fullAdd;
  List<int> showlevel;
  CommentModel? specialComment;
  int? viewsCount;
  String? posterId;

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        postId: json["post_id"],
        userId: json["user_id"],
        posterId: json["poster_id"],
        postDesc: json["post_desc"],
        postImage: json["post_image"],
        backgroundMusic: json["background_music"],
        postImages: json["post_image"] == null || json["post_image"].isEmpty
            ? json["post_images"] ?? []
            : [json["post_image"]],
        postVideo: json['post_video'] ?? '',
        createdAt: json["createdAt"],
        level: json["level"],
        location: json["location"],
        fullAdd: List<String>.from(json["full_add"].map((x) => x)),
        showlevel: json["show_level"] == null
            ? [json["level"]]
            : List<int>.from(json["show_level"].map((x) => x)),
        likeCount: json["like_count"],
        upvoteCount: json["upvote_count"],
        commentsCount: json["comments_count"],
        specialComment: json["special_comment"] != null
            ? CommentModel.fromJson("", json["special_comment"])
            : null,
            viewsCount: json['viewsCount'] ?? 0,
      );
  factory PostModel.empty() => PostModel(
        postId: "",
        userId: "",
        postDesc: "",
        postImage: "",
        postImages: [],
        postVideo: '',
        createdAt: Timestamp.now(),
        level: 1,
        location: "",
        fullAdd: [],
        showlevel: [],
        likeCount: 0,
        upvoteCount: 0,
        commentsCount: 0,
        specialComment: null,
        viewsCount: 0,
      );

  Map<String, dynamic> toJson({bool removeCreatedAt = false}) {
    final json = {
      "post_id": postId,
      "user_id": userId,
      "poster_id": posterId,
      "post_desc": postDesc,
      "post_images": postImages,
      "background_music": backgroundMusic,
      'post_video': postVideo,
      "createdAt": createdAt,
      "level": level,
      "location": location,
      "full_add": List<dynamic>.from(fullAdd.map((x) => x)),
      "show_level": List<dynamic>.from(showlevel.map((x) => x)),
      "like_count": likeCount,
      "comments_count": commentsCount,
      "upvote_count": upvoteCount,
      "views_count": viewsCount,
    };

    // removing the createdAt key only if updating
    if (removeCreatedAt) {
      json.remove('createdAt');
    }

    return json;
  }
}
