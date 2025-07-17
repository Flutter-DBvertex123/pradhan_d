import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/service/vote_service.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/utils/notification.dart';
import 'package:chunaw/app/widgets/linear_gradient_mask.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () async {
      if (FirebaseAuth.instance.currentUser != null) {
        Notifications.init();
        if (await UserService.userExists(
            FirebaseAuth.instance.currentUser!.uid)) {
          VoteService.updateUserUpvoteForToday(
              FirebaseAuth.instance.currentUser!.uid, 0);
          UserService.setUserValues();
          AppRoutes.navigateOffHomeTabScreen();
        } else {
          AppRoutes.navigateOffProfileData(isGuestLogin: false);
        }
      } else {
        // if is guest login, navigate to home
        if (Pref.getBool(Keys.IS_GUEST_LOGIN, false)) {
          AppRoutes.navigateOffHomeTabScreen();
        } else {
          AppRoutes.navigateOffLogin();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // color: AppColors.primaryColor,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          end: Alignment.centerLeft,
          begin: Alignment.centerRight,
          colors: [AppColors.gradient1, AppColors.gradient2],
          stops: [0.0, 1.0],
          // tileMode: TileMode.mirror,
        )),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(AppAssets.splashlogo,
                  colorBlendMode: BlendMode.color),
              Center(
                child: LinearGradientMask(
                  child: Text(
                    'Pradhaan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 24,
                        letterSpacing:
                            0 /*percentages not used in flutter. defaulting to zero*/,
                        fontWeight: FontWeight.normal,
                        height: 1),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
