import 'package:chunaw/app/utils/app_colors.dart';
import 'package:chunaw/app/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PostShimmer extends StatelessWidget {
  const PostShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: EdgeInsets.only(
              left: 16.0.sp, right: 16.0.sp, top: 9.0.sp, bottom: 9.0.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userShimmer(),
              SizedBox(height: 14.h),
              shimmerWidget(
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.baseColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  width: Get.width,
                ),
              ),
              SizedBox(height: 3.h),
              shimmerWidget(
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.baseColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  width: Get.width,
                ),
              ),
              SizedBox(height: 3.h),
              shimmerWidget(
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.baseColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  width: Get.width * 0.5,
                ),
              ),
              SizedBox(height: 11.h),
              shimmerWidget(
                child: Container(
                  decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(10)),
                  height: 120.h,
                  width: double.infinity,
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

Widget userShimmer({bool add = true}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    textBaseline: TextBaseline.alphabetic,
    children: [
      shimmerWidget(
        child: CircleAvatar(
          radius: 15.r,
          backgroundColor: AppColors.gradient1,
        ),
      ),
      const Spacer(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shimmerWidget(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.baseColor,
                borderRadius: BorderRadius.circular(30),
              ),
              width: Get.width * 0.3,
            ),
          ),
          SizedBox(
            height: 7,
          ),
          if (add)
            shimmerWidget(
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.baseColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                width: Get.width * 0.1,
              ),
            ),
        ],
      ),
      const Spacer(),
      Column(
        children: [
          // SizedBox(height: 12),
          shimmerWidget(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.baseColor,
                borderRadius: BorderRadius.circular(30),
              ),
              width: Get.width * 0.05,
            ),
          ),
        ],
      )
    ],
  );
}
