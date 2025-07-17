import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

longToastMessage(String msg) {
  FocusManager.instance.primaryFocus!.unfocus();

  Fluttertoast.showToast(msg: msg, toastLength: Toast.LENGTH_LONG);
}
