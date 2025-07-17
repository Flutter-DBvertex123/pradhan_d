import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/controller/auth/profile_process_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_drop_down.dart';
import 'package:chunaw/app/widgets/app_text_field.dart';
import 'package:chunaw/app/widgets/app_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:chunaw/app/utils/parties_data.dart';

class ProfileUpdate extends StatefulWidget {
  const ProfileUpdate({Key? key}) : super(key: key);

  @override
  State<ProfileUpdate> createState() => _ProfileUpdateState();
}

class _ProfileUpdateState extends State<ProfileUpdate> {
  // to hold the existing affiliate text
  late final String initialAffiliateText;

  final ProfileProcessController processController =
      Get.put(ProfileProcessController(), tag: "UpdateProfile");
  @override
  void initState() {
    super.initState();
    print("""
    values:
    name: ${getPrefValue(Keys.NAME)},
    username: ${getPrefValue(Keys.USERNAME)},
    userdesc: ${getPrefValue(Keys.USER_DESC)},
    country: ${getPrefValue(Keys.COUNTRY)},
    state: ${getPrefValue(Keys.STATE)},
    city: ${getPrefValue(Keys.CITY)},
    pincode: ${getPrefValue(Keys.POSTAL)},
    affilatetext: ${getPrefValue(Keys.AFFILIATE_TEXT)},
    affiliatephoto: ${getPrefValue(Keys.AFFILIATE_PHOTO)},
    """);
    processController.nameController.text = getPrefValue(Keys.NAME);
    processController.usernameController.text = getPrefValue(Keys.USERNAME);
    processController.userdescController.text = getPrefValue(Keys.USER_DESC);
    processController.getCountry();

    processController.selectedCountry.value =
        locationModelFromJson(getPrefValue(Keys.COUNTRY));
    processController.getState();
    processController.selectedState.value =
        locationModelFromJson(getPrefValue(Keys.STATE));
    processController.getCity();
    processController.selectedCity.value =
        locationModelFromJson(getPrefValue(Keys.CITY));
    processController.getPostal();
    processController.selectedPostal.value =
        locationModelFromJson(getPrefValue(Keys.POSTAL));
    processController.affiliateTextController.text =
        getPrefValue(Keys.AFFILIATE_TEXT);
    processController.addressController.text =
        getPrefValue(Keys.ORGANIZATION_ADDRESS);
    processController.isIndividual.value =
        getPrefValue(Keys.IS_ORGANIZATION) == 'true' ? false : true;

    initialAffiliateText = getPrefValue(Keys.AFFILIATE_TEXT);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Edit Profile',
        scaffoldKey: null,
        elevation: 0,
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 18),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Image.asset(
                        AppAssets.bannerImage,
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                    Positioned(
                      bottom: -70,
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.white.withOpacity(0.3),
                        child: Center(
                          child: CircleAvatar(
                            radius: 55.r,
                            backgroundColor: AppColors.gradient1,
                            child: ClipOval(
                              clipBehavior: Clip.hardEdge,
                              child: Obx(
                                () => processController.imageFile.value.path ==
                                        ''
                                    ? CachedNetworkImage(
                                        placeholder: (context, error) {
                                          // printError();
                                          return CircleAvatar(
                                            radius: 55.r,
                                            backgroundColor:
                                                AppColors.gradient1,
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                              color: AppColors.highlightColor,
                                            )),
                                          );
                                        },
                                        errorWidget:
                                            (context, error, stackTrace) {
                                          // printError();
                                          return Image.asset(
                                            AppAssets.brokenImage,
                                            fit: BoxFit.fitHeight,
                                            // width: 160.0,
                                            height: 200.0,
                                          );
                                        },
                                        imageUrl:
                                            getPrefValue(Keys.PROFILE_PHOTO),
                                        // .replaceAll('\', '//'),
                                        fit: BoxFit.fitHeight,
                                        // width: 160.0,
                                        height: 160.0,
                                      )
                                    : Image.file(
                                        processController.imageFile.value,
                                        fit: BoxFit.fitHeight,
                                        // width: 160.0,
                                        height: 200.0,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        // child: CircleAvatar(
                        //   radius: 55.r,
                        //   backgroundColor: AppColors.gradient1,
                        // ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 75),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      processController.cameraAction(context, true);
                    },
                    child: Container(
                      // width: 40,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primaryColor, width: 3),
                          borderRadius: BorderRadius.circular(15)),
                      // alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13.0, vertical: 5),
                        child: Text("Edit"),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // Text(
                //   ' Individual or Organization?',
                //   style: TextStyle(
                //     fontFamily: AppFonts.Montserrat,
                //     fontSize: 16,
                //     fontWeight: FontWeight.w500,
                //     color: Colors.black,
                //   ),
                // ),
                // SizedBox(
                //   height: 12,
                // ),
                // Container(
                //   padding: EdgeInsets.all(4),
                //   height: 59,
                //   decoration: BoxDecoration(
                //     color: AppColors.textBackColor,
                //     borderRadius: BorderRadius.circular(9),
                //     border: Border.all(
                //       color: AppColors.borderColorGrey,
                //       width: 1.5,
                //     ),
                //   ),
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: GestureDetector(
                //           onTap: () {
                //             setState(() {
                //               processController.isIndividual.value = true;
                //             });
                //           },
                //           child: Container(
                //             alignment: Alignment.center,
                //             decoration: BoxDecoration(
                //               color: processController.isIndividual.value
                //                   ? AppColors.primaryColor
                //                   : null,
                //               borderRadius: BorderRadius.circular(9),
                //             ),
                //             child: Text(
                //               'Inidividual',
                //               style: TextStyle(
                //                 color: processController.isIndividual.value
                //                     ? AppColors.white
                //                     : null,
                //               ),
                //             ),
                //           ),
                //         ),
                //       ),
                //       Expanded(
                //         child: GestureDetector(
                //           onTap: () {
                //             setState(() {
                //               processController.isIndividual.value = false;
                //
                //               // also resetting the pre defined image and text if there is any
                //               processController
                //                   .affiliateImagePreDefinedPath.value = '';
                //
                //               processController.affiliateTextController.text =
                //                   '';
                //             });
                //           },
                //           child: Container(
                //             alignment: Alignment.center,
                //             decoration: BoxDecoration(
                //               color: !processController.isIndividual.value
                //                   ? AppColors.primaryColor
                //                   : null,
                //               borderRadius: BorderRadius.circular(9),
                //             ),
                //             child: Text(
                //               'Organization',
                //               style: TextStyle(
                //                 color: !processController.isIndividual.value
                //                     ? AppColors.white
                //                     : null,
                //               ),
                //             ),
                //           ),
                //         ),
                //       )
                //     ],
                //   ),
                // ),
                // SizedBox(
                //   height: 18,
                // ),
                Text(
                  !processController.isIndividual.value
                      ? "Organization name"
                      : "  Name",
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                SizedBox(height: 12),
                AppTextField(
                  controller: processController.nameController,
                  keyboardType: TextInputType.text,
                  lableText: !processController.isIndividual.value
                      ? "Enter your organization name"
                      : "Enter your name",
                ),
                SizedBox(height: 18),
                Text(
                  "  Username",
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                SizedBox(height: 12),
                AppTextField(
                  controller: processController.usernameController,
                  keyboardType: TextInputType.text,
                  lableText: "Enter your unique name",
                ),
                SizedBox(height: 18),
                Text(
                  "  User Description",
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                SizedBox(height: 12),
                AppTextField(
                  controller: processController.userdescController,
                  keyboardType: TextInputType.multiline,
                  inputAction: TextInputAction.newline,
                  lableText: "Write a few words about you",
                  minLines: 9,
                  maxLines: 17,
                ),
                SizedBox(
                  height: 18,
                ),
                if (!processController.isIndividual.value)
                  Text(
                    " Organization Address",
                    style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                if (!processController.isIndividual.value)
                  SizedBox(
                    height: 12,
                  ),
                if (!processController.isIndividual.value)
                  AppTextField(
                    controller: processController.addressController,
                    keyboardType: TextInputType.multiline,
                    inputAction: TextInputAction.newline,
                    lableText: "ABC street, high road ...",
                    minLines: 3,
                    maxLines: 5,
                  ),
                if (!processController.isIndividual.value)
                  SizedBox(
                    height: 18,
                  ),
                if (processController.isIndividual.value)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            " Associated With Any Organization",
                            style: TextStyle(
                                fontFamily: AppFonts.Montserrat,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black),
                          ),
                          GestureDetector(
                            onTap: () async {
                              await _showBottomSheetForSelectingAffiliateText();

                              setState(() {});
                            },
                            child: Icon(Icons.edit),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      AppTextField(
                        controller: processController.affiliateTextController,
                        enabled: false,
                      ),
                      SizedBox(
                        height: 18,
                      ),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      " Organization Icon",
                      style: TextStyle(
                          fontFamily: AppFonts.Montserrat,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    processController.affiliateImagePreDefinedPath.value.isEmpty
                        ? GestureDetector(
                            onTap: () {
                              processController.cameraAction(context, false);
                            },
                            child: Icon(Icons.edit),
                          )
                        : const SizedBox(),
                  ],
                ),
                SizedBox(height: 12),
                CircleAvatar(
                  radius: 60.r,
                  backgroundColor: AppColors.white.withOpacity(0.3),
                  child: Center(
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundColor: AppColors.gradient1,
                      child: ClipOval(
                        clipBehavior: Clip.hardEdge,
                        child: Obx(() => processController
                                    .affiliateImageFile.value.path ==
                                ''
                            ? processController
                                    .affiliateImagePreDefinedPath.isNotEmpty
                                ? Image.asset(
                                    processController
                                        .affiliateImagePreDefinedPath.value,
                                    fit: BoxFit.contain,
                                    height: 200,
                                  )
                                : CachedNetworkImage(
                                    placeholder: (context, error) {
                                      return CircleAvatar(
                                        radius: 50.r,
                                        backgroundColor: AppColors.gradient1,
                                        child: Center(
                                            child: CircularProgressIndicator(
                                          color: AppColors.highlightColor,
                                        )),
                                      );
                                    },
                                    errorWidget: (context, error, stackTrace) {
                                      return Image.asset(
                                        AppAssets.brokenImage,
                                        fit: BoxFit.fitHeight,
                                        height: 200.0.w,
                                      );
                                    },
                                    imageUrl:
                                        getPrefValue(Keys.AFFILIATE_PHOTO),
                                    fit: BoxFit.fitHeight,
                                    height: 200.0,
                                  )
                            : Image.file(
                                processController.affiliateImageFile.value,
                                fit: BoxFit.fitHeight,
                                height: 200.0,
                              )),
                      ),
                    ),
                  ),
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
                // AppTextField(
                //   controller: processController.cityController,
                //   keyboardType: TextInputType.text,
                //   lableText: "Enter city name",
                // ),
                Obx(
                  () => processController.countryLoading.value
                      ? Center(
                          child: CupertinoActivityIndicator(),
                        )
                      : AppDropDown(
                          hint: 'Select Country',
                          hintWidget: Obx(
                            () => Text(
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
                          ),
                          items: processController.countryList.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(
                                unit.name,
                              ),
                            );
                          }).toList(),
                          onChanged: (unit) {
                            // if unit is same as before, return
                            if (unit.id ==
                                processController.selectedCountry.value.id) {
                              return;
                            }

                            print(unit.name);
                            processController.selectedCountry.value = unit;

                            processController.getState();

                            // resetting state, city, and postal
                            processController.resetState();
                            processController.resetCity();
                            processController.resetPostal();

                            processController.update();
                          },
                        ),
                ),
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
                                color:
                                    processController.selectedState.value.id ==
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
                        onChanged: processController
                                .selectedCountry.value.id.isEmpty
                            ? null
                            : (unit) {
                                // if unit is same, return
                                if (unit.id ==
                                    processController.selectedState.value.id) {
                                  return;
                                }

                                print(unit.name);
                                processController.selectedState.value = unit;
                                processController.getCity();

                                // resetting city and postal
                                processController.resetCity();
                                processController.resetPostal();

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
                                color:
                                    processController.selectedCity.value.id ==
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
                        onChanged: processController
                                .selectedState.value.id.isEmpty
                            ? null
                            : (unit) {
                                // if city is same, return
                                if (unit.id ==
                                    processController.selectedCity.value.id) {
                                  return;
                                }

                                print(unit.name);
                                processController.selectedCity.value = unit;
                                processController.getPostal();

                                // resetting postal
                                processController.resetPostal();

                                processController.update();
                              },
                      )),
                SizedBox(height: 18),
                Text(
                  " Postal",
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
                          onChanged: processController
                                  .selectedCity.value.id.isEmpty
                              ? null
                              : (unit) {
                                  print(unit.name);
                                  processController.selectedPostal.value = unit;
                                  processController.update();
                                },
                        ),
                ),
                SizedBox(height: 18),

                // Text(
                //   "  Pincode",
                //   style: TextStyle(
                //       fontFamily: AppFonts.Montserrat,
                //       fontSize: 16,
                //       fontWeight: FontWeight.w500,
                //       color: Colors.black),
                // ),
                // SizedBox(height: 12),
                // AppTextField(
                //   controller: processController.pincodeController,
                //   keyboardType: TextInputType.text,
                //   lableText: "Enter pincode",
                // ),
                // SizedBox(height: 18),

                AppButton(
                    onPressed: () {
                      // grabbing the lowercase party names
                      final partyNames =
                          parties.keys.map((e) => e.toLowerCase()).toList();

                      // if custom party name is set and if initial affiliate text was a party then the new affiliate image must be there
                      if (!partyNames.contains(processController
                              .affiliateTextController.text
                              .toLowerCase()) &&
                          partyNames
                              .contains(initialAffiliateText.toLowerCase()) &&
                          processController
                              .affiliateImageFile.value.path.isEmpty) {
                        longToastMessage(
                            'Please set a custom affiliate image. Current affiliate image is already reserved to a party');
                        return;
                      }

                      // if an individual then also resetting the address here
                      if (processController.isIndividual.value) {
                        setState(() {
                          processController.addressController.text = '';
                        });
                      } else {
                        // if not an individual then check the name
                        // name can not be as same as an existing party
                        if (partyNames.contains(processController
                            .nameController.text
                            .toLowerCase())) {
                          longToastMessage(
                              'This organization name is reserved. Please choose something else.');
                          return;
                        }
                      }

                      processController.updateData();
                      // AppRoutes.navigateToLocationData();
                    },
                    buttonText: "Continue"),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBottomSheetForSelectingAffiliateText() async {
    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  AppTextField(
                    controller: processController.affiliateTextController,
                    lableText: 'Affiliate text',
                    onChange: (value) {
                      setState(() {
                        processController.affiliateTextController.text = value;

                        // if the value is not one of the party then set the affiliate pre defined image to empty
                        if (!parties.keys.toList().contains(value)) {
                          processController.affiliateImagePreDefinedPath.value =
                              '';
                        } else {
                          // if it is one of the party, then set the image path
                          processController.affiliateImagePreDefinedPath.value =
                              parties[value]!;
                        }
                      });
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Organization names',
                    style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    '*Choosing an "Organization name" will also update the organization icon associated with that organization name.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: parties.keys.map((e) {
                      // is the current one the active one?
                      bool isActive =
                          processController.affiliateTextController.text == e;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // updating the affiliate text
                            processController.affiliateTextController.text = e;

                            // updating the affiliate image
                            processController.affiliateImagePreDefinedPath
                                .value = parties[e]!;

                            // resetting the affiliate image file if any
                            processController.affiliateImageFile.value =
                                File('');
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isActive
                                ? AppColors.primaryColor
                                : Colors.grey.withOpacity(.2),
                          ),
                          child: Text(e),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
