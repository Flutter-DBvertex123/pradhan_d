import 'package:chunaw/app/utils/app_assets.dart';
import 'package:chunaw/app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    Key? key,
    this.padding,
    required this.controller,
    this.lableText,
    this.limit,
    this.border,
    this.fontSize,
    this.textAlign = TextAlign.start,
    this.hintText,
    this.required = false,
    this.obscure = false,
    this.onChange,
    this.inputAction = TextInputAction.done,
    this.keyboardType = TextInputType.text,
    // required this.validator,
    this.enabled = true,
    this.focusNode,
    this.maxLines = 1,
    this.minLines = 1,
    this.validator,
    this.inputFormatters = const [],
    this.nextFocusNode,
    this.prefixIcon,
  }) : super(key: key);

  final TextEditingController controller;
  final String? lableText;
  final EdgeInsetsGeometry? padding;
  final String? hintText;
  final InputBorder? border;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final int? limit;
  final double? fontSize;
  final int maxLines;
  final int minLines;
  final bool enabled;
  final bool obscure;
  final TextInputType keyboardType;
  final bool required;
  final FormFieldValidator<String>? validator;
  final TextInputAction inputAction;
  final Function(String)? onChange;
  final Widget? prefixIcon;
  // final ValidatorCallback validator;
  final FocusNode? focusNode, nextFocusNode;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late bool hide;
  @override
  void initState() {
    hide = widget.obscure;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // FocusNode fn = widget.focusNode ?? FocusNode();
    // padding: widget.padding ?? EdgeInsets.all(8.0),
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      elevation: 0.2,
      child: Theme(
          data: ThemeData(
            primaryColor: AppColors.gradient1,
            primarySwatch: getMaterialColor(AppColors.gradient2),
          ),
          child: TextFormField(
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.center,
            style:
                Theme.of(context).textTheme.titleSmall!.copyWith(fontSize: 16),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: widget.hintText,
              contentPadding: EdgeInsets.only(top: 0, bottom: 15, left: 10),
              border: InputBorder.none,
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: SvgPicture.asset(AppAssets.searchIcon),
              ),
              prefixIconConstraints:
                  BoxConstraints(maxHeight: 40, maxWidth: 40),
              enabledBorder: InputBorder.none,
            ),
            onChanged: widget.onChange,
          )),
    );
  }
}
