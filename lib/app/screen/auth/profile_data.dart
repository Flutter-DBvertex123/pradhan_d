import 'dart:convert';

import 'package:chunaw/app/controller/auth/profile_process_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_drop_down.dart';
import 'package:chunaw/app/widgets/app_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileData extends StatefulWidget {
  const ProfileData({
    Key? key,
    required this.isGuestLogin,
  }) : super(key: key);

  final bool isGuestLogin;

  @override
  State<ProfileData> createState() => _ProfileDataState();
}

class _ProfileDataState extends State<ProfileData> {
  final ProfileProcessController processController =
      Get.put(ProfileProcessController(), tag: "Profile");

  // whether this is a guest login or not
  late final bool isGuestLogin;

  @override
  void initState() {
    super.initState();

    // just check with auth id here
    isGuestLogin = widget.isGuestLogin;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: PreferredSize(
      //     preferredSize: Size(double.infinity, 70),
      //     child: SimpleAppBar(title: "")),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 18),
                      Text(
                        isGuestLogin ? ' Almost there!' : " Welcome! 👋",
                        style: TextStyle(
                            fontFamily: AppFonts.Montserrat,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black),
                      ),
                      SizedBox(height: 8),
                      Text(
                        isGuestLogin
                            ? '  Please select locations to view posts'
                            : "  Create your account",
                        style: TextStyle(
                            fontFamily: AppFonts.Montserrat,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.greyTextColor),
                      ),
                      if (!isGuestLogin) SizedBox(height: 30),
                      // if (!isGuestLogin)
                      //   Text(
                      //     ' Individual or Organization?',
                      //     style: TextStyle(
                      //       fontFamily: AppFonts.Montserrat,
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.w500,
                      //       color: Colors.black,
                      //     ),
                      //   ),
                      // if (!isGuestLogin)
                      //   SizedBox(
                      //     height: 12,
                      //   ),
                      // if (!isGuestLogin)
                      //   Container(
                      //     padding: EdgeInsets.all(4),
                      //     height: 59,
                      //     decoration: BoxDecoration(
                      //       color: AppColors.textBackColor,
                      //       borderRadius: BorderRadius.circular(9),
                      //       border: Border.all(
                      //         color: AppColors.borderColorGrey,
                      //         width: 1.5,
                      //       ),
                      //     ),
                      //     child: Row(
                      //       children: [
                      //         Expanded(
                      //           child: GestureDetector(
                      //             onTap: () {
                      //               setState(() {
                      //                 processController.isIndividual.value =
                      //                     true;
                      //               });
                      //             },
                      //             child: Container(
                      //               alignment: Alignment.center,
                      //               decoration: BoxDecoration(
                      //                 color:
                      //                     processController.isIndividual.value
                      //                         ? AppColors.primaryColor
                      //                         : null,
                      //                 borderRadius: BorderRadius.circular(9),
                      //               ),
                      //               child: Text(
                      //                 'Inidividual',
                      //                 style: TextStyle(
                      //                   color:
                      //                       processController.isIndividual.value
                      //                           ? AppColors.white
                      //                           : null,
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //         Expanded(
                      //           child: GestureDetector(
                      //             onTap: () {
                      //               setState(() {
                      //                 processController.isIndividual.value =
                      //                     false;
                      //               });
                      //             },
                      //             child: Container(
                      //               alignment: Alignment.center,
                      //               decoration: BoxDecoration(
                      //                 color:
                      //                     !processController.isIndividual.value
                      //                         ? AppColors.primaryColor
                      //                         : null,
                      //                 borderRadius: BorderRadius.circular(9),
                      //               ),
                      //               child: Text(
                      //                 'Organization',
                      //                 style: TextStyle(
                      //                   color: !processController
                      //                           .isIndividual.value
                      //                       ? AppColors.white
                      //                       : null,
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         )
                      //       ],
                      //     ),
                      //   ),
                      // if (!isGuestLogin)
                      //   SizedBox(
                      //     height: 18,
                      //   ),
                      if (!isGuestLogin)
                        Text(
                          processController.isIndividual.value
                              ? "  Name"
                              : "  Organization Name",
                          style: TextStyle(
                              fontFamily: AppFonts.Montserrat,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      if (!isGuestLogin) SizedBox(height: 12),
                      if (!isGuestLogin)
                        AppTextField(
                          controller: processController.nameController,
                          keyboardType: TextInputType.text,
                          lableText: processController.isIndividual.value
                              ? "Enter your name"
                              : "Enter your organization name",
                        ),
                      if (!isGuestLogin) SizedBox(height: 18),
                      if (!isGuestLogin)
                        Text(
                          "  Username",
                          style: TextStyle(
                              fontFamily: AppFonts.Montserrat,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black),
                        ),
                      if (!isGuestLogin) SizedBox(height: 12),
                      if (!isGuestLogin)
                        AppTextField(
                          controller: processController.usernameController,
                          keyboardType: TextInputType.text,
                          lableText: "Enter your unique name",
                        ),
                      SizedBox(
                        height: 18,
                      ),
                      Text(
                        "  Country",
                        style: TextStyle(
                            fontFamily: AppFonts.Montserrat,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      SizedBox(height: 12),
                      Obx(
                        () => processController.countryLoading.value
                            ? Center(
                                child: CupertinoActivityIndicator(),
                              )
                            : AppDropDown(
                                hint: 'Select Country',
                                hintWidget: Text(
                                  processController.selectedCountry.value.name,
                                  style: TextStyle(
                                      fontFamily: AppFonts.Montserrat,
                                      color: processController
                                                  .selectedCountry.value.id ==
                                              ""
                                          ? Colors.black.withOpacity(0.51)
                                          : AppColors.black,
                                      fontSize: 14),
                                ),
                                items:
                                    processController.countryList.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Text(
                                      unit.name,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (unit) {
                                  print(unit.name);
                                  processController.selectedCountry.value =
                                      unit;

                                  processController.getState();
                                  processController.update();
                                },
                              ),
                      ),
                      // AppTextField(
                      //   controller: processController.cityController,
                      //   keyboardType: TextInputType.text,
                      //   lableText: "Enter city name",
                      // ),
                      SizedBox(height: 18),
                      Text(
                        "  State",
                        style: TextStyle(
                            fontFamily: AppFonts.Montserrat,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      SizedBox(height: 12),
                      Obx(() => processController.stateLoading.value
                          ? Center(
                              child: CupertinoActivityIndicator(),
                            )
                          : AppDropDown(
                              hint: 'Select State',
                              hintWidget: Obx(
                                () => Text(
                                  processController.selectedState.value.name,
                                  style: TextStyle(
                                      fontFamily: AppFonts.Montserrat,
                                      color: processController
                                                  .selectedState.value.id ==
                                              ""
                                          ? Colors.black.withOpacity(0.51)
                                          : AppColors.black,
                                      fontSize: 14),
                                ),
                              ),
                              items: processController.stateList.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit.name,
                                  ),
                                );
                              }).toList(),
                              onChanged: (unit) {
                                print(unit.name);
                                processController.selectedState.value = unit;
                                processController.selectedCity.value =
                                    LocationModel.empty(name: "Select City");
                                processController.selectedPostal.value =
                                    LocationModel.empty(name: "Select Postal");
                                processController.getCity();
                                processController.update();
                              },
                            )),
                      // AppTextField(
                      //   controller: processController.stateController,
                      //   keyboardType: TextInputType.text,
                      //   lableText: "Enter state name",
                      // ),
                      SizedBox(height: 18),
                      Text(
                        " City",
                        style: TextStyle(
                            fontFamily: AppFonts.Montserrat,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      SizedBox(height: 12),
                      Obx(() => processController.cityLoading.value
                          ? Center(
                              child: CupertinoActivityIndicator(),
                            )
                          : AppDropDown(
                              hint: 'Select City',
                              hintWidget: Obx(
                                () => Text(
                                  processController.selectedCity.value.name,
                                  style: TextStyle(
                                      fontFamily: AppFonts.Montserrat,
                                      color: processController
                                                  .selectedCity.value.id ==
                                              ""
                                          ? Colors.black.withOpacity(0.51)
                                          : AppColors.black,
                                      fontSize: 14),
                                ),
                              ),
                              items: processController.cityList.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit.name,
                                  ),
                                );
                              }).toList(),
                              onChanged: (unit) {
                                print(unit.name);
                                processController.selectedCity.value = unit;
                                processController.selectedPostal.value =
                                    LocationModel.empty(name: "Select Postal");
                                processController.getPostal();
                                processController.update();
                              },
                            )),
                      SizedBox(height: 18),

                      Text(
                        "  Postal",
                        style: TextStyle(
                            fontFamily: AppFonts.Montserrat,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      SizedBox(height: 12),
                      Obx(
                        () => processController.postalLoading.value
                            ? Center(
                                child: CupertinoActivityIndicator(),
                              )
                            : AppDropDown(
                                hint: 'Select Postal',
                                hintWidget: Obx(
                                  () => Text(
                                    processController.selectedPostal.value.name,
                                    style: TextStyle(
                                        fontFamily: AppFonts.Montserrat,
                                        color: processController
                                                    .selectedPostal.value.id ==
                                                ""
                                            ? Colors.black.withOpacity(0.51)
                                            : AppColors.black,
                                        fontSize: 14),
                                  ),
                                ),
                                items: processController.postalList.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Text(
                                      unit.name,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (unit) {
                                  print(unit.name);
                                  processController.selectedPostal.value = unit;
                                  processController.update();
                                },
                              ),
                      ),

                      SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 18,
            ),
            AppButton(
                onPressed: () async {
                  // save location data in either case of guest login or not
                  processController.saveLocationData(isGuestLogin);

                  // if is not guest login, save the profile data
                  if (!isGuestLogin) {
                    processController.saveProfileData();
                    return;
                  }

                  // if is guest login, save the data locally and move on to home tab screen
                  await _handleGuestLocaitonData();

                  // send the user to home now
                  Pref.setBool(Keys.IS_GUEST_LOGIN, true);
                  AppRoutes.navigateOffHomeTabScreen();
                },
                buttonText: "Continue"),
            SizedBox(
              height: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGuestLocaitonData() async {
    // setting location values in prefs
    await setPrefValue(
        Keys.STATE, jsonEncode(processController.selectedState.value.toJson()));
    await setPrefValue(
        Keys.CITY, jsonEncode(processController.selectedCity.value.toJson()));
    await setPrefValue(Keys.COUNTRY,
        jsonEncode(processController.selectedCountry.value.toJson()));
    await setPrefValue(Keys.POSTAL,
        jsonEncode(processController.selectedPostal.value.toJson()));

    // setting the selected states, default to the current home one
    await setPrefValue(
      Keys.PREFERRED_STATES,
      jsonEncode(
        [locationModelFromJson(getPrefValue(Keys.STATE)).name],
      ),
    );
  }

  // void _showBottomSheetForSelectingAffiliateText() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(10),
  //         topRight: Radius.circular(10),
  //       ),
  //     ),
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) => Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 20),
  //           child: SingleChildScrollView(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 SizedBox(
  //                   height: 20,
  //                 ),
  //                 AppTextField(
  //                   controller: processController.affiliateTextController,
  //                   lableText: 'Organization name',
  //                   onChange: (value) {
  //                     setState(() {
  //                       processController.affiliateTextController.text = value;

  //                       // if the value is not one of the party then set the affiliate pre defined image to empty
  //                       if (!parties.keys.toList().contains(value)) {
  //                         processController.affiliateImagePreDefinedPath.value =
  //                             '';
  //                       } else {
  //                         // if it is one of the party, then set the image path
  //                         processController.affiliateImagePreDefinedPath.value =
  //                             parties[value]!;
  //                       }
  //                     });
  //                   },
  //                 ),
  //                 SizedBox(
  //                   height: 20,
  //                 ),
  //                 Text(
  //                   'Organization names',
  //                   style: TextStyle(
  //                     fontFamily: AppFonts.Montserrat,
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w500,
  //                     color: Colors.black,
  //                   ),
  //                 ),
  //                 SizedBox(
  //                   height: 5,
  //                 ),
  //                 Text(
  //                   '*Choosing an "Organization name" will also update the organization icon associated with that organization name.',
  //                   style: TextStyle(
  //                     fontSize: 12,
  //                     color: Colors.grey,
  //                   ),
  //                 ),
  //                 SizedBox(
  //                   height: 20,
  //                 ),
  //                 Wrap(
  //                   spacing: 10,
  //                   runSpacing: 10,
  //                   children: parties.keys.map((e) {
  //                     // is the current one the active one?
  //                     bool isActive =
  //                         processController.affiliateTextController.text == e;

  //                     return GestureDetector(
  //                       onTap: () {
  //                         setState(() {
  //                           // updating the affiliate text
  //                           processController.affiliateTextController.text = e;

  //                           // updating the affiliate image
  //                           processController.affiliateImagePreDefinedPath
  //                               .value = parties[e]!;

  //                           // resetting the affiliate image file if any
  //                           processController.affiliateImageFile.value =
  //                               File('');
  //                         });
  //                       },
  //                       child: Container(
  //                         padding: EdgeInsets.symmetric(
  //                           horizontal: 20,
  //                           vertical: 13,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           borderRadius: BorderRadius.circular(10),
  //                           color: isActive
  //                               ? AppColors.primaryColor
  //                               : Colors.grey.withOpacity(.2),
  //                         ),
  //                         child: Text(e),
  //                       ),
  //                     );
  //                   }).toList(),
  //                 ),
  //                 SizedBox(
  //                   height: 20,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _showBottomSheetForSelectingAffiliateImage() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(10),
  //         topRight: Radius.circular(10),
  //       ),
  //     ),
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) => Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 20),
  //           child: SingleChildScrollView(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 SizedBox(
  //                   height: 20,
  //                 ),
  //                 Container(
  //                   width: double.infinity,
  //                   alignment: Alignment.center,
  //                   child: GestureDetector(
  //                     onTap: () {
  //                       processController.cameraAction(context, false);
  //                     },
  //                     child: Container(
  //                       padding: EdgeInsets.symmetric(
  //                         horizontal: 20,
  //                         vertical: 13,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: Colors.grey.withOpacity(.2),
  //                         borderRadius: BorderRadius.circular(5),
  //                       ),
  //                       child: Text(
  //                         'Choose Custom Image',
  //                         style: TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           decoration: TextDecoration.underline,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 Column(
  //                   children: [
  //                     SizedBox(
  //                       height: 20,
  //                     ),
  //                     Text(
  //                       'Political Party Symbols',
  //                       style: TextStyle(
  //                         fontFamily: AppFonts.Montserrat,
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w500,
  //                         color: Colors.black,
  //                       ),
  //                     ),
  //                     SizedBox(
  //                       height: 5,
  //                     ),
  //                     Text(
  //                       '*Choosing a predefined "Political Party Symbol" will also update the organization name associated with that political party symbol.',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: Colors.grey,
  //                       ),
  //                     ),
  //                     SizedBox(
  //                       height: 20,
  //                     ),
  //                     Wrap(
  //                       spacing: 10,
  //                       runSpacing: 10,
  //                       children: parties.keys.map((e) {
  //                         // is the current one the active one?
  //                         bool isActive =
  //                             processController.affiliateTextController.text ==
  //                                 e;

  //                         return GestureDetector(
  //                           onTap: () {
  //                             setState(() {
  //                               // updating the affiliate text
  //                               processController.affiliateTextController.text =
  //                                   e;

  //                               // updating the pre defined affiliate image path
  //                               processController.affiliateImagePreDefinedPath
  //                                   .value = parties[e]!;

  //                               // resetting the affiliate image file if any
  //                               processController.affiliateImageFile.value =
  //                                   File('');
  //                             });
  //                           },
  //                           child: Container(
  //                             height: 100,
  //                             width: 100,
  //                             decoration: BoxDecoration(
  //                               color: Colors.white,
  //                               border: Border.all(
  //                                 width: 5,
  //                                 color: isActive
  //                                     ? AppColors.primaryColor
  //                                     : Colors.white,
  //                               ),
  //                               borderRadius: BorderRadius.circular(200),
  //                             ),
  //                             child: Container(
  //                               height: 90,
  //                               width: 90,
  //                               decoration: BoxDecoration(
  //                                 borderRadius: BorderRadius.circular(200),
  //                                 color: Colors.grey.withOpacity(.2),
  //                               ),
  //                               child: ClipRRect(
  //                                 borderRadius: BorderRadius.circular(200),
  //                                 child: Image.asset(
  //                                   parties[e]!,
  //                                   fit: BoxFit.contain,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         );
  //                       }).toList(),
  //                     ),
  //                   ],
  //                 ),
  //                 SizedBox(
  //                   height: 20,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
