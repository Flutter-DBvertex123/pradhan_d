import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CountryCodeWidget extends StatelessWidget {
  const CountryCodeWidget({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);
  final Function()? onTap;
  final RxString text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppColors.textBackColor,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: AppColors.borderColorGrey, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.textBackColor,
            borderRadius: BorderRadius.circular(9.0),
            border: Border.all(width: 1.0, color: const Color(0xffebebeb)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text(
                      text.value,
                      style: TextStyle(color: Colors.black),
                      softWrap: false,
                    )),
                SizedBox(width: 2),
                Container(
                  // padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      color: Colors.grey.shade100),
                  child: Icon(
                    Icons.keyboard_arrow_down_sharp,
                    size: 12,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
