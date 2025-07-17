import 'dart:math';

import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
import 'package:chunaw/app/dbvertex/utils/razorpay_impl.dart';
import 'package:chunaw/app/service/collection_name.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../controller/common/loading_controller.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_pref.dart';
import '../utils/show_snack_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class TransferToCampaignScreen extends StatefulWidget {
  final Function() onWithdraw;
  final String? scopeSuffix;
  final String title;
  const TransferToCampaignScreen(this.onWithdraw, {super.key, this.scopeSuffix, required this.title});

  @override
  State<StatefulWidget> createState() => _TransferToCampaignState();

}

class _TransferToCampaignState extends State<TransferToCampaignScreen> {
  var amountController = TextEditingController();
  var noteController = TextEditingController();

  late String scopeSuffix;

  LoadingController loadingcontroller = Get.put(LoadingController());

  @override
  void initState() {

    if (widget.scopeSuffix != null) {
      scopeSuffix = widget.scopeSuffix!;
      noteController.text = 'Contributing to Pradhaan free auto ride campaign for ${scopeSuffix.split('-').sublist(1).join('-')}.';
    } else {
      Future.delayed(Duration(milliseconds: 10), () async {
        loadingcontroller.updateLoading(true);
        
        // Fetch user data
        var snapshot = await FirebaseFirestore.instance
            .collection(USER_DB)
            .where('id', isEqualTo: Pref.getString(Keys.USERID))
            .get();

        final data = snapshot.docs.firstOrNull?.data();
        if (data == null) {
          loadingcontroller.updateLoading(false);
          Navigator.of(context).pop();
          longToastMessage('Unable to fetch user data');
          return;
        }

        // User location and level-based scope logic
        final int userLevel = data['level'];
        final Map postal = data['postal'];
        final Map city = data['city'];
        final Map country = data['country'];
        final Map state = data['state'];

        List<Map> scopeData = [postal, city, state, country].sublist(max(0, userLevel - 2)).reversed.toList();
        scopeSuffix = scopeData[scopeData.length - 1]['id'] ?? '';
        List<String> scope = scopeData.map<String>((val) => val['name']).toList();


        noteController.text = 'Donating to Pradhaan free auto ride campaign for ${scopeSuffix.split('-').sublist(1).join('-')} city.';


        loadingcontroller.updateLoading(false);
      });
    }

    RazorpayManager().setCallbacks(onPaymentSuccess, onPaymentError, externalWalletCallback: onHandleExternalWallet);

    super.initState();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarCustom(
        leadingBack: true,
        title: widget.title,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "  Amount To Contribute",
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                SizedBox(height: 12),
                AppTextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  lableText: "₹",
                  maxLines: 1,
                  minLines: 1,
                ),
                SizedBox(height: 12),
                Text(
                  "  Note",
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                SizedBox(height: 12),
                AppTextField(
                  controller: noteController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.text,
                  maxLines: 2,
                  minLines: 1,
                  enabled: false,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 16),
              child: AppButton(
                  onPressed: submit,
                  buttonText: 'Contribute'
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> onPaymentSuccess(PaymentSuccessResponse response) async {
    pushRecord(response);
  }

  void onPaymentError(PaymentFailureResponse response) {
    Future.delayed(Duration(milliseconds: 10), () => longToastMessage('Payment failed with error code: ${response.error?['code']??'NONE'}.'));
  }

  void onHandleExternalWallet(ExternalWalletResponse response) {
    Future.delayed(Duration(milliseconds: 10), () => longToastMessage('Can not Handle External Wallet.'));
  }

  Future<void> pushRecord([PaymentSuccessResponse? response]) async {
    loadingcontroller.updateLoading(true);
    try {
      String note = noteController.text.trim();
      double proposedAmount = double.tryParse(amountController.text.trim()) ?? 0;

      if (response != null) {
        Map<String, dynamic> captureResponse = await RazorpayManager().capture(response, (proposedAmount * 100).toInt());
        bool captured = captureResponse['captured'] ?? false;

        if (!captured) {
          longToastMessage('Payment failed. Your refund will be provided soon in your bank account.');
          return;
        }
      }

      // Initialize batch write
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Create a new document in TRANSACTION_HISTORY
      DocumentReference transactionRef = FirebaseFirestore.instance.collection(TRANSACTION_HISTORY).doc();
      batch.set(transactionRef, {
        'uid': FirebaseAuth.instance.currentUser?.uid,
        'amount': proposedAmount,
        'createdAt': DateTime.now(),
        'status': true,
        'failed': false,
        'note': note.isNotEmpty ? note : null,
        response?.paymentId == null ? null : 'payment_id': response?.paymentId,
      });

      // Update donations data in a batch
      DocumentReference donationsRef = FirebaseFirestore.instance.collection('donations').doc();
      batch.set(donationsRef, {
        'by': FirebaseAuth.instance.currentUser?.uid,
        'amount': FieldValue.increment(proposedAmount),
        'datetime': DateTime.now(),
        'location': widget.scopeSuffix
      }, SetOptions(merge: true));

      // Commit the batch
      await batch.commit();

      widget.onWithdraw();
      loadingcontroller.updateLoading(false);
      Navigator.of(context).pop();
      longToastMessage('Contribution submitted. Thank you for your support.');
    } catch (error) {
      loadingcontroller.updateLoading(false);
      longToastMessage('Something went wrong.');
    }
  }

  void promptToPayUsingRazorpay(double amount, [String? message]) {
    // RazorpayManager().pay(amount);
    // Disabled now

    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: Text('Insufficient Balance'),
        content: Text('You don\'t have sufficient balance in your wallet to contribute to ${scopeSuffix.split('-').sublist(1).join('-')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Dismiss', style: TextStyle(color: AppColors.gradient1)))
        ],
      );
    });
  }

  Future<void> submit() async {
    String? validationError;
    double proposedAmount = 0;

    try {
      proposedAmount = double.parse(amountController.text.trim());
      if (proposedAmount <= 0) {
        validationError = 'Amount cannot be 0 or negative';
      }
    } catch (parseError) {
      validationError = 'Please enter a valid amount to contribute';
    }

    if (validationError != null) {
      longToastMessage(validationError);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    loadingcontroller.updateLoading(true);

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getRevenueDetailsForPradhaan');
      final response = await callable.call({
        "pradhaan_id": FirebaseAuth.instance.currentUser?.uid
      });

      var responseBody = response.data;
      print("ishwar: $responseBody");

      // int totalViewsGeneratedByPradhaan = responseBody['totalViewsGeneratedByPradhaan'] ?? 0;  // Only for the specific pradhaan
      // double? pradhaanRevenue = responseBody['pradhaanRevenue'] ?? 0;
      double? pradhaanRemainingBalance = (double.tryParse((responseBody['pradhaanRemainingBalance'] ?? 0.0).toString()) ?? 0.0);


      loadingcontroller.updateLoading(false);
      if (0 >= (pradhaanRemainingBalance??0)) {
        promptToPayUsingRazorpay(proposedAmount, 'You cannot contribute more than your available balance.');
      } else
        if ((pradhaanRemainingBalance??0) >= proposedAmount) {
        pushRecord();
      } else {
        promptToPayUsingRazorpay(proposedAmount, 'You cannot contribute more than your available balance.');
      }
    } catch (e) {
      loadingcontroller.updateLoading(false);
      Navigator.of(context).pop();
      showSnackBar(context, message: 'Something went wrong.');
      print("ishwar: Error: $e");
    }
  }

}