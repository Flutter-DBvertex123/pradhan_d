import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

import '../screen/home/post_card.dart';
import '../utils/app_assets.dart';
import '../utils/app_bar.dart';
import '../utils/app_colors.dart';

class WithdrawBreakdown extends StatefulWidget {
  const WithdrawBreakdown({super.key});

  @override
  State<StatefulWidget> createState() => WithdrawState();
}

class WithdrawState extends State<WithdrawBreakdown> {

  List<MapEntry<String, List<MapEntry<dynamic, dynamic>>>>? weeks;

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> getData() async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable('getWeekWiseBreakdown');
      final response = await callable.call({'pradhan_id': FirebaseAuth.instance.currentUser?.uid});

      print("ishwar: response ${response.data}");

      List<MapEntry<String, dynamic>> weekData = (response.data as Map<String, dynamic>).entries.toList();

      weeks = [];

      for (MapEntry<String, dynamic> data in weekData) {

        print("ishwar: _____");
        print("ishwar: ${data.key}");
        print("ishwar: ${data.value}");

        List<MapEntry<dynamic, dynamic>> usersData = (data.value as Map<dynamic, dynamic>).entries.toList();
        usersData.sort((entry0, entry1) => (double.tryParse("${entry1.value['total_amount'] ?? 0.0}")??0.0).compareTo(double.tryParse("${entry0.value['total_amount'] ?? 0.0}")??0.0));

        weeks?.add(MapEntry(data.key, usersData));
      }

      setState(() {});

    } catch (error) {
      print("ishwar: here ${error}");
      setState(() {
        weeks = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarCustom(
          title: 'Revenue Breakdown',
          leadingBack: true,
          elevation: 0,
          showSearch: false,
        ),
      body: weeks == null ? Center(
        child: CircularProgressIndicator(
          color: AppColors.gradient1,
        )
      ) : weeks!.isEmpty ? Container(
        color: Colors.white,
        child: Center(
          child: Text(
            'No records found',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 15
            ),
          )
        ),
      ) : ListView.builder(
        itemBuilder: (context, index) {
          return BreakdownItem(weekData: weeks![index]);
        },
        itemCount: weeks!.length,
      )
    );
  }

}

class BreakdownItem extends StatefulWidget {
  final MapEntry<String, List<MapEntry<dynamic, dynamic>>> weekData;

  const BreakdownItem({super.key, required this.weekData});

  @override
  State<StatefulWidget> createState() => BreakdownState();
}

class BreakdownState extends State<BreakdownItem> {
  late bool isExpanded;

  @override
  void initState() {
    isExpanded = false;
    super.initState();
  }

  String formatWeekAndYear(String dateString) {
    // Parse the input date string
    DateTime date = DateTime.tryParse(dateString) ?? DateTime.now();

    // Get the current year
    int currentYear = DateTime.now().year;

    // Format the month as abbreviated (e.g., "Nov")
    String formattedMonth = DateFormat('MMM').format(date);

    // Calculate the day of the year
    int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;

    // Calculate the week number (1-53)
    int weekNumber = (dayOfYear / 7).floor() + 1;

    // Format the final string
    String formattedDate = '$formattedMonth, Week#$weekNumber';

    // Add year if the date is from a different year
    if (date.year != currentYear) {
      formattedDate += ', ${date.year}';
    }

    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: ExpansionTile(
        collapsedBackgroundColor: Colors.white.withOpacity(0.9),
        backgroundColor: Colors.white,
        iconColor: AppColors.gradient1,
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          formatWeekAndYear(widget.weekData.key),
          style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500
          ),
        ),
        subtitle: Text('Total Earning: ₹${widget.weekData.value.map((data) => data.value['total_amount']??0.0).fold(0.0, (a, b) => a + (b as num).toDouble()).toStringAsFixed(2)}'),
        trailing: Icon(
          isExpanded
              ? Icons.arrow_drop_down_circle
              : Icons.arrow_drop_down,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Contributors',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(widget.weekData.value.length, (index) {
        Map<dynamic, dynamic>? weekData = widget.weekData.value[index].value;
        return ListTile(
          title: Text(weekData?['name'] ?? 'Unknown'),
          trailing: Text(
            '₹${(weekData?['total_amount'] ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontSize: 15
            ),
          ),
          leading: CircleAvatar(
            radius: 22.r,
            backgroundColor: getColorBasedOnLevel(weekData?['level'] ?? 1),
            child: CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.gradient1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    placeholder: (context, error) {
                      return CircleAvatar(
                        radius: 15.r,
                        backgroundColor: AppColors.gradient1,
                        child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.highlightColor,
                            )),
                      );
                    },
                    errorWidget: (context, error, stackTrace) {
                      return Image.asset(
                        AppAssets.brokenImage,
                        fit: BoxFit.fitHeight,
                        width: 160.0,
                        height: 160.0,
                      );
                    },
                    imageUrl: weekData?['image'] ?? '',
                    // .replaceAll('\', '//'),
                    fit: BoxFit.cover,
                    // width: 160.0,
                    height: 160.0,
                  ),
                )),
          ),
        );
      })
        ],
      ),
    );
  }
}