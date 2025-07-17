import 'package:chunaw/app/models/location_model.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    Key? key,
    required this.locationModel,
    required this.last,
  }) : super(key: key);
  final bool last;
  final LocationModel locationModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: last ? 100 : 0),
      child: Card(
        color: AppColors.primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ID: ${locationModel.id}",
                  style: TextStyle(color: AppColors.white)),
              Text("Name: ${locationModel.name}",
                  style: TextStyle(color: AppColors.white)),
              Text("Text: ${locationModel.text}",
                  style: TextStyle(color: AppColors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
