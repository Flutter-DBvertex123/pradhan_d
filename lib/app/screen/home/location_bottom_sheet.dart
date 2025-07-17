import 'package:chunaw/app/controller/home/home_controller.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_drop_down.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationBottomSheet extends StatelessWidget {
  LocationBottomSheet({Key? key}) : super(key: key);
  final HomeController homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              // Text(
              //   "  Filter By",
              //   style: TextStyle(
              //       fontFamily: AppFonts.Montserrat,
              //       fontSize: 16,
              //       fontWeight: FontWeight.w500,
              //       color: Colors.black),
              // ),
              // Row(
              //   children: [
              //     Obx(() => Radio(
              //           value: 0,
              //           groupValue: homeController.filterby.value,
              //           onChanged: (v) {
              //             homeController.filterby.value = v!;
              //           },
              //         )),
              //     Text("Postal"),
              //     Obx(() => Radio(
              //           value: 1,
              //           groupValue: homeController.filterby.value,
              //           onChanged: (v) {
              //             homeController.filterby.value = v!;
              //           },
              //         )),
              //     Text("City"),
              //     Obx(() => Radio(
              //         value: 2,
              //         groupValue: homeController.filterby.value,
              //         onChanged: (v) {
              //           homeController.filterby.value = v!;
              //         })),
              //     Text("State"),
              //   ],
              // ),
              SizedBox(height: 15),

              Obx(() => homeController.filterby.value == 3
                  ? showState()
                  : Container()),
              Obx(() => homeController.filterby.value == 2
                  ? showCity()
                  : Container()),
              Obx(() => homeController.filterby.value == 1
                  ? showPostal()
                  : Container()),
              // SizedBox(height: Get.height * 0.16.sp),
              AppButton(
                  onPressed: () {
                    homeController.applyFilter();
                    homeController.getPosts(homeController.filterby.value);
                    homeController.getSachiv(homeController.filterby.value);
                  },
                  buttonText: "Apply Filter"),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  showState() {
    return Column(
      children: [
        Text(
          "  State",
          style: TextStyle(
              fontFamily: AppFonts.Montserrat,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black),
        ),
        SizedBox(height: 12),
        Obx(() => homeController.stateLoading.value
            ? Center(
                child: CupertinoActivityIndicator(),
              )
            : AppDropDown(
                hint: 'Select State',
                hintWidget: Obx(
                  () => Text(
                    homeController.selectedState.value.name,
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        color: homeController.selectedState.value.id == ""
                            ? Colors.black.withOpacity(0.51)
                            : AppColors.black,
                        fontSize: 14),
                  ),
                ),
                items: homeController.stateList.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit.name,
                    ),
                  );
                }).toList(),
                onChanged: (unit) {
                  print(unit.name);
                  homeController.selectedState.value = unit;
                  // homeController.selectedCity.value =
                  //     LocationModel.empty(name: "");
                  // homeController.selectedPostal.value =
                  //     LocationModel.empty(name: "");
                  homeController.getCity();
                  homeController.update();
                },
              )),
        SizedBox(height: 18),
      ],
    );
  }

  showPostal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  Postal",
          style: TextStyle(
              fontFamily: AppFonts.Montserrat,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black),
        ),
        SizedBox(height: 12),
        Obx(() => homeController.postalLoading.value
            ? Center(
                child: CupertinoActivityIndicator(),
              )
            : AppDropDown(
                hint: 'Select Postal',
                hintWidget: Obx(
                  () => Text(
                    homeController.selectedPostal.value.name,
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        color: homeController.selectedPostal.value.id == ""
                            ? Colors.black.withOpacity(0.51)
                            : AppColors.black,
                        fontSize: 14),
                  ),
                ),
                items: homeController.postalList.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit.name,
                    ),
                  );
                }).toList(),
                onChanged: (unit) {
                  print(unit.name);
                  homeController.selectedPostal.value = unit;
                  homeController.update();
                },
              )),
        SizedBox(height: 18),
      ],
    );
  }

  showCity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  City",
          style: TextStyle(
              fontFamily: AppFonts.Montserrat,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black),
        ),
        SizedBox(height: 12),
        Obx(() => homeController.cityLoading.value
            ? Center(
                child: CupertinoActivityIndicator(),
              )
            : AppDropDown(
                hint: 'Select City',
                hintWidget: Obx(
                  () => Text(
                    homeController.selectedCity.value.name,
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        color: homeController.selectedCity.value.id == ""
                            ? Colors.black.withOpacity(0.51)
                            : AppColors.black,
                        fontSize: 14),
                  ),
                ),
                items: homeController.cityList.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit.name,
                    ),
                  );
                }).toList(),
                onChanged: (unit) {
                  print(unit.name);
                  homeController.selectedCity.value = unit;
                  // homeController.selectedPostal.value =
                  //     LocationModel.empty(name: "Select Postal");
                  homeController.getPostal();
                  homeController.update();
                },
              )),
        SizedBox(height: 18),
      ],
    );
  }
}
