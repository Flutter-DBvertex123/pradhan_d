import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AppDropDown extends StatelessWidget {
  final List<DropdownMenuItem> items;
  final Function(dynamic)? onChanged;
  final String hint;
  final Widget? hintWidget;
  final bool showClearButton;
  final Function()? onClear;

  const AppDropDown(
      {super.key,
      required this.items,
      required this.onChanged,
      required this.hint,
      this.hintWidget,
        this.showClearButton = false,
        this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      elevation: 0,
      color: AppColors.textBackColor,
      child: Theme(
        data: ThemeData(
          primaryColor: AppColors.gradient1,
          primarySwatch: getMaterialColor(AppColors.gradient2),
        ),

        // height: 60.0,
        // decoration: BoxDecoration(
        //   border: Border.all(width: 1, color: AppColors.greyTextColor),
        //   borderRadius: BorderRadius.all(Radius.circular(5.0)),
        // ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: DropdownButton(
            underline: Divider(
              color: Colors.transparent,
            ),
            items: items,
            isExpanded: true,
            hint: Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: hintWidget ??
                  Text(
                    hint,
                  ),
            ),
            onChanged: onChanged,
            icon:Row(
              children: [
                if (showClearButton) IconButton(icon: Icon(Icons.clear, size: 20), onPressed: onClear),
                if (showClearButton) SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
