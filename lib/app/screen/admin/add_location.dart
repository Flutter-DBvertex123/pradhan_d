import 'package:chunaw/app/controller/admin/location_admin_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/screen/admin/location_admin.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:chunaw/app/utils/app_fonts.dart';
import 'package:chunaw/app/widgets/app_button.dart';
import 'package:chunaw/app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddLocation extends StatefulWidget {
  const AddLocation({Key? key, required this.type}) : super(key: key);
  final LoactionType type;

  @override
  State<AddLocation> createState() => _AddLocationState();
}

class _AddLocationState extends State<AddLocation> {
  TextEditingController idController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController textController = TextEditingController();
  final LocationAdminController adminController =
      Get.find<LocationAdminController>(tag: "locatio");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: "Add Location",
        scaffoldKey: null,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 18),
            Text(
              "  Id",
              style: TextStyle(
                  fontFamily: AppFonts.Montserrat,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
            SizedBox(height: 12),
            AppTextField(
              controller: idController,
              keyboardType: TextInputType.text,
              lableText: "Enter unique id",
            ),
            SizedBox(height: 18),
            Text(
              "  Name",
              style: TextStyle(
                  fontFamily: AppFonts.Montserrat,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
            SizedBox(height: 12),
            AppTextField(
              controller: nameController,
              keyboardType: TextInputType.text,
              lableText: "Enter unique name",
            ),
            SizedBox(height: 18),
            Text(
              "  Text",
              style: TextStyle(
                  fontFamily: AppFonts.Montserrat,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
            SizedBox(height: 12),
            AppTextField(
              controller: textController,
              keyboardType: TextInputType.text,
              lableText: "Enter unique text",
            ),
            SizedBox(height: 18),
            AppButton(
                onPressed: () {
                  LocationModel locationModel = LocationModel(
                      name: nameController.text,
                      text: textController.text,
                      id: idController.text);
                  switch (widget.type) {
                    case LoactionType.State:
                      adminController.addState(locationModel);
                      break;
                    case LoactionType.City:
                      adminController.addCity(locationModel);
                      break;
                    case LoactionType.Postal:
                      adminController.addPostal(locationModel);
                      break;
                  }
                },
                buttonText: "Add"),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
