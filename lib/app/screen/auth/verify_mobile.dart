import 'package:chunaw/app/controller/auth/auth_controller.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/widgets/app_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyMobile extends StatelessWidget {
  VerifyMobile({Key? key}) : super(key: key);
  final AuthController authController = Get.find<AuthController>(tag: "Auth");
  final TextEditingController otpController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size(double.infinity, 70),
          child: SimpleAppBar(title: "")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 18),
            Text(
              "OTP Verification",
              style: TextStyle(
                  fontFamily: AppFonts.Montserrat,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
            SizedBox(height: 12),
            Text(
              "We send a code to (${authController.phoneController.text[0]}${authController.phoneController.text[1]}*****${authController.phoneController.text[8]}${authController.phoneController.text[9]}).\nEnter it here to verify your identity",
              style: TextStyle(
                  fontFamily: AppFonts.Montserrat,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black),
            ),
            SizedBox(height: 34),
            PinCodeTextField(
              length: 6,
              obscureText: false,
              animationType: AnimationType.fade,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(5),
                  fieldHeight: 58,
                  fieldWidth: 50,
                  activeFillColor: AppColors.textBackColor,
                  selectedColor: AppColors.black,
                  inactiveFillColor: AppColors.textBackColor,
                  selectedFillColor: AppColors.black),
              animationDuration: Duration(milliseconds: 300),
              controller: otpController,
              enablePinAutofill: true,
              onCompleted: (v) {
                print("Completed");
              },
              onChanged: (value) {
                // print(value);
                // setState(() {
                //   currentText = value;
                // });
              },
              appContext: context,
            ),
            SizedBox(height: 34),
            Center(
              child: InkWell(
                onTap: (){},
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.primaryColor,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Spacer(),
            AppButton(
                onPressed: () {
                  authController.verifyOTP(
                    context,
                    smsCode: otpController.text,
                  );
                },
                buttonText: "Submit"),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
