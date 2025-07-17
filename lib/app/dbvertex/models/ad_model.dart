import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String uid;
  final String title;
  final String? actionUrl;
  final String description;
  final String? videoUrl;
  final List<String> images;
  final List<String> scope;
  final DateTime createdAt;
  final int proposedAmount;
  int generatedViews;
  final int targetViews;
  final String paymentId;
  final double randomness;
  final double priority;
  final String scopeSuffix;

   AdModel(this.id, {
    required this.uid,
    required this.title,
    required this.actionUrl,
    required this.description,
    required this.videoUrl,
    required this.images,
    required this.scope,
    required this.createdAt,
    required this.proposedAmount,
    required this.generatedViews,
    required this.targetViews,
    required this.paymentId,
    required this.randomness,
    required this.priority,
    required this.scopeSuffix
});

  factory AdModel.empty() {
    return AdModel(
        '_',
        uid: 'uid',
        title: 'title',
        actionUrl: 'actionUrl',
        description: 'description',
        videoUrl: 'videoUrl',
        images: [],
        scope: [],
        createdAt: DateTime.now(),
        proposedAmount: 0,
        generatedViews: 0,
        targetViews: 0,
        paymentId: '',
        randomness: 0.0,
        priority: 0.0,
      scopeSuffix: ''
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      "id": id,
      "uid": uid,
      "title": title,
      "action_url": actionUrl,
      'description': description,
      "video_url": videoUrl,
      "images": images,
      "scope": scope,
      "created_at": createdAt,
      'target_views': targetViews,
      'proposed_amount': proposedAmount,
      'generated_views': generatedViews,
      'payment_id': paymentId,
      'randomness': randomness,
      'priority': priority,
      'scope_suffix': scopeSuffix
    };
    return json;
  }
  
  factory AdModel.fromJson(Map json) {
    return AdModel(
        json['id'] ?? '',
        uid: json['uid']??'',
        title: json['title']??'',
        actionUrl: json['action_url'],
        description: json['description']??'',
        videoUrl: json['video_url'],
        images: List<String>.from(json['images'] ?? []),
        scope: List<String>.from(json['scope'] ?? []),
        createdAt: json['created_at'] is Timestamp || json['created_at'] == null ? ((json['created_at'] ?? Timestamp.now()) as Timestamp).toDate() : Timestamp(json['created_at']['_seconds'], json['created_at']['_nanoseconds']).toDate(),
      proposedAmount: json['proposed_amount'] ?? 0,
        generatedViews: json['generated_views'] ?? 0,
      targetViews: json['target_views'] ?? 0,
      paymentId: json['payment_id'] ?? 'none',
      randomness: json['randomness'] ?? 0.0,
      priority: json['priority'] ?? 0.0,
      scopeSuffix: json['scope_suffix']
    );
  }
}