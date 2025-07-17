import 'package:chunaw/app/dbvertex/ishwar_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/location_model.dart';
import '../service/collection_name.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_pref.dart';
import 'level_selector_sheet.dart';

class GetFreeAutoRideScreen extends StatefulWidget {
  const GetFreeAutoRideScreen({super.key});

  @override
  State<StatefulWidget> createState() => _GetFreeAutoRideState();

}

class _GetFreeAutoRideState extends State<GetFreeAutoRideScreen> {

  List<LocationModel> scope = [];
  List<Map>? autos;

  @override
  void initState() {
    getAllData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(
        leadingBack: true,
        title: 'Get Free Auto Ride',
        elevation: 0,
      ),
      body: autos == null ? Center(
          child: CircularProgressIndicator(
            color: AppColors.gradient1,
          )
      ) : SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0).copyWith(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                elevation: 4,
                clipBehavior: Clip.hardEdge,
                color: AppColors.white,
                margin: EdgeInsets.only(top: 8.0),
                child: InkWell(
                  onTap: () async {
                    LevelSelectorSheet.show(context, (state, city, postal) {
                      scope.clear();
                      scope.add(LocationModel(name: 'India', text: 'IND', id: '1-India'));
                      if (state != null) {
                        scope.add(state);
                        if (city != null) {
                          scope.add(city);
                          if (postal != null) {
                            scope.add(postal);
                          }
                        }
                      }
                      getAllData();
                    }, hidePostal: true, allField: true, defaultState:  scope.length > 1 ? scope[1] : null, defaultCity: scope.length > 2 ? scope[2] : null, defaultPostal: scope.length > 3 ? scope[3] : null);
                  },
                  child: Container(
                    color: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Builder(
                              builder: (context) {
                                var namedScope = scope.map((loc) => loc.name).toList();

                                return SizedBox(
                                  height: MediaQuery.sizeOf(context).width * 0.08,
                                  child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) => Center(
                                        child: Text(
                                          namedScope[index],
                                          style: TextStyle(
                                              fontFamily: AppFonts.Montserrat,
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500
                                          ),
                                        ),
                                      ),
                                      separatorBuilder: (context, index) => Center(child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(Icons.arrow_forward, size: 12,color: Colors.white,),
                                      )),
                                      itemCount: namedScope.length
                                  ),
                                );
                              }
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down,color: Colors.white,)
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text('Free Autos In ${scope.lastOrNull?.name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              (autos?.isEmpty ?? true) ? Card(
                color: Colors.white,
                clipBehavior: Clip.hardEdge,
                margin: EdgeInsets.symmetric(vertical: 4.0),
                elevation: 0,
                child: ListTile(
                  title: Text('No auto found in selected area.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  // subtitle: Text("Click here to locate auto", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
                  leading: Icon(Icons.taxi_alert_sharp, color: AppColors.gradient1,)
                ),
              ): ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white,
                    clipBehavior: Clip.hardEdge,
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 0,
                    child: InkWell(
                      onTap: () async {
                        if (!await launchUrl(Uri.parse(autos?[index]['link']))) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Couldn\'t load url! Please try again later.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: ListTile(
                        title: Text('Auto ${index + 1}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        // subtitle: Text("Click here to locate auto", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
                        subtitle: Text.rich(
                            TextSpan(
                                text: autos?[index]['from']??'Unknown',
                                children: [
                                  WidgetSpan(child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Icon(Icons.swap_horiz_sharp, size: 16),
                                  )),
                                  TextSpan(
                                    text: autos?[index]['to']??'Unknown',
                                  )
                                ]
                            )
                        ),
                        leading: Icon(Icons.local_taxi, color: AppColors.gradient1,),
                        trailing: Icon(Icons.location_on_rounded, color: Colors.grey),
                      ),
                    ),
                  );
                },
                itemCount: autos?.length,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> getAllData() async {
    try {
      if (scope.isEmpty) {

        var snapshot = await FirebaseFirestore.instance.collection(USER_DB).where('id', isEqualTo: Pref.getString(Keys.USERID)).get();

        final data = snapshot.docs.firstOrNull?.data();

        if (data != null) {
          final Map city = data['city'] ?? {};
          final Map country = data['country'] ?? {};
          final Map state = data['state'] ?? {};

          scope = [LocationModel.fromJson(Map.from(country)), LocationModel.fromJson(Map.from(state)), LocationModel.fromJson(Map.from(city))];
          print("ishwar: scope ${scope.map((d) => d.id)}");
        }
      }

      if (scope.isNotEmpty) {
        var ref = FirebaseFirestore.instance.collection(AUTO_LINKS).doc(scope.lastOrNull?.id??'');
        var snapshot = await ref.get();
        final data = snapshot.data();

        print("ishwar: data for ${ref.path} $data");

        autos = [];

        if (data != null && data['location'] is List) {
          for (var map in data['location']) {
            autos?.add(map);
          }
        }
      }

      setState(() {

      });
      return true;
    } catch (error) {
      print("ishwar: $error");
      return false;
    }
  }

}