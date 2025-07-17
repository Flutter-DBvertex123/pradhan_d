import 'package:chunaw/app/dbvertex/add_withdraw_request_screen.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/common/loading_controller.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import 'ishwar_constants.dart';

class UpdateBankDetails extends StatefulWidget {

  const UpdateBankDetails({super.key});

  @override
  State<StatefulWidget> createState() => UpdateBankDetailsState();
}

class UpdateBankDetailsState extends State<UpdateBankDetails> {
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscController = TextEditingController();
  final addressController = TextEditingController();
  final yourNameController = TextEditingController();

  bool isAdding = true;
  Map<String, String>? bankDetails = {};

  LoadingController loadingcontroller = Get.put(LoadingController());

  @override
  void initState() {
    super.initState();
    getBankDetails();
  }

  Future<void> getBankDetails() async {
    bankDetails = null;

    try {
      var reference = FirebaseFirestore.instance.collection(BANK_DETAILS_DB).doc(FirebaseAuth.instance.currentUser?.uid);
      Map<String, dynamic> data = (await reference.get()).data()!;
      bankDetails = {};
      for (var key in data.keys) {
        bankDetails![key] = data[key] ??'';
      }
      isAdding = false;
    } catch (_) {
      isAdding = true;
      print("ishwar: $_");
    } finally {
      bankDetails ??= {};
    }

    if (!isAdding) {
      bankNameController.text = bankDetails?['bank_name'] ?? '';
      accountNumberController.text = bankDetails?['account_number'] ?? '';
      ifscController.text = bankDetails?['ifsc_number'] ?? '';
      addressController.text = bankDetails?['bank_address'] ?? '';
      yourNameController.text = bankDetails?['your_name'] ?? '';

    }

    setState(() {});
  }

  @override
  void dispose() {
    bankNameController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    addressController.dispose();
    yourNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Bank Details',
        elevation: 0,
        showSearch: false,
      ),
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16).copyWith(top: 0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "  Bank Name",
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  SizedBox(height: 12),
                  AppTextField(
                    controller: bankNameController,
                    keyboardType: TextInputType.name,textCapitalization: TextCapitalization.words,
                    lableText: "Please enter your bank name",
                    maxLines: 1,
                    minLines: 1,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "  Account Number",
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  SizedBox(height: 12),
                  AppTextField(
                    controller: accountNumberController,
                    keyboardType: TextInputType.name,textCapitalization: TextCapitalization.characters,
                    lableText: "Enter your account number",
                    maxLines: 1,
                    minLines: 1,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "  IFSC Number",
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black
                    ),
                  ),
                  SizedBox(height: 12),
                  AppTextField(
                    controller: ifscController,
                    keyboardType: TextInputType.text,textCapitalization: TextCapitalization.characters,
                    lableText: "Enter your ifsc number",
                    maxLines: 1,
                    minLines: 1,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "  Bank Address",
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  SizedBox(height: 12),
                  AppTextField(
                    controller: addressController,
                    keyboardType: TextInputType.text,textCapitalization: TextCapitalization.words,
                    lableText: "Enter your bank address",
                    maxLines: 1,
                    minLines: 1,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "  Your Name In Bank",
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black),
                  ),
                  SizedBox(height: 12),
                  AppTextField(
                    controller: yourNameController,
                    keyboardType: TextInputType.name,textCapitalization: TextCapitalization.words,
                    lableText: "What's your name in bank account",
                    maxLines: 1,
                    minLines: 1,
                  ),
                  SizedBox(height: MediaQuery.sizeOf(context).width * 0.4),
                ],
              ),
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
                  buttonText: isAdding ? 'Add' : 'Update'
              ),
            ),
          ),
          if (bankDetails == null) Container(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.gradient1),
            ),
          )
        ],
      ),
    );
  }

  Future<void> submit() async {
    String bankName = bankNameController.text.trim();
    String accountNumber = accountNumberController.text.trim();
    String ifscNumber = ifscController.text.trim();
    String address = addressController.text.trim();
    String yourName = yourNameController.text.trim();

    String? validationError = validate(bankName, accountNumber, ifscNumber, address, yourName);
    if (validationError != null) {
      longToastMessage(validationError);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    var bankDetails = {
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_number': ifscNumber,
      'bank_address': address,
      'your_name': yourName
    };

    loadingcontroller.updateLoading(true);
    try {
      var reference = FirebaseFirestore.instance
          .collection(BANK_DETAILS_DB)
          .doc(FirebaseAuth.instance.currentUser?.uid);
      if (isAdding) {
        await reference.set(bankDetails);
      } else {
        await reference.update(bankDetails);
      }
      loadingcontroller.updateLoading(false);
      Navigator.of(context).pop();
      longToastMessage('Bank details updated successfully');
    } catch (e) {
      loadingcontroller.updateLoading(false);
      print("ishwar: $e");
      longToastMessage('Failed to ${isAdding?'add':'update'} bank details.');
    }
  }

  String? validate(String bankName, String accountNumber, String ifscNumber, String address, String yourName) {
    if (bankName.isEmpty) {
      return 'Please enter bank name.';
    } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(bankName)) {
      return 'Bank name cannot contain numbers or special symbols, please enter the correct name.';
    } else if (!RegExp(r'^\d{10,12}$').hasMatch(accountNumber)) { // Example: 10-12 digits
      return 'Account number must be 10 to 12 digits.';
    } else if (accountNumber.isEmpty) {
      return 'Please enter account number.';
    }else if (ifscNumber.isEmpty) {
      return 'Please enter IFSC number.';
    } else if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifscNumber)) { // IFSC format example
      return 'IFSC number is invalid. Please enter a valid IFSC.';
    } else if (address.isEmpty) {
      return 'Please enter your address.';
    } else if (address.length < 10) { // Example: Minimum length
      return 'Address must be at least 10 characters long.';
    } else if (yourName.isEmpty) {
      return 'Please enter your name.';
    } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(yourName)) {
      return 'Your name cannot contain numbers or special symbols, please enter your correct name.';
    }

    return null;
  }



}