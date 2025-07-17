// ignore_for_file: constant_identifier_names

import 'package:chunaw/app/controller/admin/location_admin_controller.dart';
import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/screen/admin/add_location.dart';
import 'package:chunaw/app/screen/admin/city_admin.dart';
import 'package:chunaw/app/screen/admin/location_card.dart';
import 'package:chunaw/app/utils/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum LoactionType { State, City, Postal }

class LocationAdmin extends StatefulWidget {
  const LocationAdmin({Key? key, required this.type}) : super(key: key);
  final LoactionType type;

  @override
  State<LocationAdmin> createState() => _LocationAdminState();
}

class _LocationAdminState extends State<LocationAdmin> {
  late LocationAdminController adminController =
      Get.put(LocationAdminController(), tag: "locatio");

  @override
  void initState() {
    super.initState();
    adminController.getStates();
    // getinit();
  }

  getinit() {
    switch (widget.type) {
      case LoactionType.State:
        // adminController =

        break;
      case LoactionType.City:
        adminController = Get.find<LocationAdminController>(tag: "locatio");
        adminController.getCity();
        break;
      case LoactionType.Postal:
        adminController = Get.find<LocationAdminController>(tag: "locatio");
        adminController.getPostal();
        break;
      default:
        adminController = Get.put(LocationAdminController(), tag: "locatio");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: "States",
        scaffoldKey: null,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => AddLocation(type: LoactionType.State));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => adminController.stateLoading.value
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      switch (widget.type) {
                        case LoactionType.State:
                          adminController.getStates();
                          break;
                        case LoactionType.City:
                          adminController.getCity();

                          break;
                        case LoactionType.Postal:
                          adminController.getPostal();
                          break;
                        default:
                          adminController.getStates();
                      }
                    },
                    child: ListView.builder(
                      itemCount: adminController.stateList.length,
                      padding: EdgeInsets.only(top: 10),
                      itemBuilder: (BuildContext context, int index) {
                        LocationModel locationModel =
                            adminController.stateList[index];
                        return GestureDetector(
                          onTap: () {
                            adminController.stateId = locationModel.id;
                            print("state: ${adminController.stateId}");
                            Get.to(
                              () => CityAdmin(),
                            );
                          },
                          child: LocationCard(
                            locationModel: locationModel,
                            last: index + 1 == adminController.stateList.length,
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
