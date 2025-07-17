// ! THIS SCREEN IS NOT BEING USED RIGHT NOW

// import 'package:chunaw/app/controller/auth/profile_process_controller.dart';
// import 'package:chunaw/app/utils/app_colors.dart';
// import 'package:chunaw/app/utils/app_fonts.dart';
// import 'package:chunaw/app/widgets/app_bar.dart';
// import 'package:chunaw/app/widgets/app_button.dart';
// import 'package:chunaw/app/widgets/app_toast.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';

// class UploadImageScreen extends StatelessWidget {
//   UploadImageScreen({Key? key}) : super(key: key);
//   final ProfileProcessController processController =
//       Get.find<ProfileProcessController>(tag: "Profile");
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//           preferredSize: Size(double.infinity, 70),
//           child: SimpleAppBar(title: "Smile Please")),
//       body: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 66.sp),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "  Upload Profile Photo",
//                       style: TextStyle(
//                           fontFamily: AppFonts.Montserrat,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w400,
//                           color: AppColors.greyTextColor),
//                     ),
//                     Icon(Icons.account_circle_outlined)
//                   ],
//                 ),
//                 SizedBox(height: 12),
//                 Center(
//                   child: Container(
//                     alignment: Alignment.center,
//                     width: 150.w,
//                     height: 157.h,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(15.r),
//                     ),
//                     child: GestureDetector(
//                       onTap: () {
//                         processController.cameraAction(context, true);
//                       },
//                       child: CircleAvatar(
//                         radius: 60.r,
//                         backgroundColor: AppColors.white.withOpacity(0.3),
//                         child: Center(
//                           child: CircleAvatar(
//                             radius: 55.r,
//                             backgroundColor: AppColors.gradient1,
//                             child: ClipOval(
//                               clipBehavior: Clip.hardEdge,
//                               child: Obx(
//                                 () =>
//                                     processController.imageFile.value.path == ''
//                                         ? Icon(
//                                             Icons.account_circle_sharp,
//                                             color: AppColors.white,
//                                             size: 90,
//                                           )
//                                         : Image.file(
//                                             processController.imageFile.value,
//                                             fit: BoxFit.cover,
//                                             // width: 160.0,
//                                             height: 160.0,
//                                           ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         // child: CircleAvatar(
//                         //   radius: 55.r,
//                         //   backgroundColor: AppColors.gradient1,
//                         // ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 6),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "  Guidelines",
//                       style: TextStyle(
//                           fontFamily: AppFonts.Montserrat,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w400,
//                           color: AppColors.greyTextColor),
//                     ),
//                     Icon(Icons.open_in_new_sharp, color: AppColors.primaryColor)
//                   ],
//                 ),
//                 SizedBox(height: Get.height * 0.34),
//                 AppButton(
//                     onPressed: () {
//                       if (processController.imageFile.value.path.isNotEmpty) {
//                         // processController.savePhotos();
//                       } else {
//                         longToastMessage('Please select a profile photo');
//                       }
//                     },
//                     buttonText: "Continue"),
//                 SizedBox(height: 50),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
