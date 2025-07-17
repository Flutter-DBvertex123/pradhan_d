import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimpleAppBar extends StatelessWidget {
  const SimpleAppBar({
    Key? key,
    required this.title,
    this.trailing,
  }) : super(key: key);
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
        preferredSize: Size(double.infinity, 70),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21.0),
              child: Icon(
                Icons.arrow_back_ios,
                color: AppColors.black,
                size: 20,
              ),
            ),
          ),
          centerTitle: true,
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              color: const Color(0xff000000),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          // actions: [if (trailing != null) trailing!],
          automaticallyImplyLeading: false,
        ));
  }
}
