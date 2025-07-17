// ignore_for_file: constant_identifier_names

import 'package:chunaw/app/controller/admin/location_admin_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/screen/admin/add_location.dart';
import 'package:chunaw/app/screen/admin/location_admin.dart';
import 'package:chunaw/app/screen/admin/location_card.dart';
import 'package:chunaw/app/screen/admin/postal_admin.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CityAdmin extends StatefulWidget {
  const CityAdmin({Key? key}) : super(key: key);

  @override
  State<CityAdmin> createState() => _CityAdminState();
}

class _CityAdminState extends State<CityAdmin> {
  LocationAdminController adminController =
      Get.find<LocationAdminController>(tag: "locatio");

  @override
  void initState() {
    super.initState();
    adminController.getCity();
    // getinit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: "City",
        scaffoldKey: null,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddLocation(type: LoactionType.City));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => adminController.cityLoading.value
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      adminController.getCity();
                    },
                    child: ListView.builder(
                      itemCount: adminController.cityList.length,
                      padding: EdgeInsets.only(top: 10),
                      itemBuilder: (BuildContext context, int index) {
                        LocationModel locationModel =
                            adminController.cityList[index];
                        return GestureDetector(
                          onTap: () {
                            adminController.cityId = locationModel.id;
                            print(
                                "state: ${adminController.stateId}, city:${adminController.cityId}");
                            Get.to(
                              () => PostalAdmin(),
                            );
                          },
                          child: LocationCard(
                            locationModel: locationModel,
                            last: index + 1 == adminController.cityList.length,
                          ),
                        );
                      },
                    ),
                  )),
          )
        ],
      ),
    );
  }
}
