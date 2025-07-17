import 'package:chunaw/app/controller/auth/profile_process_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_drop_down.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditHomeLocationPage extends StatefulWidget {
  const EditHomeLocationPage({super.key});

  @override
  State<EditHomeLocationPage> createState() => _EditHomeLocationPageState();
}

class _EditHomeLocationPageState extends State<EditHomeLocationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // grabbing the process controller
  final ProfileProcessController processController =
      Get.put(ProfileProcessController(), tag: "UpdateProfile");

  @override
  void initState() {
    super.initState();

    // loading and prefilling the location data
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: 'Edit Home Location',
        elevation: 0,
        leadingBack: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                  processController.selectedState.value.id == ""
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
                                  processController.selectedCity.value.id == ""
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
                      onChanged:
                          processController.selectedState.value.id.isEmpty
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
                                color:
                                    processController.selectedPostal.value.id ==
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
                  processController.updateLocationData();
                  // AppRoutes.navigateToLocationData();
                },
                buttonText: "Continue",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
