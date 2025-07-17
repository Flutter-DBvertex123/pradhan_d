// Text('Chunaw', textAlign: TextAlign.center, style: TextStyle(
//         color: undefined,
//         fontFamily: 'Montserrat',
//         fontSize: 24,
//         letterSpacing: 0 /*percentages not used in flutter. defaulting to zero*/,
//         fontWeight: FontWeight.normal,
//         height: 1
//       ),)
import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../screen/home/search_screen.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  const AppBarCustom({
    Key? key,
    required this.title,
    this.bottom,
    this.scaffoldKey,
    this.trailling,
    this.elevation,
    this.leadingBack = false,
    this.popValue,
    this.showSearch= false, this.actions
  }) : super(key: key);
  final String title;
  final double? elevation;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final dynamic popValue;

  final Widget? trailling;
  final Widget? bottom;
  final bool leadingBack;

  final bool showSearch;

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation ?? 0.5,
      backgroundColor: AppColors.white,

      leading: scaffoldKey != null
          ? InkWell(
              onTap: () {
                scaffoldKey!.currentState!.openDrawer();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: SvgPicture.asset(
                  AppAssets.drawerIcon,
                  height: 10.h,
                  width: 10.w,
                ),
              ),
            )
          : leadingBack
              ? IconButton(
                  onPressed: () {
                    Get.back(result: popValue);
                  },
                  icon: Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 21.0),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.black,
                      size: 20,
                    ),
                  ),
                )
              : Container(),
      centerTitle: true,
      title: title == ""
          ? Text(
              'Pradhaan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20.sp,
                color: AppColors.primaryColor,
                letterSpacing:
                    0 /*percentages not used in flutter. defaulting to zero*/,
                fontWeight: FontWeight.normal,
              ),
            )
          : Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
      actions: [
        trailling != null ? trailling! : showSearch ? IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SearchScreen()));
            },
            icon: Icon(Icons.search_rounded)
        ) : const SizedBox(),
        if (actions != null) ...[
          ...actions!,
          SizedBox(width: 6)
        ]
      ],
      // actions: [if (trailing != null) trailing!],
      automaticallyImplyLeading: false,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: Size(double.infinity, 70), child: bottom!)
          : null,
    );
  }

  @override
  Size get preferredSize => Size(double.infinity, bottom != null ? 90 : 65);
}
