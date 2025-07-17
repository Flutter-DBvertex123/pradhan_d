import 'dart:math';

import 'package:chunaw/app/models/followers_model.dart';
import 'package:chunaw/app/models/post_model.dart';
import 'package:chunaw/app/models/user_model.dart';
import 'package:chunaw/app/service/pradhan_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../service/collection_name.dart';

class OrganisationVotingController extends GetxController {
  final isLoading = false.obs;
  final userList = Rx(<UserModel>[]);
  final voting = false.obs;

  final String organizationID;

  OrganisationVotingController({required this.organizationID});

  @override
  Future<void> onInit() async {
    voting.value = await PradhanService.getVoting(docId: organizationID);
    initialize();
    super.onInit();
  }

  Future<void> initialize() async {
    isLoading.value = true;

    List<PostModel> posts = [];

    try {
      final pSnapshot = await FirebaseFirestore.instance
        .collection(POST_DB)
        .where('user_id', isEqualTo: organizationID).get();

      posts = pSnapshot.docs.map((e) => PostModel.fromJson(e.data())).toList(growable: false);
    } catch (error) {
      print("ishwar:voting error while getting posts $error");
    }
    
    final Map<String, Map<String, dynamic>> usersWithVoteCounts = {};
    
    for (final post in posts) {
      String posterId = post.posterId ?? post.userId;
      
      if (usersWithVoteCounts.containsKey(posterId)) {
        usersWithVoteCounts[posterId]?['vote'] += post.upvoteCount;
      } else {
        try {
          final userSnapshot = await FirebaseFirestore.instance.collection(USER_DB).doc(posterId).get();
          usersWithVoteCounts[posterId] = {
            'vote': post.upvoteCount,
            'pradhan': UserModel.fromJson(userSnapshot.data()??{})
          };
        } catch (error) {
          print("ishwar:voting error while getting user $posterId");
        }
      }
    }
    final sortedUsers = usersWithVoteCounts.entries.map((e) {
      (e.value['pradhan'] as UserModel).upvoteCount = e.value['vote'];
      return e;
    }).toList();
    sortedUsers.sort((a, b) => b.value['vote'].compareTo(a.value['vote']));
    userList.value = sortedUsers.map<UserModel>((e) => e.value['pradhan']).toList();
    isLoading.value = false;
  }
}