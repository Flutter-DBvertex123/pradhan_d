import 'dart:io';

import 'package:get/get.dart';

class LoadingController extends GetxController {
  RxBool loading = false.obs;
  RxBool internet = true.obs;
  updateLoading(bool val) {
    loading.value = val;
    update();
  }

  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        internet.value = true;
        return true;
      } else {
        internet.value = false;
        return false;
      }
    } on SocketException catch (_) {
      print('not connected');
      // mySnackbar(title: 'Not Connected', description: 'Please check your internet Connection');
      internet.value = false;
      return false;
    }
  }
}
