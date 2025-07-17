

import 'package:chunaw/app/service/user_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../ishwar_constants.dart';

class RazorpayManager {
  static final RazorpayManager _instance = RazorpayManager._internal();
  final Razorpay _razorpay = Razorpay();

  Function(PaymentSuccessResponse response)? successCallbacks;
  Function(PaymentFailureResponse response)? errorCallbacks;
  Function(ExternalWalletResponse response)? walletCallbacks;

  factory RazorpayManager() {
    return _instance;
  }

  RazorpayManager._internal() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onHandleExternalWallet);
  }

  void onPaymentSuccess(PaymentSuccessResponse response) {
    if (successCallbacks != null) {
      successCallbacks!(response);
    }
  }

  void onPaymentError(PaymentFailureResponse response) {
    if (errorCallbacks != null) {
      errorCallbacks!(response);
    }
  }

  void onHandleExternalWallet(ExternalWalletResponse response) {
    if (walletCallbacks != null) {
      walletCallbacks!(response);
    }
  }

  void setCallbacks(Function(PaymentSuccessResponse response) successCallback, Function(PaymentFailureResponse response) errorCallback, {Function(ExternalWalletResponse response)? externalWalletCallback}) {
    this.successCallbacks = successCallback;
    this.errorCallbacks = errorCallback;
    this.walletCallbacks = externalWalletCallback;
  }

  Future<void> pay(double amount) async {
    var user = await UserService.getUserData(FirebaseAuth.instance.currentUser?.uid);
    print("ishwar: userdata = ${user?.toJson()}");
    print("ishwar: userdata = ${FirebaseAuth.instance.currentUser?.phoneNumber}");
    var options = {
      'key': razorpayApiKey,
      'amount': (amount * 100).toInt(), // convert to paise
      'name': '${user?.name} ${DateTime.now()}',
      'description': 'Account ${user?.id} paying $amount rupees to Pradhaan for adding new advertisement.',
      'timeout': 60 * 5,
      'prefill': {
        'contact': FirebaseAuth.instance.currentUser?.phoneNumber,
        'email': FirebaseAuth.instance.currentUser?.email
      }
    };

    print("ishwar: $options");
    _razorpay.open(options);
  }

  Future<Map<String, dynamic>> capture(PaymentSuccessResponse success, int amount) async {
    print("capture call : paymentId: ${success.paymentId} success: $success, amount: $amount");
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('capturePayment');
      final response = await callable.call({"payment_id": success.paymentId, 'amount': amount});

      print("ishwar: capturing payment: ${response.data}");
      return response.data ?? {'captured': false};
    } catch (error) {
      print("ishwar: capturing payment: $error");
      return {
        'captured': false
      };
    }
  }
}