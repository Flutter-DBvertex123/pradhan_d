import 'package:chunaw/app/screen/auth/login_screen.dart';
import 'package:chunaw/app/utils/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../utils/app_pref.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  signout() {
    _auth.signOut();

    // clearing the states preferences as well
    Pref.clear();

    AppRoutes.navigateOffLogin();
  }
}
