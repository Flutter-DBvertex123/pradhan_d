// import 'dart:math';
// import 'package:chunaw/app/dbvertex/transfer_to_campaign_fund_screen.dart';
// import 'package:chunaw/app/dbvertex/update_bank_details.dart';
// import 'package:chunaw/app/dbvertex/withdraw_breakdown.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:screenshot/screenshot.dart';
//
// import '../controller/common/loading_controller.dart';
// import '../service/collection_name.dart';
// import '../utils/app_bar.dart';
// import '../utils/app_colors.dart';
// import '../utils/app_pref.dart';
// import '../widgets/app_toast.dart';
// import 'add_withdraw_request_screen.dart';
// import 'ishwar_constants.dart';
//
// import 'package:timeago/timeago.dart' as timeago;
//
// class NewWithdrawScreen extends StatefulWidget {
//   const NewWithdrawScreen({super.key});
//   @override
//   State<StatefulWidget> createState() => NewWithdrawState();
// }
//
// class NewWithdrawState extends State<NewWithdrawScreen> {
//   LoadingController loadingcontroller = Get.put(LoadingController());
//
//   int? totalViewsGeneratedByPradhaan;
//   double? pradhaanRevenue;
//   double?  pradhaanRemainingBalance;
//
//   bool isLoading = true;
//   bool isSearching = false;
//
//
//   Future<bool> getMyRevenueDetails() async {
//     try {
//
//       final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getRevenueDetailsForPradhaan');
//       final response = await callable.call({
//         "pradhaan_id": FirebaseAuth.instance.currentUser?.uid
//       });
//
//       var responseBody = response.data;
//       print("ishwar: $responseBody");
//
//
//       setState(() {
//         totalViewsGeneratedByPradhaan = responseBody['totalViewsGeneratedByPradhaan'] ?? 0;  // Only for the specific pradhaan
//         pradhaanRevenue = double.tryParse((responseBody['pradhaanRevenue']??0).toString()) ?? 0.0;
//         pradhaanRemainingBalance = double.tryParse((responseBody['pradhaanRemainingBalance'] ?? 0.0).toString()) ?? 0.0;
//       });
//       return true;
//     } catch (_) {
//       longToastMessage('Failed to load revenue details');
//       setState(() {
//         totalViewsGeneratedByPradhaan = null;  // Only for the specific pradhaan
//         pradhaanRevenue = null;
//         pradhaanRemainingBalance = null;
//       });
//       print("ishwar: getting data failed: $_");
//       return false;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBarCustom(
//         leadingBack: true,
//         title: 'Your Account',
//         elevation: 0,
//       ),
//       body: FutureBuilder(
//           future: FirebaseFirestore.instance.collection(USER_DB).where('id', isEqualTo: Pref.getString(Keys.USERID)).get(),
//           builder: (context, snapshot) {
//             final data = snapshot.data?.docs.firstOrNull?.data();
//
//             if (data == null) {
//               return Center(
//                 child: CircularProgressIndicator(color: AppColors.primaryColor,),
//               );
//             }
//
//             final String profileImage = data['image'] ?? '';
//             final String name = data['name'] ?? '';
//
//
//             final int userLevel = data['level'] ?? 1;
//             final Map postal = data['postal'] ?? {};
//             final Map city = data['city'] ?? {};
//             final Map country = data['country'] ?? {};
//             final Map state = data['state'] ?? {};
//
//             List<Map> scopeData = [postal, city, state, country].sublist(max(0, userLevel - 1)).reversed.toList();
//             String scopeSuffix = scopeData[scopeData.length - 1]['id'] ?? '';
//             String scopeSuffixName = scopeData[scopeData.length - 1]['name'] ?? '';
//             // List<String> scope = scopeData.map<String>((val) => val['name']).toList();
//
//             if (pradhaanRevenue == null) {
//               getMyRevenueDetails();
//             }
//           return NestedScrollView(
//             headerSliverBuilder: (context, innerBoxIsScrolled) {
//               return isSearching ? [] : [
//
//
//                 FutureBuilder(
//                     future: FirebaseFirestore.instance.collection(BANK_DETAILS_DB).doc(FirebaseAuth.instance.currentUser?.uid).get(),
//                     builder: (context, accountSnapshot) {
//                       final detailsExists = (accountSnapshot.data?.exists ?? false) && accountSnapshot.data!.data()!.keys.every((key) => [
//                         'bank_name',
//                         'account_number',
//                         'ifsc_number',
//                         'bank_address',
//                         'your_name'
//                       ].contains(key));
//
//                       return _buildInfoBubble(pradhaanRemainingBalance??0, 'Your balance', Icons.account_balance_wallet, accountSnapshot.data == null ? 'Loading...' : detailsExists ? 'Update Bank Details' : 'Add Bank Details', accountSnapshot.data == null ? null : () async {
//                         if (0 >= (pradhaanRevenue??0)) {
//                           longToastMessage('You are not eligible for this option as you haven\'t earned yet.');
//                           return;
//                         }
//                         Navigator.of(context).push(MaterialPageRoute(builder: (context) => UpdateBankDetails()));
//                       }, (pradhaanRevenue ?? 0)  > 0 ? AppColors.gradient1 : Colors.grey, 6);
//                     },
//                 ),
//                 _buildInfoBubble((pradhaanRevenue??0) - (pradhaanRemainingBalance ?? 0), 'Your total earning', Icons.monetization_on, 'Breakdown', () {
//                   Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawBreakdown()));
//                 }),
//                 // _buildInfoBubble('Free Auto Campaign', 'Click here to contribute', Icons.local_taxi_sharp, 'Contribute', () {
//                 //   Navigator.of(context).push(MaterialPageRoute(builder: (context) => TransferToCampaignScreen(() => setState(() => pradhaanRevenue = null), scopeSuffix: scopeData.lastOrNull?['id'] ?? '', title: 'Pradhaan Contribution',)));
//                 // }, null),
//                 // _buildInfoBubble(20.0, 'Used free auto fund in your area', Icons.done_outline_rounded),
//               ];
//             },
//             body: StreamBuilder(
//                 stream: FirebaseFirestore.instance
//                     .collection(TRANSACTION_HISTORY)
//                     .where('uid', isEqualTo: Pref.getString(Keys.USERID))
//                     .orderBy('createdAt', descending: true)
//                 // .collection(PRADHAN_PAYOUTS)
//                 //     .where('user_id', isEqualTo: Pref.getString(Keys.USERID))
//                 //     .orderBy('created_at', descending: true)
//                     .snapshots(),
//               builder: (context, snapshot) {
//                 return snapshot.data == null || snapshot.data!.docs.isEmpty ? Container(
//                   color: Theme.of(context).colorScheme.surface,
//                   child: Padding(
//                     padding: const EdgeInsets.only(top: 6),
//                     child: Container(
//                       color: Colors.white,
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Icon(Icons.hourglass_empty, color: Colors.grey, size: MediaQuery.sizeOf(context).width * 0.1),
//                           SizedBox(height: 16),
//                           Text(
//                               'No Activity',
//                             style: TextStyle(
//                               color: Colors.grey,
//                               fontSize: 17,
//                               fontWeight: FontWeight.bold
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ) : TransactionListPage(snapshot.data!.docs, (isSearching) {
//                   setState(() {
//                     this.isSearching = isSearching;
//                   });
//                 }, isSearching);
//               }
//             ),
//           );
//         }
//       )
//     );
//   }
//
//
//   _buildInfoBubble(dynamic value, String title, [IconData? icon, String? actionLabel, VoidCallback? onPressed, Color? buttonBackgroundColor, double extraTopPadding = 0]) {
//     return SliverAppBar(
//       automaticallyImplyLeading: false,
//       expandedHeight: (MediaQuery.sizeOf(context).width * (actionLabel == 'Contribute' ? 0.335 : 0.3)),
//       collapsedHeight: MediaQuery.sizeOf(context).width * 0.28,
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       surfaceTintColor: Theme.of(context).colorScheme.surface,
//       flexibleSpace: Card(
//         color: Colors.white,
//         elevation: 0,
//         margin: EdgeInsets.all(3).copyWith(top: 3 + extraTopPadding),
//         child: Center(
//           child: ListTile(
//             contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//             leading: icon != null ? Icon(
//                 icon,
//                 color: Colors.grey
//             ) : null,
//             title: Text(
//               value is double ? value.toStringAsFixed(1) : value.toString(),
//               style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18
//               ),
//             ),
//             trailing: actionLabel != null ? Card(
//               elevation: 0,
//               color: buttonBackgroundColor ?? AppColors.gradient1,
//               clipBehavior: Clip.hardEdge,
//               child: InkWell(
//                 onTap: onPressed,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                   child: Text(
//                     actionLabel,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14
//                     ),
//                   ),
//                 ),
//               ),
//             ) : null,
//             subtitle: Text(
//               title,
//               style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 13
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
// }
//
// class TransactionListPage extends StatefulWidget {
//   final List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions;
//   final Function(bool isSearching) onSearchStateChanges;
//   final bool isSearching;
//
//   const TransactionListPage(this.transactions, this.onSearchStateChanges, this.isSearching, {super.key});
//
//   @override
//   State<StatefulWidget> createState() => TransactionListState();
//
// }
//
// class TransactionListState extends State<TransactionListPage> {
//   bool isSearching = false;
//   String searchFilter = '';
//
//   @override
//   void initState() {
//     isSearching = widget.isSearching;
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var filteredTransactions = widget.transactions.map<Map<String, dynamic>>((snapshot) {
//       return snapshot.data();
//     }).toList();
//     if (isSearching) {
//       filteredTransactions = filteredTransactions.where((data) {
//         return searchFilter.isEmpty || "${data['note']}".toLowerCase().contains(searchFilter);
//         // return searchFilter.isEmpty ||
//         //     "${data['pradhan_name']} ${data['location']['name']} ${data['remark']}".toLowerCase().contains(searchFilter);
//       }).toList();
//     }
//
//     return SingleChildScrollView(
//       child: Container(
//         color: Theme.of(context).colorScheme.surface,
//         child: Card(
//           elevation: 0,
//           color: Colors.white,
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.only(
//                   topRight: Radius.circular(25),
//                   topLeft: Radius.circular(25)
//               )
//           ),
//           margin: EdgeInsets.only(top: 8),
//           child: Column(
//               children: List.generate(filteredTransactions.length + 1, (index) {
//                 if (index == 0) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 18).copyWith(top: 20, right: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: isSearching ? TextField(
//                             onChanged: (val) => setState(() {
//                               searchFilter = val.trim().toLowerCase();
//                             }),
//                             decoration: InputDecoration(
//                                 hintText: 'Search',
//                                 enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.grey.withOpacity(0.4))),
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.grey.withOpacity(0.4))),
//                                 focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.grey.withOpacity(0.4))),
//                                 contentPadding: EdgeInsets.symmetric(horizontal: 12)
//                             ),
//                           ) : Text(
//                             'Transaction History',
//                             style: TextStyle(
//                                 fontSize: 18,
//                                 color: Colors.black54
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: () {
//                             searchFilter = '';
//                             isSearching = !isSearching;
//                             widget.onSearchStateChanges(isSearching);
//                           },
//                           icon: Icon(
//                               isSearching ? Icons.clear : Icons.search,
//                               color: Colors.black54
//                           ),
//                         )
//                       ],
//                     ),
//                   );
//                 }
//                 return _createTransactionTile(filteredTransactions[index - 1], index == filteredTransactions.length);
//               })
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _createTransactionTile(Map<String, dynamic> data, bool isEnd) {
//     Timestamp createdAt = data['createdAt'] as Timestamp;
//     // Timestamp createdAt = data['created_at'] as Timestamp;
//     DateTime dateTime = createdAt.toDate();
//     String timeAgo = timeago.format(dateTime);
//
//     IconData icon = Icons.pending;
//
//     if ('${data['status']}' == 'true') {
//       icon = Icons.file_download_done_outlined;
//     } else if ('${data['failed']}' == 'true'){
//       icon = Icons.cancel;
//     }
//
// /*    IconData icon;
//     Color iconColor;
//
//     switch (data['status']) {
//       case 'submitted':
//         icon = Icons.file_download_done_outlined;
//         iconColor = Colors.green;
//         break;
//       case 'failed':
//         icon = Icons.cancel;
//         iconColor = Colors.red;
//         break;
//       default:
//         icon = Icons.pending;
//         iconColor = Colors.grey;*/
//   //  }
//
//
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Row(
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                     color: AppColors.gradient1,
//                     borderRadius: BorderRadius.all(Radius.circular(8))
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Icon(icon, color: Colors.white),
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                         data.containsKey('note') && (data['note']??'').isNotEmpty ? data['note'] : 'Information unavailable',
//                         style: TextStyle(
//                             color: Colors.black,
//                             fontSize: 15
//                         )
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                         timeAgo,
//                         style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 15
//                         )
//                     ),
//     // Text(
//     // data['pradhan_name'] + ' - ' + data['location']['name'],
//     // style: TextStyle(color: Colors.black, fontSize: 15),
//     // ),
//     // SizedBox(height: 4),
//     // Text(
//     // data['remark'].isNotEmpty ? data['remark'] : 'Status: ${data['status']}',
//     // style: TextStyle(color: Colors.grey, fontSize: 13),
//     // ),
//     // SizedBox(height: 4),
//     // Text(
//     // timeAgo,
//     // style: TextStyle(color: Colors.grey, fontSize: 13),
//     // ),
//
//     ],
//                 ),
//               ),
//               SizedBox(width: 10),
//               Text(
//                   "${data['amount']} rs",
//                   style: TextStyle(
//                       color: Colors.green,
//                       fontSize: 15
//                   )
//               ),
// /*    Text(
//     "${data['amount_due']} rs",
//     style: TextStyle(color: Colors.green, fontSize: 15),
//     ),*/
//     ],
//           ),
//         ),
//         if (!isEnd) Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 26),
//           child: Divider(color: Colors.grey.withOpacity(0.6)),
//         )
//       ],
//     );
//   }
//
// }

////////////////////////////////////////////////////////////
// import 'dart:math';
// import 'package:chunaw/app/dbvertex/transfer_to_campaign_fund_screen.dart';
// import 'package:chunaw/app/dbvertex/update_bank_details.dart';
// import 'package:chunaw/app/dbvertex/withdraw_breakdown.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:screenshot/screenshot.dart';
//
// import '../controller/common/loading_controller.dart';
// import '../service/collection_name.dart';
// import '../utils/app_bar.dart';
// import '../utils/app_colors.dart';
// import '../utils/app_pref.dart';
// import '../widgets/app_toast.dart';
// import 'add_withdraw_request_screen.dart';
// import 'ishwar_constants.dart';
//
// import 'package:timeago/timeago.dart' as timeago;
//
// class NewWithdrawScreen extends StatefulWidget {
//   const NewWithdrawScreen({super.key});
//
//   @override
//   State<StatefulWidget> createState() => NewWithdrawState();
// }
//
// class NewWithdrawState extends State<NewWithdrawScreen> {
//   LoadingController loadingcontroller = Get.put(LoadingController());
//
//   int? totalViewsGeneratedByPradhaan;
//   double? pradhaanRevenue;
//   double? pradhaanRemainingBalance;
//
//   bool isLoading = true;
//   bool isSearching = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBarCustom(
//           leadingBack: true,
//           title: 'Your Account',
//           elevation: 0,
//         ),
//         body: FutureBuilder(
//             future: FirebaseFirestore.instance.collection(USER_DB).where('id', isEqualTo: Pref.getString(Keys.USERID)).get(),
//             builder: (context, snapshot) {
//               final data = snapshot.data?.docs.firstOrNull?.data();
//
//               if (data == null) {
//                 return Center(
//                   child: CircularProgressIndicator(color: AppColors.primaryColor,),
//                 );
//               }
//
//               final String profileImage = data['image'] ?? '';
//               final String name = data['name'] ?? '';
//
//               final int userLevel = data['level'] ?? 1;
//               final Map postal = data['postal'] ?? {};
//               final Map city = data['city'] ?? {};
//               final Map country = data['country'] ?? {};
//               final Map state = data['state'] ?? {};
//
//               List<Map> scopeData = [postal, city, state, country].sublist(max(0, userLevel - 1)).reversed.toList();
//               String scopeSuffix = scopeData[scopeData.length - 1]['id'] ?? '';
//               String scopeSuffixName = scopeData[scopeData.length - 1]['name'] ?? '';
//
//               return NestedScrollView(
//                 headerSliverBuilder: (context, innerBoxIsScrolled) {
//                   return isSearching ? [] : [
//                     StreamBuilder<DocumentSnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection('wallets')
//                           .doc(FirebaseAuth.instance.currentUser?.uid)
//                           .snapshots(),
//                       builder: (context, walletSnapshot) {
//                         if (walletSnapshot.hasError) {
//                           longToastMessage('Failed to load wallet data');
//                           return _buildInfoBubble(0, 'Your balance', Icons.account_balance_wallet, 'Loading...', null, Colors.grey, 6);
//                         }
//                         if (!walletSnapshot.hasData) {
//                           return _buildInfoBubble(0, 'Your balance', Icons.account_balance_wallet, 'Loading...', null, Colors.grey, 6);
//                         }
//
//                         final walletData = walletSnapshot.data?.data() as Map<String, dynamic>?;
//                         pradhaanRevenue = (walletData?['amount'] ?? 0).toDouble();
//                         pradhaanRemainingBalance = ((walletData?['amount'] ?? 0) - (walletData?['used_amount'] ?? 0)).toDouble();
//                         totalViewsGeneratedByPradhaan = 0; // Kept for compatibility
//
//                         return FutureBuilder(
//                           future: FirebaseFirestore.instance.collection(BANK_DETAILS_DB).doc(FirebaseAuth.instance.currentUser?.uid).get(),
//                           builder: (context, accountSnapshot) {
//                             final detailsExists = (accountSnapshot.data?.exists ?? false) && accountSnapshot.data!.data()!.keys.every((key) => [
//                               'bank_name',
//                               'account_number',
//                               'ifsc_number',
//                               'bank_address',
//                               'your_name'
//                             ].contains(key));
//
//                             return _buildInfoBubble(pradhaanRemainingBalance ?? 0, 'Your balance', Icons.account_balance_wallet, accountSnapshot.data == null ? 'Loading...' : detailsExists ? 'Update Bank Details' : 'Add Bank Details', accountSnapshot.data == null ? null : () async {
//                               if (0 >= (pradhaanRevenue ?? 0)) {
//                                 longToastMessage('You are not eligible for this option as you haven\'t earned yet.');
//                                 return;
//                               }
//                               Navigator.of(context).push(MaterialPageRoute(builder: (context) => UpdateBankDetails()));
//                             }, (pradhaanRevenue ?? 0) > 0 ? AppColors.gradient1 : Colors.grey, 6);
//                           },
//                         );
//                       },
//                     ),
//                     StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collectionGroup('pradhaan_payouts')
//                           .where('user_id', isEqualTo: Pref.getString(Keys.USERID))
//                           .snapshots(),
//                       builder: (context, payoutSnapshot) {
//                         double totalEarnings = 0.0;
//                         if (payoutSnapshot.hasData) {
//                           totalEarnings = payoutSnapshot.data!.docs.fold(
//                             0.0,
//                                 (sum, doc) => sum + (doc['amount_due'] as num).toDouble(),
//                           );
//                         }
//                         return _buildInfoBubble(totalEarnings, 'Your total earning', Icons.monetization_on, 'Breakdown', () {
//                           Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawBreakdown()));
//                         });
//                       },
//                     ),
//                     // _buildInfoBubble('Free Auto Campaign', 'Click here to contribute', Icons.local_taxi_sharp, 'Contribute', () {
//                     //   Navigator.of(context).push(MaterialPageRoute(builder: (context) => TransferToCampaignScreen(() => setState(() => pradhaanRevenue = null), scopeSuffix: scopeData.lastOrNull?['id'] ?? '', title: 'Pradhaan Contribution',)));
//                     // }, null),
//                     // _buildInfoBubble(20.0, 'Used free auto fund in your area', Icons.done_outline_rounded),
//                   ];
//                 },
//                 body: StreamBuilder(
//                     stream: FirebaseFirestore.instance
//                         .collectionGroup('pradhaan_payouts')
//                         .where('user_id', isEqualTo: Pref.getString(Keys.USERID))
//                         .orderBy('send_date', descending: true)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       return snapshot.data == null || snapshot.data!.docs.isEmpty ? Container(
//                         color: Theme.of(context).colorScheme.surface,
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 6),
//                           child: Container(
//                             color: Colors.white,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.hourglass_empty, color: Colors.grey, size: MediaQuery.sizeOf(context).width * 0.1),
//                                 SizedBox(height: 16),
//                                  Text(
//                                   'No Activity',
//                                   style: TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 17,
//                                       fontWeight: FontWeight.bold
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ) : TransactionListPage(snapshot.data!.docs, (isSearching) {
//                         setState(() {
//                           this.isSearching = isSearching;
//                         });
//                       }, isSearching);
//                     }
//                 ),
//               );
//             }
//         )
//     );
//   }
//
//   _buildInfoBubble(dynamic value, String title, [IconData? icon, String? actionLabel, VoidCallback? onPressed, Color? buttonBackgroundColor, double extraTopPadding = 0]) {
//     return SliverAppBar(
//       automaticallyImplyLeading: false,
//       expandedHeight: (MediaQuery.sizeOf(context).width * (actionLabel == 'Contribute' ? 0.335 : 0.3)),
//       collapsedHeight: MediaQuery.sizeOf(context).width * 0.28,
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       surfaceTintColor: Theme.of(context).colorScheme.surface,
//       flexibleSpace: Card(
//         color: Colors.white,
//         elevation: 0,
//         margin: EdgeInsets.all(3).copyWith(top: 3 + extraTopPadding),
//         child: Center(
//           child: ListTile(
//             contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//             leading: icon != null ? Icon(
//                 icon,
//                 color: Colors.grey
//             ) : null,
//             title: Text(
//               value is double ? value.toStringAsFixed(1) : value.toString(),
//               style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18
//               ),
//             ),
//             trailing: actionLabel != null ? Card(
//               elevation: 0,
//               color: buttonBackgroundColor ?? AppColors.gradient1,
//               clipBehavior: Clip.hardEdge,
//               child: InkWell(
//                 onTap: onPressed,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                   child: Text(
//                     actionLabel,
//                     style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14
//                     ),
//                   ),
//                 ),
//               ),
//             ) : null,
//             subtitle: Text(
//               title,
//               style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 13
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class TransactionListPage extends StatefulWidget {
//   final List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions;
//   final Function(bool isSearching) onSearchStateChanges;
//   final bool isSearching;
//
//   const TransactionListPage(this.transactions, this.onSearchStateChanges, this.isSearching, {super.key});
//
//   @override
//   State<StatefulWidget> createState() => TransactionListState();
// }
//
// class TransactionListState extends State<TransactionListPage> {
//   bool isSearching = false;
//   String searchFilter = '';
//
//   @override
//   void initState() {
//     isSearching = widget.isSearching;
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var filteredTransactions = widget.transactions.map<Map<String, dynamic>>((snapshot) {
//       return snapshot.data();
//     }).toList();
//     if (isSearching) {
//       filteredTransactions = filteredTransactions.where((data) {
//         return searchFilter.isEmpty ||
//             "${data['pradhan_name']} ${data['scope']} ${data['remark'] ?? ''}".toLowerCase().contains(searchFilter);
//       }).toList();
//     }
//
//     return SingleChildScrollView(
//       child: Container(
//         color: Theme.of(context).colorScheme.surface,
//         child: Card(
//           elevation: 0,
//           color: Colors.white,
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.only(
//                   topRight: Radius.circular(25),
//                   topLeft: Radius.circular(25)
//               )
//           ),
//           margin: EdgeInsets.only(top: 8),
//           child: Column(
//               children: List.generate(filteredTransactions.length + 1, (index) {
//                 if (index == 0) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 18).copyWith(top: 20, right: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: isSearching ? TextField(
//                             onChanged: (val) => setState(() {
//                               searchFilter = val.trim().toLowerCase();
//                             }),
//                             decoration: InputDecoration(
//                                 hintText: 'Search by name, scope, or remark',
//                                 enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.grey.withOpacity(0.4))),
//                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.grey.withOpacity(0.4))),
//                                 focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide(color: Colors.grey.withOpacity(0.4))),
//                                 contentPadding: EdgeInsets.symmetric(horizontal: 12)
//                             ),
//                           ) : Text(
//                             'Payout History',
//                             style: TextStyle(
//                                 fontSize: 18,
//                                 color: Colors.black54
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           onPressed: () {
//                             searchFilter = '';
//                             isSearching = !isSearching;
//                             widget.onSearchStateChanges(isSearching);
//                           },
//                           icon: Icon(
//                               isSearching ? Icons.clear : Icons.search,
//                               color: Colors.black54
//                           ),
//                         )
//                       ],
//                     ),
//                   );
//                 }
//                 return _createTransactionTile(filteredTransactions[index - 1], index == filteredTransactions.length);
//               })
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _createTransactionTile(Map<String, dynamic> data, bool isEnd) {
//     Timestamp sendDate = data['send_date'] as Timestamp;
//     DateTime dateTime = sendDate.toDate();
//     String timeAgo = timeago.format(dateTime);
//
//     IconData icon = Icons.pending;
//
//     if (data['status'] == 'paid') {
//       icon = Icons.file_download_done_outlined;
//     } else if (data['status'] == 'failed') {
//       icon = Icons.cancel;
//     }
//
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Row(
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                     color: AppColors.gradient1,
//                     borderRadius: BorderRadius.all(Radius.circular(8))
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Icon(icon, color: Colors.white),
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                         data.containsKey('pradhan_name') && (data['pradhan_name'] ?? '').isNotEmpty ? data['pradhan_name'] : 'Information unavailable',
//                         style: TextStyle(
//                             color: Colors.black,
//                             fontSize: 15
//                         )
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                         'Scope: ${data['scope'] ?? 'Unknown'}',
//                         style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 15
//                         )
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                         data.containsKey('remark') && (data['remark'] ?? '').isNotEmpty ? data['remark'] : 'Status: ${data['status'] ?? 'Unknown'}',
//                         style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 15
//                         )
//                     ),
//                     if (data.containsKey('transaction_id') && (data['transaction_id'] ?? '').isNotEmpty) ...[
//                       SizedBox(height: 4),
//                       Text(
//                           'Transaction ID: ${data['transaction_id']}',
//                           style: TextStyle(
//                               color: Colors.grey,
//                               fontSize: 15
//                           )
//                       ),
//                     ],
//                     SizedBox(height: 4),
//                     Text(
//                         timeAgo,
//                         style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 15
//                         )
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(width: 10),
//               Text(
//                   "${data['amount_due'] ?? 0} rs",
//                   style: TextStyle(
//                       color: Colors.green,
//                       fontSize: 15
//                   )
//               ),
//             ],
//           ),
//         ),
//         if (!isEnd) Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 26),
//           child: Divider(color: Colors.grey.withOpacity(0.6)),
//         )
//       ],
//     );
//   }
// }


////////////////////////////////////////
import 'dart:math';
import 'package:chunaw/app/dbvertex/transfer_to_campaign_fund_screen.dart';
import 'package:chunaw/app/dbvertex/update_bank_details.dart';
import 'package:chunaw/app/dbvertex/withdraw_breakdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import '../controller/common/loading_controller.dart';
import '../service/collection_name.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_pref.dart';
import '../widgets/app_toast.dart';
import 'add_withdraw_request_screen.dart';
import 'ishwar_constants.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:async/async.dart';

class NewWithdrawScreen extends StatefulWidget {
  const NewWithdrawScreen({super.key});

  @override
  State<StatefulWidget> createState() => NewWithdrawState();
}

class NewWithdrawState extends State<NewWithdrawScreen> {
  LoadingController loadingcontroller = Get.put(LoadingController());

  int? totalViewsGeneratedByPradhaan;
  double? pradhaanRevenue;
  double? pradhaanRemainingBalance;

  bool isLoading = true;
  bool isSearching = false;

  Future<bool> getMyRevenueDetails() async {
    print("ishwar: getRevenue details.......call");
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getRevenueDetailsForPradhaan');
      final response = await callable.call({
        "pradhaan_id": FirebaseAuth.instance.currentUser?.uid
      });
      var responseBody = response.data;
      print("ishwar: $responseBody");


    setState(() {
    totalViewsGeneratedByPradhaan = responseBody['totalViewsGeneratedByPradhaan'] ?? 0;
    pradhaanRevenue = double.tryParse((responseBody['pradhaanRevenue'] ?? 0).toString()) ?? 0.0;
    pradhaanRemainingBalance = double.tryParse((responseBody['pradhaanRemainingBalance'] ?? 0.0).toString()) ?? 0.0;
    });
    return true;
    } catch (e) {
    // CHANGE: Uncommented longToastMessage to show error feedback to user
    // WHY: User should know if revenue data fails to load
   // longToastMessage('Failed to load revenue details');
    setState(() {
    totalViewsGeneratedByPradhaan = null;
    pradhaanRevenue = null;
    pradhaanRemainingBalance = null;
    });
    print("ishwar: getting data failed: $e");
    return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Your Account',
        elevation: 0,
      ),
      body: FutureBuilder(
          future: FirebaseFirestore.instance.collection(USER_DB).where('id', isEqualTo: Pref.getString(Keys.USERID)).get(),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs.firstOrNull?.data();

            if (data == null) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            final String profileImage = data['image'] ?? '';
            final String name = data['name'] ?? '';

            final int userLevel = data['level'] ?? 1;
            final Map postal = data['postal'] ?? {};
            final Map city = data['city'] ?? {};
            final Map country = data['country'] ?? {};
            final Map state = data['state'] ?? {};

            List<Map> scopeData = [postal, city, state, country].sublist(max(0, userLevel - 1)).reversed.toList();
            String scopeSuffix = scopeData[scopeData.length - 1]['id'] ?? '';
            String scopeSuffixName = scopeData[scopeData.length - 1]['name'] ?? '';

            if (pradhaanRevenue == null) {
              getMyRevenueDetails();
            }
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return isSearching
                    ? []
                    : [
                  FutureBuilder(
                    future: FirebaseFirestore.instance.collection(BANK_DETAILS_DB).doc(FirebaseAuth.instance.currentUser?.uid).get(),
                    builder: (context, accountSnapshot) {
                      final detailsExists = (accountSnapshot.data?.exists ?? false) &&
                          accountSnapshot.data!.data()!.keys.every((key) => [
                            'bank_name',
                            'account_number',
                            'ifsc_number',
                            'bank_address',
                            'your_name'
                          ].contains(key));

                      return _buildInfoBubble(
                        pradhaanRemainingBalance ?? 0,
                        'Your balance',
                        Icons.account_balance_wallet,
                        accountSnapshot.data == null ? 'Loading...' : detailsExists ? 'Update Bank Details' : 'Add Bank Details',
                        accountSnapshot.data == null
                            ? null
                            : () async {
                          if (0 >= (pradhaanRevenue ?? 0)) {
                            longToastMessage('You are not eligible for this option as you haven\'t earned yet.');
                            return;
                          }
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => UpdateBankDetails()));
                        },
                        (pradhaanRevenue ?? 0) > 0 ? AppColors.gradient1 : Colors.grey,
                        6,
                      );
                    },
                  ),
                  _buildInfoBubble(
                    (pradhaanRevenue ?? 0)/* - (pradhaanRemainingBalance ?? 0)*/,
                    'Your total earning',
                    Icons.monetization_on,
                    'Breakdown',
                        () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawBreakdown()));
                    },
                  ),
                ];
              },
              body:StreamBuilder<List<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
                // CHANGE: Switched from TRANSACTION_HISTORY to payouts/pradhaan_payouts collection
                // WHY: payouts is the new data source for weekly payout records, synced with index.js calculatePayments
                // stream: FirebaseFirestore.instance
                //     .collectionGroup('pradhaan_payouts')
                //     .where('user_id', isEqualTo: Pref.getString(Keys.USERID))
                //     .orderBy('send_date', descending: true)
                //     .snapshots(),
                // stream: FirebaseFirestore.instance
                //     .collectionGroup('locations')
                //     .where('user_id', isEqualTo: Pref.getString(Keys.USERID))
                //     .orderBy('send_date', descending: true)
                //     .snapshots(),
                stream: combinedStream(),
                builder: (context, snapshot) {
                  // if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_empty, color: Colors.grey, size: MediaQuery.sizeOf(context).width * 0.1),
                              SizedBox(height: 16),
                              Text(
                                'No Activity',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final combinedDocs = [...snapshot.data![0], ...snapshot.data![1]].where((doc) =>doc.data().containsKey('scope') && (doc['scope']?.toString().isNotEmpty??false)).toList();
                  combinedDocs.sort((a, b) =>
                      (b['send_date'] as Timestamp).compareTo(a['send_date'] as Timestamp));

                  return TransactionListPage(combinedDocs, (isSearching) {
                    setState(() {
                      this.isSearching = isSearching;
                    });
                  }, isSearching);
                },
              ),
            );
          }),
    );
  }

  Stream<List<List<QueryDocumentSnapshot<Map<String, dynamic>>>>> combinedStream() {
    return StreamZip([
      getPradhaanPayouts(),
      getLocations(),
    ]);
  }
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getPradhaanPayouts() {
    return FirebaseFirestore.instance
        .collectionGroup('pradhaan_payouts')
        .where('user_id', isEqualTo: Pref.getString(Keys.USERID))
        .orderBy('send_date', descending: true)
        .snapshots()
        .map((event) => event.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getLocations() {
    return FirebaseFirestore.instance
        .collectionGroup(LOCATIONS_PAY_DB)
        .where('user_id', isEqualTo: Pref.getString(Keys.USERID))
        .orderBy('send_date', descending: true)
        .snapshots()
        .map((event) => event.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
  }
  SliverAppBar _buildInfoBubble(dynamic value, String title,
      [IconData? icon, String? actionLabel, VoidCallback? onPressed, Color? buttonBackgroundColor, double extraTopPadding = 0]) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: (MediaQuery.sizeOf(context).width * (actionLabel == 'Contribute' ? 0.335 : 0.3)),
      collapsedHeight: MediaQuery.sizeOf(context).width * 0.28,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: Card(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.all(3).copyWith(top: 3 + extraTopPadding),
        child: Center(
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            leading: icon != null
                ? Icon(
              icon,
              color: Colors.grey,
            )
                : null,
            title: Text(
              value is double ? value.toStringAsFixed(1) : value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            trailing: actionLabel != null
                ? Card(
              elevation: 0,
              color: buttonBackgroundColor ?? AppColors.gradient1,
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
                : null,
            subtitle: Text(
              title,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionListPage extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions;
  final Function(bool isSearching) onSearchStateChanges;
  final bool isSearching;

  const TransactionListPage(this.transactions, this.onSearchStateChanges, this.isSearching, {super.key});

  @override
  State<StatefulWidget> createState() => TransactionListState();
}

class TransactionListState extends State<TransactionListPage> {
  bool isSearching = false;
  String searchFilter = '';

  @override
  void initState() {
    isSearching = widget.isSearching;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var filteredTransactions = widget.transactions.map<Map<String, dynamic>>((snapshot) {
      return snapshot.data();
    }).toList();
    // CHANGE: Updated search to include pradhan_name, scope, remark, level
    // WHY: payouts collection has these fields, and user should be able to search by them
    if (isSearching) {
      filteredTransactions = filteredTransactions.where((data) {
        return searchFilter.isEmpty ||
            "${data['pradhan_name']} ${data['scope']} ${data['remark'] ?? ''} ${data['level']}"
                .toLowerCase()
                .contains(searchFilter);
      }).toList();
    }

    return SingleChildScrollView(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(25),
              topLeft: Radius.circular(25),
            ),
          ),
          margin: EdgeInsets.only(top: 8),
          child: Column(
            children: List.generate(filteredTransactions.length + 1, (index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18).copyWith(top: 20, right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: isSearching
                            ? TextField(
                          onChanged: (val) => setState(() {
                            searchFilter = val.trim().toLowerCase();
                          }),
                          decoration: InputDecoration(
                            // CHANGE: Updated hint text for better UX
                            // WHY: Clarifies what user can search by
                            hintText: 'Search by name, scope, remark, or level',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        )
                            : Text(
                          // CHANGE: Changed title to "Payout History"
                          // WHY: More accurate for payouts-based data
                          'Payout History',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          searchFilter = '';
                          isSearching = !isSearching;
                          widget.onSearchStateChanges(isSearching);
                          setState(() {});
                        },
                        icon: Icon(
                          isSearching ? Icons.clear : Icons.search,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _createTransactionTile(filteredTransactions[index - 1], index == filteredTransactions.length);
            }),
          ),
        ),
      ),
    );
  }

  Widget _createTransactionTile(Map<String, dynamic> data, bool isEnd) {
    print("data in history: $data");
    // CHANGE: Switched from createdAt to send_date
    // WHY: payouts collection uses send_date field for timestamp
    Timestamp sendDate = data['send_date'] as Timestamp;
    DateTime dateTime = sendDate.toDate();
    String timeAgo = timeago.format(dateTime);

    // CHANGE: Updated status icon logic for payouts status field (pending, paid, failed)
    // WHY: payouts uses string status instead of boolean status/failed fields
    IconData icon;
    Color iconColor;
var status=data['status'].toString().toLowerCase();
    switch (status) {
      case 'success':
        icon = Icons.file_download_done_outlined;
        iconColor = Colors.green;
        break;
      case 'failed':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.pending;
        iconColor = Colors.grey;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  // CHANGE: Icon background color now matches status
                  // WHY: Improves visual feedback (green for paid, red for failed)
                  color: iconColor,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(icon, color: Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CHANGE: Replaced note with pradhan_name
                    // WHY: payouts collection provides pradhan_name for user context
                    Text(
                      data.containsKey('pradhan_name') && (data['pradhan_name'] ?? '').isNotEmpty
                          ? data['pradhan_name']
                          : 'Information unavailable',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    // CHANGE: Added level field
                    // WHY: Shows payout level (postal, city, etc.) from payouts
                    Text(
                      'Level: ${data['level'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    // CHANGE: Added scope field
                    // WHY: Provides specific area context (e.g., ward_xyz)
                    Text(
                      'Scope: ${data['scope'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    // CHANGE: Replaced note with remark or status
                    // WHY: payouts provides remark for failure reasons or status if no remark
                    Text(
                      !data.containsKey('remark') && (data['remark'] ?? '').isNotEmpty
                          ? data['remark']
                          : 'Status: ${data['status'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    // CHANGE: Added transaction_id display
                    // WHY: Shows transaction ID for paid payouts
                    if (data.containsKey('transaction_id') && (data['transaction_id'] ?? '').isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        'Transaction ID: ${data['transaction_id']}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              // CHANGE: Switched from amount to amount_due
              // WHY: payouts collection uses amount_due for payout amount
           Text(
                // "Rs: ${data['amount_due'] ?? 0} /-",
             "Rs: ${((data['total_amount'] ?? data['amount_due'] ?? 0).toDouble()).toStringAsFixed(2)} /-",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        if (!isEnd)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Divider(color: Colors.grey.withOpacity(0.6)),
          ),
      ],
    );
  }

}