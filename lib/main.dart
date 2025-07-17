import 'package:chunaw/app/controller/common/loading_controller.dart';
import 'package:chunaw/app/screen/splash_screen.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'app/test.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // if (kDebugMode) {
  //   print("ishwar: Configuring app to use Firebase Emulator");
  //   FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
  //   FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  // } else {
  //   print("ishwar: Using production Firebase");
  // }
  Pref.init();

  runApp(const MyApp());
}

LoadingController loadingcontroller = Get.put(LoadingController());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus!.unfocus();
        }
      },
      child: ScreenUtilInit(
        designSize: const Size(414, 896),
        builder: (BuildContext context, Widget? child) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: getMaterialColor(AppColors.primaryColor),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    AppColors.primaryColor,
                  ),
                  foregroundColor: MaterialStateProperty.all(
                    Colors.white,
                  ),
                ),
              ),
              appBarTheme: AppBarTheme(
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                color: Colors.white,
              ),
            ),
            defaultTransition: Transition.cupertino,
            builder: (context, child) {
              return Stack(
                children: [
                  child!,
                  Obx(
                    () => loadingcontroller.loading.value
                        ? Container(
                            color: Colors.grey.withOpacity(0.4),
                            child:
                                //  Column(
                                //   mainAxisAlignment: MainAxisAlignment.center,
                                //   children: [
                                Center(
                              child: LottieBuilder.asset(
                                AppAssets.loadingAnim,
                                height: 230.h,
                                width: 230.w,
                              ),
                            ),
                            // AppButton(
                            //     onPressed: () {
                            //       loadingcontroller.updateLoading(false);
                            //     },
                            //     buttonText: "Stop Loading")
                            //   ],
                            // ),
                          )
                        : Container(),
                  ),
                  Obx(
                    () => !loadingcontroller.internet.value
                        ? PopScope(
                            canPop: false,
                            child: SafeArea(
                              top: false,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 25,
                                  color: Colors.red.withOpacity(0.8),
                                  child:
                                      //  Column(
                                      //   mainAxisAlignment: MainAxisAlignment.center,
                                      //   children: [
                                      Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 10,
                                          width: 10,
                                          child: CircularProgressIndicator(
                                            color: AppColors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          AppString.PleaseConnectInternet.tr,
                                          style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 10,
                                              decoration: TextDecoration.none),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // AppButton(
                                  //     onPressed: () {
                                  //       loadingcontroller.updateLoading(false);
                                  //     },
                                  //     buttonText: "Stop Loading")
                                  //   ],
                                  // ),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  )
                ],
              );
            },
            home: /*ReferralScreen(),*/SplashScreen()
          );
        },
      ),
    );
  }
}
