import 'package:cached_network_image/cached_network_image.dart';
import 'package:chunaw/app/dbvertex/organisations/organisation_controller.dart';
import 'package:chunaw/app/dbvertex/organisations/organization_details_controller.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/app_assets.dart';
import '../../utils/app_bar.dart';
import '../../utils/app_fonts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_drop_down.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';

class CreateOrganisationScreen extends StatefulWidget {
  final String? organizationId;
  const CreateOrganisationScreen({super.key, this.organizationId});

  @override
  State<StatefulWidget> createState() => CreateOrganisationState();
}

class CreateOrganisationState extends State<CreateOrganisationScreen>
    with SingleTickerProviderStateMixin {
  final organisationController =
      Get.put(OrganisationController(), tag: 'organisation');
  final controller = Get.put(OrganizationDetailsController());
  late final isUpdating = widget.organizationId != null;

  final visibilityModes = ['Private', 'Public'];

  @override
  void initState() {
    super.initState();

    if (isUpdating) {
      organisationController.initialize(widget.organizationId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
        value: SystemUiOverlayStyle(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBarCustom(
            leadingBack: true,
            title: '${isUpdating ? 'Update' : 'Create'} Organization',
            elevation: 0,
          ),
          body: Obx(() {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: organisationController.isLoading.value
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._createVisibilityModes(),
                          ..._createTextField('Organization Name',
                              organisationController.nameController,
                              maxLength: 30),
                          ..._createTextField('Organization Description',
                              organisationController.descController,
                              maxLength: 200, maxLines: 3),
                          if (!isUpdating)
                            ..._createTextField('Street Address',
                                organisationController.addressController,
                                maxLength: 150),
                          ..._createOrganisationIconField(),
                          if (!isUpdating) ..._createLocationSelector(),
                          ..._createContinueButton(),
                        ],
                      ),
                    ),
            );
          }),
        ));
  }

  List<Widget> _createOrganisationIconField() {
    return [
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
          GestureDetector(
            onTap: () {
              organisationController.cameraAction(context);
            },
            child: Icon(Icons.edit),
          )
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
              child: Obx(() => organisationController.organisationIcon.value
                          ?.existsSync() ==
                      true
                  ? Image.file(
                      organisationController.organisationIcon.value!,
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
                            ),
                          ),
                        );
                      },
                      errorWidget: (context, error, stackTrace) {
                        return Image.asset(
                          AppAssets.brokenImage,
                          fit: BoxFit.fill,
                          height: 200.0.w,
                        );
                      },
                      imageUrl: organisationController.organizationImage.value,
                      fit: BoxFit.fitHeight,
                      height: 200.0,
                    )),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _createVisibilityModes() {
    return [
      SizedBox(height: 10),
      Text(
        ' Organization Visibility',
        textAlign: TextAlign.start,
        style: TextStyle(
          fontFamily: AppFonts.Montserrat,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      SizedBox(
        height: 12,
      ),
      Obx(() {
        return Container(
          padding: EdgeInsets.all(4),
          height: 59,
          decoration: BoxDecoration(
            color: AppColors.textBackColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: AppColors.borderColorGrey,
              width: 1.5,
            ),
          ),
          child: Row(
            children: visibilityModes.map((visibility) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    organisationController.visibility.value = visibility;
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          visibility == organisationController.visibility.value
                              ? AppColors.primaryColor
                              : null,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      visibility,
                      style: TextStyle(
                        color: visibility ==
                                organisationController.visibility.value
                            ? AppColors.white
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
      SizedBox(
        height: 18,
      )
    ];
  }

  List<Widget> _createTextField(String label, TextEditingController controller,
      {int? maxLength, int? maxLines}) {
    return [
      Text(
        "  $label",
        style: TextStyle(
            fontFamily: AppFonts.Montserrat,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black),
      ),
      SizedBox(height: 12),
      AppTextField(
          controller: controller,
          maxLines: maxLines ?? 1,
          counterText: '',
          limit: maxLength,
          keyboardType: TextInputType.text,
          lableText: label.split(' ').last),
      SizedBox(height: 18)
    ];
  }

  List<Widget> _createLocationSelector() {
    return [
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
        () => organisationController.countryLoading.value
            ? Center(
                child: CupertinoActivityIndicator(),
              )
            : AppDropDown(
                hint: 'Select Country',
                hintWidget: Obx(
                  () => Text(
                    organisationController.selectedCountry.value.name,
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        color:
                            organisationController.selectedCountry.value.id ==
                                    ""
                                ? Colors.black.withOpacity(0.51)
                                : AppColors.black,
                        fontSize: 14),
                  ),
                ),
                items: organisationController.countryList.map((unit) {
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
                      organisationController.selectedCountry.value.id) {
                    return;
                  }

                  organisationController.selectedCountry.value = unit;

                  organisationController.getState();

                  // resetting state, city, and postal
                  organisationController.resetState();
                  organisationController.resetCity();
                  organisationController.resetPostal();

                  organisationController.update();
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
      Obx(() => organisationController.stateLoading.value
          ? Center(
              child: CupertinoActivityIndicator(),
            )
          : AppDropDown(
              hint: 'Select State',
              hintWidget: Obx(
                () => Text(
                  organisationController.selectedState.value.name,
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      color: organisationController.selectedState.value.id == ""
                          ? Colors.black.withOpacity(0.51)
                          : AppColors.black,
                      fontSize: 14),
                ),
              ),
              items: organisationController.stateList.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(
                    unit.name,
                  ),
                );
              }).toList(),
              onChanged: organisationController.selectedCountry.value.id.isEmpty
                  ? null
                  : (unit) {
                      // if unit is same, return
                      if (unit.id ==
                          organisationController.selectedState.value.id) {
                        return;
                      }

                      print(unit.name);
                      organisationController.selectedState.value = unit;
                      organisationController.getCity();

                      // resetting city and postal
                      organisationController.resetCity();
                      organisationController.resetPostal();

                      organisationController.update();
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
      Obx(() => organisationController.cityLoading.value
          ? Center(
              child: CupertinoActivityIndicator(),
            )
          : AppDropDown(
              hint: 'Select City',
              hintWidget: Obx(
                () => Text(
                  organisationController.selectedCity.value.name,
                  style: TextStyle(
                      fontFamily: AppFonts.Montserrat,
                      color: organisationController.selectedCity.value.id == ""
                          ? Colors.black.withOpacity(0.51)
                          : AppColors.black,
                      fontSize: 14),
                ),
              ),
              items: organisationController.cityList.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(
                    unit.name,
                  ),
                );
              }).toList(),
              onChanged: organisationController.selectedState.value.id.isEmpty
                  ? null
                  : (unit) {
                      // if city is same, return
                      if (unit.id ==
                          organisationController.selectedCity.value.id) {
                        return;
                      }

                      print(unit.name);
                      organisationController.selectedCity.value = unit;
                      organisationController.getPostal();

                      // resetting postal
                      organisationController.resetPostal();

                      organisationController.update();
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
        () => organisationController.postalLoading.value
            ? Center(
                child: CupertinoActivityIndicator(),
              )
            : AppDropDown(
                hint: 'Select Postal',
                hintWidget: Obx(
                  () => Text(
                    organisationController.selectedPostal.value.name,
                    style: TextStyle(
                        fontFamily: AppFonts.Montserrat,
                        color:
                            organisationController.selectedPostal.value.id == ""
                                ? Colors.black.withOpacity(0.51)
                                : AppColors.black,
                        fontSize: 14),
                  ),
                ),
                items: organisationController.postalList.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit.name,
                    ),
                  );
                }).toList(),
                onChanged: organisationController.selectedCity.value.id.isEmpty
                    ? null
                    : (unit) {
                        print(unit.name);
                        organisationController.selectedPostal.value = unit;
                        organisationController.update();
                      },
              ),
      ),
      SizedBox(height: 18),
    ];
  }

  List<Widget> _createContinueButton() {
    return [
      if (isUpdating) SizedBox(height: 16),
      AppButton(
          onPressed: () async {
            bool result = await organisationController
                .createOrganisation(widget.organizationId);
            if (result) {
              longToastMessage(
                  'Organization ${isUpdating ? 'updated' : 'created'}.');
              Get.back();
            }
          },
          buttonText: isUpdating ? "Update" : "Create"),
      SizedBox(height: 50)
    ];
  }
}
