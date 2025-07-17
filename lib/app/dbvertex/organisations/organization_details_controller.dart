import 'dart:async';

import 'package:chunaw/app/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../models/followers_model.dart';
import '../../service/collection_name.dart';
import '../../service/user_service.dart';

class OrganizationDetailsController extends GetxController {
  final posts = Rx<List<PostModel>?>([]);
  DocumentSnapshot? lastDocument;
  String? lastOrganizationId;
  bool isFetching = false;
  bool canScrollMore = true;

  final iAdmin = Rx<bool?>(null);

  // final locationId = Rx<String?>(null);

  final totalFollowers = Rx<int?>(null);
  final joinStatus = Rx<String?>(null);
  final isPrivate = Rx<bool?>(null);
  String myFollowId = '';
  final followers = RxList(<FollowerModel>[]);
  StreamSubscription? dataFetcher;
  String? admin;

  Future<void> fetchPosts(String organizationID) async {
    lastOrganizationId = organizationID;
    if (isFetching || !canScrollMore) return;
    isFetching = true;
    dataFetcher?.cancel();

    Query query = FirebaseFirestore.instance
        .collection(POST_DB)
        .where('user_id', isEqualTo: organizationID)
        .orderBy('createdAt', descending: true)
        .limit(5);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }
    bool isManual = true;

    try {
      dataFetcher = query.snapshots().listen(
        (data) {
          if (data.docs.isNotEmpty) {
            lastDocument = data.docs.last;

            final newPosts = data.docs
                .map((doc) => PostModel.fromJson(
                    (doc.data() ?? {}) as Map<String, dynamic>))
                .toList();
            if (isManual) {
              posts.value = [...?posts.value, ...newPosts];
            } else {
              posts.value = newPosts; /*[...?posts.value, ...newPosts];*/
            }

            isManual = false;
          } else {
            canScrollMore = false;
          }
        },
      );
    } catch (e) {
      print('Error fetching posts: $e');
    } finally {
      isFetching = false;
    }
  }

  void reload() {
    canScrollMore = true;
    posts.value?.clear();
    lastDocument = null;
    fetchPosts(lastOrganizationId!);
  }

  void deletePost(PostModel model) {
    posts.value?.remove(model);
    posts.refresh();
    if (5 > (posts.value?.length ?? 0)) {
      posts.value?.clear();
      lastDocument = null;
      fetchPosts(lastOrganizationId!);
    }
  }

  Future<void> sendRequest(String organizationId) async {
    String? savedStatus = joinStatus.value;
    joinStatus.value = null;

    try {
      final data = {
        'org_id': organizationId,
        'user_id': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': DateTime.now(),
        'admin': admin
      };
      final reference =
          FirebaseFirestore.instance.collection('organization_req').doc();

      await reference.set(data);

      joinStatus.value = 'request';
    } catch (error) {
      print("ishwar:new: $error");
    }
    joinStatus.value ??= savedStatus;
  }

  Future<void> cancelRequest(String organizationId) async {
    String? savedStatus = joinStatus.value;
    joinStatus.value = null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('organization_req')
          .where('org_id', isEqualTo: organizationId)
          .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first;
        await data.reference.delete();
        joinStatus.value = 'user';
      }
    } catch (error) {
      print("ishwar:new: $error");
    }

    joinStatus.value ??= savedStatus;
  }

  void join(String organizationId) {
    if (isPrivate.value == null) {
      return;
    }

    if (isPrivate.value == true) {
      sendRequest(organizationId);
      return;
    }

    final followerModel = FollowerModel(
        followerId: FirebaseAuth.instance.currentUser!.uid,
        followeeId: organizationId,
        createdAt: Timestamp.now());
    UserService.addFollowers(followerModel: followerModel);
  }
}
