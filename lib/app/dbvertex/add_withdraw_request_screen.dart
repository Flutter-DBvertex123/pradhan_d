// import 'dart:math';
//
// import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
// import 'package:chunaw/app/service/collection_name.dart';
// import 'package:chunaw/app/utils/app_bar.dart';
// import 'package:chunaw/app/widgets/app_toast.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../controller/common/loading_controller.dart';
// import '../utils/app_fonts.dart';
// import '../utils/app_pref.dart';
// import '../utils/show_snack_bar.dart';
// import '../widgets/app_button.dart';
// import '../widgets/app_text_field.dart';
//
// class AddWithdrawRequestScreen extends StatefulWidget {
//   final Function() onWithdraw;
//   const AddWithdrawRequestScreen(this.onWithdraw, {super.key});
//
//   @override
//   State<StatefulWidget> createState() => _AddWithdrawRequestState();
//
// }
//
// class _AddWithdrawRequestState extends State<AddWithdrawRequestScreen> {
//   var amountController = TextEditingController();
//   var noteController = TextEditingController();
//
//
//   LoadingController loadingcontroller = Get.put(LoadingController());
//
//   @override
//   void dispose() {
//     amountController.dispose();
//     noteController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBarCustom(
//         leadingBack: true,
//         title: 'Add Request',
//         elevation: 0,
//       ),
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "  Amount To Withdraw",
//                   style: TextStyle(
//                       fontFamily: AppFonts.Montserrat,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black),
//                 ),
//                 SizedBox(height: 12),
//                 AppTextField(
//                   controller: amountController,
//                   keyboardType: TextInputType.number,
//                   lableText: "₹",
//                   maxLines: 1,
//                   minLines: 1,
//                 ),
//                 SizedBox(height: 12),
//                 Text(
//                   "  Note",
//                   style: TextStyle(
//                       fontFamily: AppFonts.Montserrat,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.black),
//                 ),
//                 SizedBox(height: 12),
//                 AppTextField(
//                   controller: noteController,
//                   textCapitalization: TextCapitalization.sentences,
//                   keyboardType: TextInputType.text,
//                   lableText: "Add note (Optional)",
//                   maxLines: 2,
//                   minLines: 1,
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               color: Theme.of(context).colorScheme.onPrimary,
//               padding: EdgeInsets.symmetric(vertical: 16),
//               child: AppButton(
//                   onPressed: submit,
//                   buttonText: 'Submit Request'
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> submit() async {
//     String? validationError;
//
//     double proposedAmount = 0;
//     try {
//       proposedAmount = double.parse(amountController.text.trim());
//       if (0>=proposedAmount) {
//         validationError = 'Amount can not be 0 or negative';
//       }
//     } catch (parseError) {
//       validationError = 'Please enter valid amount to withdraw';
//     }
//
//     String note = noteController.text.trim();
//     if (note.length >= 50) {
//       validationError = 'Note can not be longer than 50 characters.';
//     }
//
//     if (validationError != null) {
//       longToastMessage(validationError);
//       return;
//     }
//
//     FocusManager.instance.primaryFocus?.unfocus();
//
//     loadingcontroller.updateLoading(true);
//
//     try {
//       final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getRevenueDetailsForPradhaan');
//       final response = await callable.call({
//         "pradhaan_id": FirebaseAuth.instance.currentUser?.uid
//       });
//
//       var responseBody = response.data;
//       print("ishwar: $responseBody");
//
//       int totalViewsGeneratedByPradhaan = responseBody['totalViewsGeneratedByPradhaan'] ?? 0;  // Only for the specific pradhaan
//       final rev = responseBody['pradhaanRevenue'] ?? 0.0;
//       double? pradhaanRevenue = rev is int ? rev.toDouble() : rev;
//       double? pradhaanRemainingBalance = (responseBody['pradhaanRemainingBalance'] ?? 0);
//
//       if ((pradhaanRemainingBalance??0) >= proposedAmount) {
//         await FirebaseFirestore.instance.collection(TRANSACTION_HISTORY).doc().set({
//           'uid': FirebaseAuth.instance.currentUser?.uid,
//           'amount': proposedAmount,
//           'createdAt': DateTime.now(),
//           'status': false,
//           'failed': false,
//           'note': note.isNotEmpty ? note : 'Withdrawal Request'
//         });
//         widget.onWithdraw();
//         loadingcontroller.updateLoading(false);
//         Navigator.of(context).pop();
//         longToastMessage('Request submitted.');
//       } else {
//         loadingcontroller.updateLoading(false);
//         longToastMessage('You can not request amount more than your available balance');
//       }
//     } catch (_) {
//       loadingcontroller.updateLoading(false);
//       Navigator.of(context).pop();
//       showSnackBar(context, message: 'Something went wrong!');
//     }
//
//     // try {
//     //   var snapshot = await FirebaseFirestore.instance.collection(USER_DB).where('id', isEqualTo: Pref.getString(Keys.USERID)).get();
//     //   final data = snapshot.docs.firstOrNull?.data();
//     //
//     //   if (data == null) {
//     //     loadingcontroller.updateLoading(false);
//     //     Navigator.of(context).pop();
//     //     longToastMessage('Unable to fetch user data');
//     //     return;
//     //   }
//     //
//     //   final int userLevel = data['level'];
//     //   final Map postal = data['postal'];
//     //   final Map city = data['city'];
//     //   final Map country = data['country'];
//     //   final Map state = data['state'];
//     //
//     //   List<Map> scopeData = [postal, city, state, country].sublist(max(0, userLevel - 2)).reversed.toList();
//     //   String scopeSuffix = scopeData[scopeData.length - 1]['id'] ?? '';
//     //   List<String> scope = scopeData.map<String>((val) => val['name']).toList();
//     //
//     //   print("ishwar: $scope suffix: $scopeSuffix");
//     //   try {
//     //     final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getRevenueDetailsForScope');
//     //     callable.call({"scope": scope, "scope_suffix": scopeSuffix}).then((response) async {
//     //       double revenue = response.data?['pradhan']?['pradhaanRemainingBalance']?.toDouble() ?? 0.0;
//     //       String pradhanId = response.data?['pradhan']?['pradhanId']??'';
//     //       print("ishwar: response of revenue data for scope $revenue: (${scopeData.map((loc) => loc['name']).toList()}): ${response.data}");
//     //
//     //       if (revenue >= proposedAmount) {
//     //         await FirebaseFirestore.instance.collection(TRANSACTION_HISTORY).doc().set({
//     //           'uid': pradhanId,
//     //           'amount': proposedAmount,
//     //           'createdAt': DateTime.now(),
//     //           'status': false,
//     //           'failed': false,
//     //           'note': note.isNotEmpty ? note : null
//     //         });
//     //         widget.onWithdraw();
//     //         loadingcontroller.updateLoading(false);
//     //         Navigator.of(context).pop();
//     //         longToastMessage('Request submitted.');
//     //       } else {
//     //         loadingcontroller.updateLoading(false);
//     //         longToastMessage('You can not request amount more than your available balance');
//     //       }
//     //     }, onError: (error) {
//     //       Navigator.of(context).pop();
//     //       showSnackBar(context, message: 'Something went wrong!');
//     //       return;
//     //     });
//     //   } catch (e) {
//     //     loadingcontroller.updateLoading(false);
//     //     Navigator.of(context).pop();
//     //     showSnackBar(context, message: 'Something went wrong!');
//     //   }
//     // } catch (error) {
//     //   loadingcontroller.updateLoading(false);
//     //   Navigator.of(context).pop();
//     //   longToastMessage('Something went wrong.');
//     // }
//   }
// }