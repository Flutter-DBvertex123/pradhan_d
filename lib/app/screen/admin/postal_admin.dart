// ignore_for_file: constant_identifier_names

import 'package:chunaw/app/controller/admin/location_admin_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/screen/admin/add_location.dart';
import 'package:chunaw/app/screen/admin/location_admin.dart';
import 'package:chunaw/app/screen/admin/location_card.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PostalAdmin extends StatefulWidget {
  const PostalAdmin({Key? key}) : super(key: key);

  @override
  State<PostalAdmin> createState() => _PostalAdminState();
}

class _PostalAdminState extends State<PostalAdmin> {
  LocationAdminController adminController =
      Get.find<LocationAdminController>(tag: "locatio");

  @override
  void initState() {
    super.initState();
    adminController.getPostal();
    // getinit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: "Postal",
        scaffoldKey: null,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddLocation(type: LoactionType.Postal));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => adminController.pincodeLoading.value
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      adminController.getPostal();
                    },
                    child: ListView.builder(
                      itemCount: adminController.postalList.length,
                      padding: EdgeInsets.only(top: 10),
                      itemBuilder: (BuildContext context, int index) {
                        LocationModel locationModel =
                            adminController.postalList[index];
                        return GestureDetector(
                          onTap: () {
                            // switch (widget.type) {
                            //   case LoactionType.State:
                            //     adminController.stateId = locationModel.id;
                            //     print("state: ${adminController.stateId}");
                            //     Get.to(
                            //       () => CityAdmin(type: LoactionType.City),
                            //       preventDuplicates: false,
                            //     );
                            //     break;
                            //   case LoactionType.City:
                            // adminController.cityId = locationModel.id;
                            // print(
                            //     "state: ${adminController.stateId}, city:${adminController.cityId}");
                            //     Get.to(
                            //       () => CityAdmin(type: LoactionType.Postal),
                            //       preventDuplicates: false,
                            //     );
                            //     break;
                            //   case LoactionType.Postal:
                            //     break;
                            //   default:
                            // }
                          },
                          child: LocationCard(
                            locationModel: locationModel,
                            last:
                                index + 1 == adminController.postalList.length,
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
