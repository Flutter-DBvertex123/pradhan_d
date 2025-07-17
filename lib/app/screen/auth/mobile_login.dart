import 'package:chunaw/app/controller/auth/auth_controller.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/widgets/app_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_text_field.dart';
import 'package:chunaw/app/widgets/country_flag_widget.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MoibleLogin extends StatelessWidget {
  MoibleLogin({Key? key}) : super(key: key);
  final AuthController authController = Get.find<AuthController>(tag: "Auth");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size(double.infinity, 70),
          child: SimpleAppBar(title: "Mobile Number")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 18),
            Text(
              "  Mobile Number",
              style: TextStyle(
                  fontFamily: AppFonts.Montserrat,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 65,
              child: Row(
                children: [
                  CountryCodeWidget(
                    text: authController.selectedCountryCode,
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode:
                            true, // optional. Shows phone code before the country name.
                        onSelect: (Country country) {
                          print('Select country: ${country.displayName}');
                          authController.selectedCountryCode.value =
                              "+${country.phoneCode}";
                        },
                      );
                    },
                  ),
                  Expanded(
                    child: AppTextField(
                      controller: authController.phoneController,
                      keyboardType: TextInputType.phone,
                      lableText: "Enter mobile number",
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            AppButton(
                onPressed: () {
                  print('Users Phone Number ${authController.phoneController.text}');
                  authController.signInwithPhone();
                },
                buttonText: "Continue"),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
