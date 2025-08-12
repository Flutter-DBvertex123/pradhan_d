
import 'package:chunaw/app/controller/home/welcome_location_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../controller/auth/profile_process_controller.dart';
import '../../controller/location_features/pradhan_vote_controller.dart';
import '../../models/location_model.dart';
import '../../service/user_service.dart';
import '../../utils/app_bar.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../utils/app_pref.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_drop_down.dart';
class SelectElectionLocation extends StatefulWidget {
  const SelectElectionLocation({super.key});

  @override
  State<SelectElectionLocation> createState() => _SelectElectionLocationState();
}

class _SelectElectionLocationState extends State<SelectElectionLocation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LocationModel? selectedElectionLocation;

  // grabbing the process controller

  bool isCountry = false;
  bool isState = false;
  bool isCity = false;
  bool isPostal = false;
  LocationModel? country;
  LocationModel? state;
  LocationModel? city;
  LocationModel? postal;
  final PradhanVoteController welcomeController =
  Get.put(PradhanVoteController());
  String level = getPrefValue(Keys.LEVEL);

  @override
  void initState() {
    super.initState();

    // loading and prefilling the location data

print('dss :- level of user $level');
     country =
        locationModelFromJson(getPrefValue(Keys.COUNTRY));

     state =
        locationModelFromJson(getPrefValue(Keys.STATE));

     city =
        locationModelFromJson(getPrefValue(Keys.CITY));

     postal =
        locationModelFromJson(getPrefValue(Keys.POSTAL));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: 'Select Election Location',
        elevation: 0,
        leadingBack: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Country (Level 4)
              if (level == "4")
                _buildLocationTile(
                  title: "Country",
                  location: country,
                  isSelected: isCountry,
                  onTap: () {
                    selectedElectionLocation = country;
                    setState(() {
                      isCountry = true;
                      isState = isCity = isPostal = false;
                    });
                  },
                ),

              // State (Level 4 or 3)
              if (level == "4" || level == "3")
                _buildLocationTile(
                  title: "State",
                  location: state,
                  isSelected: isState,
                  onTap: () {
                    selectedElectionLocation = state;
                    setState(() {
                      isState = true;
                      isCountry = isCity = isPostal = false;
                    });
                  },
                ),

              // City (Level 4, 3, 2)
              if (level == "4" || level == "3" || level == "2")
                _buildLocationTile(
                  title: "City",
                  location: city,
                  isSelected: isCity,
                  onTap: () {
                    selectedElectionLocation = city;
                    setState(() {
                      isCity = true;
                      isCountry = isState = isPostal = false;
                    });
                  },
                ),

              // Postal (Always visible except maybe level 0)
              if (level == "4" || level == "3" || level == "2" || level == "1")
                _buildLocationTile(
                  title: "Postal",
                  location: postal,
                  isSelected: isPostal,
                  onTap: () {
                    selectedElectionLocation = postal;
                    setState(() {
                      isPostal = true;
                      isCountry = isState = isCity = false;
                    });
                  },
                ),

              const SizedBox(height: 18),

              AppButton(
                onPressed: () async {
                  if (selectedElectionLocation != null) {
                    await UserService.updateUserWithGivenFields(
                      userId: getPrefValue(Keys.USERID),
                      data: {
                        'preferred_election_location': {
                          'id': selectedElectionLocation!.id,
                          'name': selectedElectionLocation!.name,
                          'text': selectedElectionLocation!.text,
                        }
                      },
                      navigateToHomeAfterUpdate: false,
                    );
                  }
                },
                buttonText: "Continue",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTile({
    required String title,
    required LocationModel? location,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            " $title",
            style: TextStyle(
              fontFamily: AppFonts.Montserrat,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: AppColors.textBackColor,
            title: Text('${location?.name ?? title}'),
            trailing: isSelected
                ? Icon(Icons.check, color: AppColors.primaryColor)
                : const SizedBox(),
            onTap: onTap,
          ),
        ],
      ),
    );
  }
  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        title: 'Select Election Location',
        elevation: 0,
        leadingBack: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 18),
              Text(
                " Country",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              ListTile(
                tileColor: AppColors.textBackColor,
                title: Text('${country?.name ?? 'Country'}'),
                trailing: isCountry? Icon(Icons.check,color: AppColors.primaryColor) : SizedBox(),
                onTap: (){
                  selectedElectionLocation = country;
                  setState(() {
                    isPostal = false;
                    isCity = false;
                    isState = false;
                    isCountry = true;
                  });
                },

              ),
              SizedBox(height: 18),
              Text(
                " State",
                style: TextStyle(
                    fontFamily: AppFonts.Montserrat,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 12),
              ListTile(
                tileColor: AppColors.textBackColor,
                title: Text('${state?.name ?? 'State'}'),
                trailing: isState? Icon(Icons.check,color: AppColors.primaryColor) : SizedBox(),
                onTap: (){
                  selectedElectionLocation = state;
                  setState(() {
                    isPostal = false;
                    isCity = false;
                    isState = true;
                    isCountry = false;
                  });
                },
              ),
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
              ListTile(
                tileColor: AppColors.textBackColor,
                title: Text('${city?.name ?? 'City'}'),
                trailing: isCity? Icon(Icons.check,color: AppColors.primaryColor) : SizedBox(),
                onTap: (){
                  selectedElectionLocation = city;
                  setState(() {
                    isPostal = false;
                    isCity = true;
                    isState = false;
                    isCountry = false;
                  });
                },
              ),
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
              ListTile(

                tileColor: AppColors.textBackColor,
                title: Text('${postal?.name ?? 'Postal'}'),
                trailing: isPostal? Icon(Icons.check,color: AppColors.primaryColor) : SizedBox(),
                onTap: (){
                  selectedElectionLocation = postal;
                  setState(() {
                    isPostal = true;
                    isCity = false;
                    isState = false;
                    isCountry = false;
                  });
                },
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
                onPressed: () async {
                  print('dss : - ${selectedElectionLocation!.name}' );
                  if(selectedElectionLocation != null){
                    await UserService.updateUserWithGivenFields(
                      userId: getPrefValue(Keys.USERID),
                      data: {
                        'preferred_election_location': {
                          'id': selectedElectionLocation!.id,
                          'name': selectedElectionLocation!.name,
                          'text': selectedElectionLocation!.text,
                        }
                      },
                      navigateToHomeAfterUpdate: false,
                    );
                  }else{

                  }

                  // AppRoutes.navigateToLocationData();
                },
                buttonText: "Continue",
              ),
            ],
          ),
        ),
      ),
    );
  }*/
}
