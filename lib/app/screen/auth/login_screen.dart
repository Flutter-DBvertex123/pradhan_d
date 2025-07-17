import 'package:chunaw/app/controller/auth/auth_controller.dart';
import 'package:chunaw/app/screen/auth/terms_and_conditions_page.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/show_snack_bar.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  final bool removeGuestLogin;

  const LoginScreen({Key? key, required this.removeGuestLogin})
      : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    final AuthController authController =
        Get.put(AuthController(), tag: "Auth");
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: Get.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 130),
              SvgPicture.asset(AppAssets.loginImage),
              const Spacer(),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 29),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 15,
                          width: 15,
                          child: Checkbox(
                            value: checked,
                            onChanged: (newValue) {
                              setState(() {
                                checked = newValue!;
                              });
                            },
                            checkColor: AppColors.white,
                            activeColor: AppColors.primaryColor,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'I agree to the ',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final understood = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TermsAndConditionsPage(),
                              ),
                            );

                            // if understood, check the box automatically
                            if (understood) {
                              setState(() {
                                checked = true;
                              });
                            }
                          },
                          child: Text(
                            'Terms and Conditions',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  PlainButton(
                      buttonText: "Continue with Google",
                      verticalPadding: 0,
                      onpressed: () {
                        if (checked) {
                          authController.signInWithGoogle();
                        } else {
                          // Show a SnackBar with the error message indicating that terms and conditions must be accepted
                          showSnackBar(
                            context,
                            message: 'Please accept terms and conditions.',
                            duration: Duration(seconds: 2),
                          );
                        }
                      },
                      color: AppColors.googleColor,
                      asset: AppAssets.googleIcon),
                  PlainButton(
                    buttonText: "Continue with Mobile",
                    verticalPadding: 0,
                    onpressed: () {
                      if (checked) {
                        AppRoutes.navigateToMobileLogin();
                      } else {
                        // Show a SnackBar with the error message indicating that terms and conditions must be accepted
                        showSnackBar(
                          context,
                          message: 'Please accept terms and conditions.',
                          duration: Duration(seconds: 2),
                        );
                      }
                    },
                    color: AppColors.googleColor,
                    asset: AppAssets.mobileIcon,
                  ),
                  if (!widget.removeGuestLogin)
                    const SizedBox(
                      height: 5,
                    ),
                  if (!widget.removeGuestLogin) Text('--- or ---'),
                  if (!widget.removeGuestLogin)
                    const SizedBox(
                      height: 10,
                    ),
                  if (!widget.removeGuestLogin)
                    GestureDetector(
                      onTap: () {
                        if (!checked) {
                          showSnackBar(
                            context,
                            message: 'Please accept terms and conditions.',
                            duration: Duration(seconds: 2),
                          );
                          return;
                        } else {
                          AppRoutes.navigateToProfileData(
                            isGuestLogin: true,
                          );
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 16, color: Colors.black),
                          children: [
                            TextSpan(
                              text: 'Continue as',
                            ),
                            TextSpan(
                              text: ' Guest',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
